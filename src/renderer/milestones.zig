const std = @import("std");
const models = @import("../github/models.zig");
const themes = @import("themes.zig");
const c = @import("card.zig");
pub const MilestonesRenderOptions = struct {
    theme: themes.Theme,
    card_width: u32 = 424,
    card_height: u32 = 180,
    border_radius: f64 = 4.5,
    hide_border: bool = false,
    hide_title: bool = false,
    animate: bool = true,
};
fn magnitude(s: []const u8) f64 {
    var n: usize = 0;
    while (n < s.len and ((s[n] >= '0' and s[n] <= '9') or s[n] == '.')) : (n += 1) {}
    const v = std.fmt.parseFloat(f64, s[0..n]) catch return 0;
    const multiplier: f64 = if (n < s.len and (s[n] == 'k' or s[n] == 'K')) 1000 else if (n < s.len and s[n] == 'M') 1_000_000 else 1;
    return v * multiplier;
}
pub fn progress(item: models.MilestoneItem) f64 {
    if (item.tier == .diamond) return 1;
    const target = if (std.mem.startsWith(u8, item.target_str, "Next: ")) magnitude(item.target_str[6..]) else 0;
    return if (target > 0) c.fraction(magnitude(item.value_str) / target) else 0;
}
pub fn renderMilestonesSVG(a: std.mem.Allocator, overview: *const models.MilestonesOverview, opts: MilestonesRenderOptions) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(a);
    defer stream.deinit();
    const w = &stream.writer;
    const width = try c.begin(w, opts, "Career milestones", "ACHIEVEMENTS & TROPHIES. STREAK RUNNER, POLYGLOT, CODE TITAN, PR SPECIALIST, REPO MASTER and STAR MAGNET. Progress toward each next tier.");
    try c.header(w, width, "CAREER MILESTONES", overview.master_title, opts.theme, opts.hide_title);
    // Switch by usable width rather than stretching a three-column grid.
    const wide = width >= 700;
    const cols: usize = if (wide) 6 else 3;
    const gap: f64 = if (wide) 10 else 12;
    const tile_w = (width - 36 - gap * @as(f64, @floatFromInt(cols - 1))) / @as(f64, @floatFromInt(cols));
    const glyphs = [_]@import("card_icons.zig").Icon{ .flame, .layers, .commit, .pr, .repo, .star };
    const titles = [_][]const u8{ "Streak runner", "Polyglot", "Code titan", "PR specialist", "Repo master", "Star magnet" };
    for (overview.items, 0..) |item, i| {
        const x = 18 + @as(f64, @floatFromInt(i % cols)) * (tile_w + gap);
        const y: f64 = if (wide) 43 else 43 + @as(f64, @floatFromInt(i / cols)) * 64;
        const color = if (item.tier == .diamond) c.mint else if (item.tier == .platinum) c.violet else item.tier_color;
        if (wide) {
            try c.rect(w, x, y, tile_w, 118, 4, opts.theme.bar_bg_color, 1);
            try c.icon(w, glyphs[i], x + 12, y + 12, 19, color);
            try c.text(w, x + 12, y + 47, titles[i], 10, opts.theme.muted_color, 500, "start", tile_w - 24);
            try c.text(w, x + 12, y + 69, item.value_str, 16, opts.theme.text_color, 650, "start", tile_w - 24);
            try c.text(w, x + 12, y + 86, item.tier_label, 8, color, 650, "start", tile_w - 24);
            try c.bar(w, x + 12, y + 96, tile_w - 24, progress(item), color, opts.theme);
            try c.text(w, x + 12, y + 110, item.target_str, 8, opts.theme.muted_color, 500, "start", tile_w - 24);
        } else {
            try c.icon(w, glyphs[i], x, y + 1, 14, color);
            try c.text(w, x + 20, y + 12, titles[i], 8.5, opts.theme.muted_color, 500, "start", tile_w - 20);
            try c.text(w, x, y + 32, item.value_str, 16, opts.theme.text_color, 650, "start", tile_w);
            try c.bar(w, x, y + 42, tile_w, progress(item), color, opts.theme);
            try c.text(w, x, y + 54, item.target_str, 7.5, opts.theme.muted_color, 500, "start", tile_w * 0.58);
            try c.text(w, x + tile_w, y + 54, item.tier_label, 7.5, color, 600, "end", tile_w * 0.40);
        }
    }
    try c.end(w);
    return stream.toOwnedSlice();
}
