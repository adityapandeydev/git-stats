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

// Ring geometry. The inner edge is ring_r - ring_stroke / 2 = 37px. Grade and
// score form one block centred on the ring, so the widest score
// ("1000 / 1000", ~52px at 10px) keeps its corners ~31px from the centre.
pub const ring_cx: f64 = 77;
pub const ring_cy: f64 = 96;
pub const ring_r: f64 = 40;
pub const ring_stroke: f64 = 6;

pub fn renderStatsSVG(a: std.mem.Allocator, stats: *const models.OverallStats, opts: StatsRenderOptions) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(a);
    defer stream.deinit();
    const w = &stream.writer;
    const rating = stats.rating;
    var desc_buf: [256]u8 = undefined;
    const desc = try std.fmt.bufPrint(&desc_buf, "Grade {s}, {d} of 1000. {d} commits, {d} merged pull requests, {d} stars, {d} repositories.", .{ rating.tier, rating.score, stats.total_commits, stats.merged_prs, stats.total_stars, stats.contributed_repos });
    const width = try c.begin(w, opts, "Developer Stats", desc);
    const t = opts.theme;
    try c.heading(w, width, "Developer Stats", if (std.mem.eql(u8, stats.timeframe, "this-year")) "Last 12 months" else "All-time", t, opts.hide_title);

    // Score ring: pathLength makes 750/1000 exactly 75% of a turn; butt caps
    // keep 0, 750 and 1000 exact instead of adding a visible minimum arc.
    try w.print("<circle cx=\"{d}\" cy=\"{d}\" r=\"{d}\" fill=\"none\" stroke=\"{s}\" stroke-width=\"{d}\"/>", .{ ring_cx, ring_cy, ring_r, t.bar_bg_color, ring_stroke });
    try w.print("<circle class=\"rating-progress\" cx=\"{d}\" cy=\"{d}\" r=\"{d}\" fill=\"none\" stroke=\"{s}\" stroke-width=\"{d}\" pathLength=\"100\" stroke-dasharray=\"100\" stroke-dashoffset=\"{d:.3}\" transform=\"rotate(-90 {d} {d})\"/>", .{ ring_cx, ring_cy, ring_r, t.title_color, ring_stroke, 100 * (1 - scoreProgress(rating.score)), ring_cx, ring_cy });
    try c.text(w, ring_cx, ring_cy + 3, rating.tier, 28, t.text_color, 700, "middle", 56);
    try c.fmt(w, ring_cx, ring_cy + 16, "{d} / 1000", .{rating.score}, 10, t.muted_color, 500, "middle", 60);
    try c.text(w, ring_cx, 158, rating.title, 11, t.title_color, 600, "middle", 2 * (ring_cx - 8));

    // Headline metrics. Column offsets are tuned for 424px and stretch with width.
    const x0: f64 = 150;
    const span = width - c.pad - x0;
    const offsets = [_]f64{ 0, 68, 148, 202 };
    const labels = [_][]const u8{ "Commits", "Merged PRs", "Stars", "Repos" };
    const values = [_]u64{ stats.total_commits, stats.merged_prs, stats.total_stars, stats.contributed_repos };
    for (labels, values, offsets, 0..) |label, value, off, i| {
        const x = x0 + off * span / 249;
        const next = if (i + 1 < offsets.len) x0 + offsets[i + 1] * span / 249 else width - c.pad;
        try c.text(w, x, 58, label, 11, t.muted_color, 500, "start", next - x - 6);
        const n = try formatCommas(a, value);
        defer a.free(n);
        try c.text(w, x, 80, n, 18, t.text_color, 650, "start", next - x - 6);
    }
    try c.rule(w, x0, 93, span, t);

    // How the score is made: four parts that add up to it exactly.
    const parts = [_]struct { []const u8, u32, u32 }{
        .{ "Commits", rating.commits_pts, 350 },
        .{ "Pull requests", rating.prs_pts, 300 },
        .{ "Collaboration", rating.collab_pts, 200 },
        .{ "Impact", rating.impact_pts, 150 },
    };
    const bar_x = x0 + 86;
    const bar_w = width - c.pad - 59 - bar_x;
    for (parts, 0..) |part, i| {
        const y = 114 + @as(f64, @floatFromInt(i)) * 16;
        try c.text(w, x0, y, part[0], 11, t.muted_color, 500, "start", 84);
        try c.meter(w, bar_x, y - 6, bar_w, @as(f64, @floatFromInt(part[1])) / @as(f64, @floatFromInt(part[2])), t.title_color, t, 5);
        try w.print("<text x=\"{d:.2}\" y=\"{d:.2}\" font-size=\"11\" fill=\"{s}\" text-anchor=\"end\"><tspan fill=\"{s}\" font-weight=\"600\">{d}</tspan> / {d}</text>", .{ width - c.pad, y, t.muted_color, t.text_color, part[1], part[2] });
    }
    try c.end(w);
    return stream.toOwnedSlice();
}
