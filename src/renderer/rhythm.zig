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
};
pub fn renderRhythmSVG(a: std.mem.Allocator, rhythm: *const models.CommitRhythm, opts: RhythmRenderOptions) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(a);
    defer stream.deinit();
    const w = &stream.writer;
    const width = try c.begin(w, opts, "Commit rhythm", "24H × 7D MATRIX. PEAK WINDOW and CIRCADIAN SPLIT of the mapped commits, in the configured timezone.");
    // The data model carries an already shifted matrix, not its timezone. Do
    // not claim a fixed UTC offset in this header.
    try c.header(w, width, "COMMIT RHYTHM", "24H × 7D", opts.theme, opts.hide_title);
    try c.icon(w, .sunrise, 18, 40, 15, c.gold);
    try c.text(w, 40, 52, if (rhythm.total_commits == 0) "No activity yet" else rhythm.peak_window_str, 13, opts.theme.text_color, 650, "start", 110);
    try c.text(w, 153, 52, "peak window", 9, opts.theme.muted_color, 500, "start", 100);
    try c.pill(w, width - 109, 37, 91, if (rhythm.total_commits == 0) "No activity" else rhythm.persona_title, c.gold);
    var peak: u32 = 1;
    for (rhythm.matrix) |row| for (row) |n| {
        peak = @max(peak, n);
    };
    const step = (width - 62) / 24;
    const days = [_][]const u8{ "M", "T", "W", "T", "F", "S", "S" };
    try w.writeAll("<g class=\"rhythm-matrix\">");
    for (days, 0..) |day, d| {
        const y = 66 + @as(f64, @floatFromInt(d)) * 9.1;
        try c.text(w, 19, y + 6, day, 6.5, opts.theme.muted_color, 500, "start", 15);
        for (rhythm.matrix[d], 0..) |n, h| try c.rect(w, 42 + @as(f64, @floatFromInt(h)) * step, y, step - 1.7, 7.1, 1.4, if (n == 0) opts.theme.border_color else opts.theme.title_color, if (n == 0) 1 else 0.25 + 0.75 * @as(f64, @floatFromInt(n)) / @as(f64, @floatFromInt(peak)));
    }
    try w.writeAll("</g>");
    const hours = [_]u8{ 0, 6, 12, 18, 23 };
    for (hours) |h| try c.fmt(w, 42 + @as(f64, @floatFromInt(h)) * step, 139, "{d:0>2}", .{h}, 8, opts.theme.muted_color, 500, "start", 20);
    try c.rule(w, 18, 147, width - 36, opts.theme);
    // Empty data is 0% day AND 0% night. Never imply night activity.
    const day = c.fraction(@as(f64, @floatFromInt(rhythm.day_commits)) / @as(f64, @floatFromInt(@max(1, rhythm.total_commits))));
    const night = c.fraction(@as(f64, @floatFromInt(rhythm.night_commits)) / @as(f64, @floatFromInt(@max(1, rhythm.total_commits))));
    const total_str = try c.compact(a, rhythm.total_commits);
    defer a.free(total_str);
    try c.text(w, 18, 167, total_str, 14, opts.theme.text_color, 650, "start", 66);
    const mapped_x = 24 + @min(66, @as(f64, @floatFromInt(total_str.len)) * 8.4);
    try c.text(w, mapped_x, 167, "commits mapped", 8.5, opts.theme.muted_color, 500, "start", 170 - mapped_x);
    // Keep complementary labels at 100% instead of rounding 61.5/38.5 to
    // 62/39. Preserve independent percentages for incomplete sampled data.
    const day_pct: u32 = @intFromFloat(day * 100);
    const night_pct: u32 = if (rhythm.total_commits > 0 and rhythm.night_commits == rhythm.total_commits - @min(rhythm.total_commits, rhythm.day_commits)) 100 - day_pct else @intFromFloat(night * 100);
    try c.icon(w, .sun, width - 247, 155, 12, c.gold);
    try c.fmt(w, width - 230, 166, "{d}% day", .{day_pct}, 9, opts.theme.text_color, 500, "start", 65);
    try c.icon(w, .moon, width - 166, 155, 12, c.violet);
    try c.fmt(w, width - 149, 166, "{d}% night", .{night_pct}, 9, opts.theme.text_color, 500, "start", 65);
    try c.rect(w, width - 78, 159, 60, 4, 2, opts.theme.border_color, 1);
    try c.rect(w, width - 78, 159, 60 * day, 4, 0, c.gold, 1);
    try c.rect(w, width - 78 + 60 * day, 159, 60 * @min(night, 1 - day), 4, 0, c.violet, 1);
    try c.end(w);
    return stream.toOwnedSlice();
}
