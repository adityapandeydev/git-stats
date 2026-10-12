const std = @import("std");
const models = @import("../github/models.zig");
const themes = @import("themes.zig");
const c = @import("card.zig");
pub const StatsRenderOptions = struct {
    theme: themes.Theme,
    card_width: u32 = 424,
    card_height: u32 = 180,
    border_radius: f64 = 4.5,
    hide_border: bool = false,
    hide_title: bool = false,
    animate: bool = true,
};
pub fn formatCommas(a: std.mem.Allocator, n: u64) ![]const u8 {
    var buf: [32]u8 = undefined;
    const raw = try std.fmt.bufPrint(&buf, "{d}", .{n});
    var out: [48]u8 = undefined;
    var j: usize = 0;
    for (raw, 0..) |ch, i| {
        if (i > 0 and (raw.len - i) % 3 == 0) {
            out[j] = ',';
            j += 1;
        }
        out[j] = ch;
        j += 1;
    }
    return a.dupe(u8, out[0..j]);
}
pub fn scoreProgress(score: u32) f64 {
    return @as(f64, @floatFromInt(@min(score, 1000))) / 1000;
}
pub fn renderStatsSVG(a: std.mem.Allocator, stats: *const models.OverallStats, opts: StatsRenderOptions) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(a);
    defer stream.deinit();
    const w = &stream.writer;
    const width = try c.begin(w, opts, "Developer stats", "Craft rating, commits, merged pull requests, total stars and repositories.");
    try c.header(w, width, "DEVELOPER STATS", if (std.mem.eql(u8, stats.timeframe, "this-year")) "THIS YEAR" else "ALL-TIME", opts.theme, opts.hide_title);
    const rating = stats.rating;
    try w.print("<defs><linearGradient id=\"stats-rating\"><stop stop-color=\"{s}\"/><stop offset=\"1\" stop-color=\"{s}\"/></linearGradient><radialGradient id=\"stats-aura\"><stop stop-color=\"{s}\" stop-opacity=\".12\"/><stop offset=\"1\" stop-color=\"{s}\" stop-opacity=\"0\"/></radialGradient></defs><circle cx=\"76\" cy=\"94\" r=\"58\" fill=\"url(#stats-aura)\"/><circle cx=\"76\" cy=\"94\" r=\"40\" fill=\"none\" stroke=\"{s}\" stroke-width=\"4\"/>", .{ c.violet, opts.theme.title_color, c.violet, c.violet, opts.theme.border_color });
    // pathLength makes 750/1000 exactly 75% of a turn. Butt caps preserve the
    // proportion at 0, 750 and 1000 rather than adding a minimum visible arc.
    try w.print("<circle class=\"rating-progress\" cx=\"76\" cy=\"94\" r=\"40\" fill=\"none\" stroke=\"url(#stats-rating)\" stroke-width=\"4\" pathLength=\"100\" stroke-dasharray=\"100\" stroke-dashoffset=\"{d:.3}\" transform=\"rotate(-90 76 94)\"/>", .{100 * (1 - scoreProgress(rating.score))});
    try w.writeAll("<g class=\"tier-badge-txt\">");
    try c.text(w, 76, 96, rating.tier, 34, c.violet, 750, "middle", 66);
    try c.fmt(w, 76, 117, "{d} / 1,000", .{rating.score}, 9, opts.theme.muted_color, 500, "middle", 72);
    try w.writeAll("</g>");
    try c.pill(w, 33, 143, 86, rating.percentile, c.violet);
    try c.rect(w, 148, 48, 1, 110, 0, opts.theme.border_color, 1);
    const nums = [_]u64{ stats.total_commits, stats.merged_prs, stats.total_stars, stats.contributed_repos };
    const labels = [_][]const u8{ "Commits", "Merged PRs", "Total stars", "Repositories" };
    const colors = [_][]const u8{ opts.theme.title_color, c.violet, c.gold, c.mint };
    const glyphs = [_]@import("card_icons.zig").Icon{ .commit, .pr, .star, .book };
    const col_w = (width - 176) / 2;
    for (nums, 0..) |n, i| {
        const x = 168 + @as(f64, @floatFromInt(i % 2)) * col_w;
        const y = 54 + @as(f64, @floatFromInt(i / 2)) * 57;
        try c.icon(w, glyphs[i], x, y - 2, 14, colors[i]);
        try c.text(w, x + 22, y + 9, labels[i], 9, opts.theme.muted_color, 500, "start", col_w - 30);
        const number = try formatCommas(a, n);
        defer a.free(number);
        try c.text(w, x, y + 37, number, 24, opts.theme.text_color, 650, "start", col_w - 14);
    }
    try c.rule(w, 168, 155, width - 191, opts.theme);
    try c.text(w, 168, 170, rating.title, 9, opts.theme.muted_color, 500, "start", width - 191);
    try c.end(w);
    return stream.toOwnedSlice();
}
