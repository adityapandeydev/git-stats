const std = @import("std");
const models = @import("../github/models.zig");
const themes = @import("themes.zig");
const c = @import("card.zig");
pub const RhythmRenderOptions = struct {
    theme: themes.Theme,
    card_width: u32 = 424,
    card_height: u32 = 180,
    border_radius: f64 = 4.5,
    hide_border: bool = false,
    hide_title: bool = false,
    animate: bool = true,
    /// The matrix is already shifted into this offset; shown in the header.
    tz_offset_hours: ?f64 = null,
};

/// "UTC+5:30", "UTC−3", "UTC".
pub fn formatOffset(buf: []u8, hours: f64) ![]const u8 {
    if (!std.math.isFinite(hours) or hours == 0) return std.fmt.bufPrint(buf, "UTC", .{});
    const total: u32 = @intFromFloat(@round(@abs(hours) * 60));
    const sign = if (hours < 0) "\u{2212}" else "+";
    if (total % 60 == 0) return std.fmt.bufPrint(buf, "UTC{s}{d}", .{ sign, total / 60 });
    return std.fmt.bufPrint(buf, "UTC{s}{d}:{d:0>2}", .{ sign, total / 60, total % 60 });
}

/// Five steps like GitHub's contribution graph: empty, then quartiles of the peak.
pub fn level(n: u32, peak: u32) u8 {
    if (n == 0 or peak == 0) return 0;
    const r = @as(f64, @floatFromInt(n)) / @as(f64, @floatFromInt(peak));
    return if (r < 0.25) 1 else if (r < 0.5) 2 else if (r < 0.75) 3 else 4;
}
const level_opacity = [_]f64{ 1, 0.3, 0.5, 0.75, 1 };

pub fn renderRhythmSVG(a: std.mem.Allocator, rhythm: *const models.CommitRhythm, opts: RhythmRenderOptions) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(a);
    defer stream.deinit();
    const w = &stream.writer;
    const t = opts.theme;
    const p = c.palette(t);
    var tz_buf: [32]u8 = undefined;
    const tz = if (opts.tz_offset_hours) |h| try formatOffset(&tz_buf, h) else "";
    var desc_buf: [256]u8 = undefined;
    const desc = try std.fmt.bufPrint(&desc_buf, "Commits by weekday and hour{s}{s}. Peak window {s}. {d} recent commits sampled.", .{ if (tz.len > 0) " in " else "", tz, rhythm.peak_window_str, rhythm.total_commits });
    const width = try c.begin(w, opts, "Commit Rhythm", desc);
    try c.heading(w, width, "Commit Rhythm", tz, t, opts.hide_title);

    const empty = rhythm.total_commits == 0;
    if (empty) {
        try c.text(w, c.pad, 55, "No commits in the sampled repositories", 11, t.muted_color, 500, "start", width - 2 * c.pad);
    } else {
        try c.text(w, c.pad, 55, "Peak", 11, t.muted_color, 500, "start", 30);
        try c.text(w, c.pad + 30, 55, rhythm.peak_window_str, 12.5, t.text_color, 600, "start", 120);
    }

    // Day / night split. Complementary labels add up to 100 for complete data.
    const total_f = @as(f64, @floatFromInt(@max(1, rhythm.total_commits)));
    const day = c.fraction(@as(f64, @floatFromInt(rhythm.day_commits)) / total_f);
    const night = c.fraction(@as(f64, @floatFromInt(rhythm.night_commits)) / total_f);
    const day_pct: u32 = @intFromFloat(@round(day * 100));
    const night_pct: u32 = if (!empty and rhythm.night_commits == rhythm.total_commits - @min(rhythm.total_commits, rhythm.day_commits)) 100 - day_pct else @intFromFloat(@round(night * 100));
    if (!empty) {
        try c.fmt(w, width - c.pad, 55, "{d}% day \u{00b7} {d}% night", .{ day_pct, night_pct }, 11, t.muted_color, 500, "end", 150);
        const bx = width - 192;
        try c.rect(w, bx, 49, 50, 5, 2.5, t.bar_bg_color, 1);
        try c.rect(w, bx, 49, 50 * day, 5, 2.5, p.gold, 1);
        try c.rect(w, bx + 50 * day, 49, 50 * @min(night, 1 - day), 5, 2.5, p.violet, 1);
    }

    // 7 × 24 matrix, rows Monday..Sunday, already in the configured timezone.
    var peak: u32 = 0;
    for (rhythm.matrix) |row| for (row) |n| {
        peak = @max(peak, n);
    };
    const x0: f64 = 56;
    const y0: f64 = 66;
    const row_h: f64 = 10.5;
    const slot = (width - c.pad - x0) / 24;
    const day_labels = [_][]const u8{ "Mon", "", "Wed", "", "Fri", "", "Sun" };
    try w.writeAll("<g class=\"rhythm-matrix\">");
    for (rhythm.matrix, 0..) |row, d| {
        const y = y0 + @as(f64, @floatFromInt(d)) * row_h;
        if (day_labels[d].len > 0) try c.text(w, c.pad, y + 8, day_labels[d], 10, t.muted_color, 500, "start", 28);
        for (row, 0..) |n, h| {
            const l = level(n, peak);
            try c.rect(w, x0 + @as(f64, @floatFromInt(h)) * slot + 1, y, slot - 2, row_h - 2, 2, if (l == 0) t.bar_bg_color else t.title_color, level_opacity[l]);
        }
    }
    try w.writeAll("</g>");
    for ([_]u8{ 0, 6, 12, 18, 24 }) |h| {
        const anchor = if (h == 0) "start" else if (h == 24) "end" else "middle";
        try c.fmt(w, x0 + @as(f64, @floatFromInt(h)) * slot, 152, "{d:0>2}", .{h}, 10, t.muted_color, 500, anchor, 20);
    }

    // Footer: sample size and persona, then the colour legend.
    const legend_x = width - 103;
    if (!empty) try c.fmt(w, c.pad, 168, "{d} recent commits sampled \u{00b7} {s}", .{ rhythm.total_commits, rhythm.persona_title }, 11, t.muted_color, 500, "start", legend_x - 40 - c.pad);
    try c.text(w, legend_x - 5, 168, "Less", 10, t.muted_color, 500, "end", 30);
    for (0..5) |l| try c.rect(w, legend_x + @as(f64, @floatFromInt(l)) * 10, 160, 8, 8, 2, if (l == 0) t.bar_bg_color else t.title_color, level_opacity[l]);
    try c.text(w, width - c.pad, 168, "More", 10, t.muted_color, 500, "end", 30);
    try c.end(w);
    return stream.toOwnedSlice();
}
