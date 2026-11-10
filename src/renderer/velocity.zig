const std = @import("std");
const models = @import("../github/models.zig");
const themes = @import("themes.zig");
const c = @import("card.zig");
pub const VelocityRenderOptions = struct {
    theme: themes.Theme,
    card_width: u32 = 424,
    card_height: u32 = 180,
    border_radius: f64 = 4.5,
    hide_border: bool = false,
    hide_title: bool = false,
    animate: bool = true,
};

// Merge time, lines and files come from the latest 30 pull requests (see the
// GraphQL query in client.zig); outcome counts are lifetime totals.
pub fn renderVelocitySVG(a: std.mem.Allocator, stats: *const models.VelocityStats, opts: VelocityRenderOptions) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(a);
    defer stream.deinit();
    const w = &stream.writer;
    const t = opts.theme;
    const p = c.palette(t);
    const total = stats.total_prs;
    const rate: u64 = if (total == 0) 0 else @intFromFloat(@round(@as(f64, @floatFromInt(stats.merged_prs)) * 100 / @as(f64, @floatFromInt(total))));
    var desc_buf: [256]u8 = undefined;
    const desc = try std.fmt.bufPrint(&desc_buf, "Average merge time {s}. {d} of {d} pull requests merged, {d} open, {d} closed.", .{ if (stats.merged_prs == 0) "unavailable" else stats.turnaround_str, stats.merged_prs, total, stats.open_prs, stats.closed_prs });
    const width = try c.begin(w, opts, "Pull Requests", desc);
    try c.heading(w, width, "Pull Requests", "Timing & size: last 30 PRs", t, opts.hide_title);
    const inner = width - 2 * c.pad;

    if (total == 0) {
        try c.text(w, c.pad, 92, "No pull requests yet", 18, t.text_color, 650, "start", inner);
        try c.text(w, c.pad, 112, "Opened pull requests will appear here after the next update.", 11, t.muted_color, 500, "start", inner);
        try c.end(w);
        return stream.toOwnedSlice();
    }

    // Two headline numbers.
    const right_x = c.pad + inner * 0.55;
    try c.text(w, c.pad, 56, "Average time to merge", 11, t.muted_color, 500, "start", right_x - c.pad - 8);
    try c.text(w, c.pad, 90, if (stats.merged_prs == 0) "\u{2014}" else stats.turnaround_str, 30, t.text_color, 700, "start", right_x - c.pad - 8);
    try c.text(w, right_x, 56, "Merge rate", 11, t.muted_color, 500, "start", 90);
    try c.fmt(w, right_x, 90, "{d}%", .{rate}, 30, t.text_color, 700, "start", 90);
    try c.fmt(w, width - c.pad, 90, "{d} of {d}", .{ stats.merged_prs, total }, 11, t.muted_color, 500, "end", 80);

    // Outcome bar: merged / open / closed, clipped to one rounded track.
    const denom = @as(f64, @floatFromInt(total));
    const segments = [_]struct { u64, []const u8, []const u8 }{
        .{ stats.merged_prs, t.title_color, "merged" },
        .{ stats.open_prs, p.gold, "open" },
        .{ stats.closed_prs, p.pink, "closed" },
    };
    try w.print("<clipPath id=\"pr-outcomes\"><rect x=\"{d}\" y=\"102\" width=\"{d:.2}\" height=\"6\" rx=\"3\"/></clipPath>", .{ c.pad, inner });
    try c.rect(w, c.pad, 102, inner, 6, 3, t.bar_bg_color, 1);
    try w.writeAll("<g clip-path=\"url(#pr-outcomes)\">");
    var x: f64 = c.pad;
    for (segments) |s| {
        const sw = inner * c.fraction(@as(f64, @floatFromInt(s[0])) / denom);
        try c.rect(w, x, 102, @min(sw, c.pad + inner - x), 6, 0, s[1], 1);
        x += sw;
    }
    try w.writeAll("</g>");
    var lx: f64 = c.pad;
    for (segments) |s| {
        var buf: [48]u8 = undefined;
        const label = try std.fmt.bufPrint(&buf, "{d} {s}", .{ s[0], s[2] });
        try w.print("<circle cx=\"{d:.2}\" cy=\"123\" r=\"3\" fill=\"{s}\"/>", .{ lx + 3, s[1] });
        try c.text(w, lx + 10, 127, label, 11, t.muted_color, 500, "start", 100);
        lx += 24 + @as(f64, @floatFromInt(label.len)) * 6;
    }
    try c.rule(w, c.pad, 136, inner, t);

    // Size of the recent work.
    var adds: [24]u8 = undefined;
    var dels: [24]u8 = undefined;
    var lines_buf: [64]u8 = undefined;
    const lines = try std.fmt.bufPrint(&lines_buf, "+{s} / \u{2212}{s}", .{ try c.number(&adds, stats.total_additions), try c.number(&dels, stats.total_deletions) });
    var files_buf: [24]u8 = undefined;
    var reviews_buf: [24]u8 = undefined;
    const cols = [_]struct { []const u8, []const u8 }{
        .{ "Lines changed", lines },
        .{ "Files touched", try c.number(&files_buf, stats.changed_files) },
        .{ "Reviews given", try c.number(&reviews_buf, stats.reviews_completed) },
    };
    const col_w = inner / 3;
    for (cols, 0..) |col, i| {
        const cx = c.pad + @as(f64, @floatFromInt(i)) * col_w;
        try c.text(w, cx, 154, col[0], 11, t.muted_color, 500, "start", col_w - 8);
        try c.text(w, cx, 169, col[1], 12.5, t.text_color, 600, "start", col_w - 8);
    }
    try c.end(w);
    return stream.toOwnedSlice();
}
