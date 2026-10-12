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
pub fn renderVelocitySVG(a: std.mem.Allocator, stats: *const models.VelocityStats, opts: VelocityRenderOptions) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(a);
    defer stream.deinit();
    const w = &stream.writer;
    const width = try c.begin(w, opts, "Pull request velocity", "CADENCE & IMPACT. MERGE RATE, MERGED PRS, CODE SHIPPED, PEER REVIEWS and VELOCITY INDEX.");
    try c.header(w, width, "PULL REQUEST VELOCITY", "CADENCE & IMPACT", opts.theme, opts.hide_title);
    try c.icon(w, .timer, 18, 43, 16, opts.theme.title_color);
    try c.text(w, 41, 52, "Average merge time", 10, opts.theme.muted_color, 500, "start", 138);
    try c.text(w, 18, 94, if (stats.merged_prs == 0) "—" else stats.turnaround_str, 36, opts.theme.text_color, 700, "start", 148);
    try c.pill(w, 18, 106, 133, if (stats.total_prs == 0) "No pull requests" else stats.tier.name, c.mint);
    try c.fmt(w, width - 18, 60, "{d}", .{stats.velocity_score}, 30, c.mint, 700, "end", 100);
    try c.text(w, width - 18, 77, "/ 100 velocity index", 8, opts.theme.muted_color, 500, "end", 130);
    try c.text(w, width - 18, 94, if (stats.total_prs == 0) "No activity yet" else stats.tier.percentile, 9, c.mint, 600, "end", 130);
    const nums = [_]u64{ stats.merged_prs, stats.reviews_completed, stats.changed_files };
    const labels = [_][]const u8{ "merged", "reviews", "files" };
    const colors = [_][]const u8{ opts.theme.title_color, c.violet, c.gold };
    const step = (width - 193) / 3;
    for (nums, 0..) |n, i| {
        const x = 184 + @as(f64, @floatFromInt(i)) * step;
        const str = try c.compact(a, n);
        defer a.free(str);
        try c.text(w, x, 117, str, 20, colors[i], 650, "start", step - 8);
        try c.text(w, x, 132, labels[i], 9, opts.theme.muted_color, 500, "start", step - 8);
    }
    try c.rule(w, 18, 141, width - 36, opts.theme);
    const denom = @as(f64, @floatFromInt(@max(1, stats.total_prs)));
    const merged = c.fraction(@as(f64, @floatFromInt(stats.merged_prs)) / denom);
    const open = @min(1 - merged, c.fraction(@as(f64, @floatFromInt(stats.open_prs)) / denom));
    const closed = @min(1 - merged - open, c.fraction(@as(f64, @floatFromInt(stats.closed_prs)) / denom));
    try c.fmt(w, 18, 153, "{d:.1}% merged", .{merged * 100}, 10, opts.theme.text_color, 600, "start", 150);
    const adds = try c.compact(a, stats.total_additions);
    defer a.free(adds);
    const dels = try c.compact(a, stats.total_deletions);
    defer a.free(dels);
    try c.fmt(w, width - 18, 153, "+{s} / −{s} lines", .{ adds, dels }, 9, opts.theme.muted_color, 500, "end", 210);
    const bw = width - 36;
    try c.rect(w, 18, 160, bw, 4, 2, opts.theme.border_color, 1);
    try c.rect(w, 18, 160, bw * merged, 4, 0, opts.theme.title_color, 1);
    try c.rect(w, 18 + bw * merged, 160, bw * open, 4, 0, c.gold, 1);
    try c.rect(w, 18 + bw * (merged + open), 160, bw * closed, 4, 0, c.pink, 1);
    try c.fmt(w, 18, 175, "{d} merged / {d} authored", .{ stats.merged_prs, stats.total_prs }, 8, opts.theme.muted_color, 500, "start", bw * 0.58);
    try c.fmt(w, width - 18, 175, "{d} open · {d} closed", .{ stats.open_prs, stats.closed_prs }, 8, opts.theme.muted_color, 500, "end", bw * 0.40);
    try c.end(w);
    return stream.toOwnedSlice();
}
