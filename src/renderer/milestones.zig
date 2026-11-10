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

/// Progress toward the next tier, from the numeric value and threshold.
pub fn progress(item: models.MilestoneItem) f64 {
    if (item.next == 0) return 1;
    return c.fraction(@as(f64, @floatFromInt(item.value)) / @as(f64, @floatFromInt(item.next)));
}

const titles = [_][]const u8{ "Streak", "Languages", "Contributions", "Merged PRs", "Repositories", "Stars" };

fn tierColor(tier: models.MilestoneTier, t: themes.Theme, p: c.Palette) []const u8 {
    return switch (tier) {
        .bronze => p.bronze,
        .silver => t.muted_color,
        .gold => p.gold,
        .platinum => p.violet,
        .diamond => p.mint,
    };
}

pub fn renderMilestonesSVG(a: std.mem.Allocator, overview: *const models.MilestonesOverview, opts: MilestonesRenderOptions) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(a);
    defer stream.deinit();
    const w = &stream.writer;
    const t = opts.theme;
    const p = c.palette(t);
    var desc_buf: [384]u8 = undefined;
    var desc_len: usize = 0;
    for (overview.items, titles) |item, name| {
        const part = try std.fmt.bufPrint(desc_buf[desc_len..], "{s} {d} ({s}). ", .{ name, item.value, item.tier.name() });
        desc_len += part.len;
    }
    const width = try c.begin(w, opts, "Milestones", desc_buf[0..desc_len]);
    try c.heading(w, width, "Milestones", overview.master_title, t, opts.hide_title);

    // Wide cards (hero width) put all six in one row instead of stretching a 3 × 2 grid.
    const wide = width >= 700;
    const cols: usize = if (wide) 6 else 3;
    const gap: f64 = 18;
    const tile_w = (width - 2 * c.pad - gap * @as(f64, @floatFromInt(cols - 1))) / @as(f64, @floatFromInt(cols));
    for (overview.items, titles, 0..) |item, name, i| {
        const x = c.pad + @as(f64, @floatFromInt(i % cols)) * (tile_w + gap);
        // One wide row is centred in the space below the title.
        const y: f64 = if (wide) 82 else 48 + @as(f64, @floatFromInt(i / cols)) * 66;
        const color = tierColor(item.tier, t, p);
        var num_buf: [24]u8 = undefined;
        const n = try c.number(&num_buf, item.value);
        var value_buf: [40]u8 = undefined;
        const value = if (i == 0) try std.fmt.bufPrint(&value_buf, "{s} {s}", .{ n, if (item.value == 1) "day" else "days" }) else n;
        try c.text(w, x, y + 10, name, 11, t.muted_color, 500, "start", tile_w);
        try c.text(w, x, y + 32, value, 17, t.text_color, 650, "start", tile_w);
        try c.meter(w, x, y + 39, tile_w, progress(item), color, t, 4);
        // Tier and next target share a footer line, so long titles and values
        // never collide; maxed milestones show only their tier.
        try w.print("<text x=\"{d:.2}\" y=\"{d:.2}\" font-size=\"9\" font-weight=\"700\" letter-spacing=\"0.6\" fill=\"{s}\">{s}</text>", .{ x, y + 55, color, item.tier.name() });
        if (item.next > 0) {
            var next_buf: [24]u8 = undefined;
            var label_buf: [40]u8 = undefined;
            const label = try std.fmt.bufPrint(&label_buf, "next {s}", .{try c.number(&next_buf, item.next)});
            try c.text(w, x + tile_w, y + 55, label, 10, t.muted_color, 500, "end", tile_w * 0.5);
        }
    }
    try c.end(w);
    return stream.toOwnedSlice();
}
