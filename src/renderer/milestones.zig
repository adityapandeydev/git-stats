const std = @import("std");
const models = @import("../github/models.zig");
const themes = @import("themes.zig");

pub const MilestonesRenderOptions = struct {
    theme: themes.Theme,
    card_width: u32 = 424,
    card_height: u32 = 180,
    border_radius: f64 = 4.5,
    hide_border: bool = false,
    hide_title: bool = false,
    animate: bool = true,
};

fn escapeXml(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var stream = std.Io.Writer.Allocating.init(allocator);
    defer stream.deinit();

    for (input) |c| {
        switch (c) {
            '&' => try stream.writer.writeAll("&amp;"),
            '<' => try stream.writer.writeAll("&lt;"),
            '>' => try stream.writer.writeAll("&gt;"),
            '"' => try stream.writer.writeAll("&quot;"),
            '\'' => try stream.writer.writeAll("&#39;"),
            else => try stream.writer.writeByte(c),
        }
    }
    return try stream.toOwnedSlice();
}

pub fn renderMilestonesSVG(
    allocator: std.mem.Allocator,
    overview: *const models.MilestonesOverview,
    opts: MilestonesRenderOptions,
) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(allocator);
    defer stream.deinit();
    const w = &stream.writer;

    const width = if (opts.card_width > 0) opts.card_width else 424;
    const height = if (opts.card_height > 0) opts.card_height else 180;
    const w_f = @as(f64, @floatFromInt(width));

    const esc_master_title = try escapeXml(allocator, overview.master_title);
    defer allocator.free(esc_master_title);

    // SVG Root & Defs
    try w.print(
        \\<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {d} {d}" width="{d}" height="{d}">
        \\  <defs>
        \\    <linearGradient id="mil-glass-grad" x1="0%" y1="0%" x2="100%" y2="100%">
        \\      <stop offset="0%" stop-color="#24283b" stop-opacity="0.6"/>
        \\      <stop offset="100%" stop-color="#1f2335" stop-opacity="0.3"/>
        \\    </linearGradient>
        \\  </defs>
        \\
    , .{ width, height, width, height });

    // Stylesheet
    try w.print(
        \\  <style>
        \\    .mil-title {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 11px; letter-spacing: 0.6px; fill: {s}; }}
        \\    .mil-sub {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 7.5px; letter-spacing: 0.35px; fill: #787c99; }}
        \\    .mil-badge-txt {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 9px; letter-spacing: 0.4px; fill: {s}; }}
        \\    .mil-lbl {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 7.2px; letter-spacing: 0.35px; fill: #7aa2f7; }}
        \\    .mil-val {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 11.5px; fill: #c0caf5; }}
        \\    .mil-tier-txt {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 6.5px; letter-spacing: 0.5px; }}
        \\    .mil-target-txt {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 6.8px; fill: #787c99; }}
        \\
    , .{ opts.theme.title_color, overview.master_color });

    if (opts.animate) {
        try w.writeAll(
            \\    @keyframes milFadeIn {
            \\      from { opacity: 0; transform: translateY(4px); }
            \\      to { opacity: 1; transform: translateY(0); }
            \\    }
            \\    .mil-anim { animation: milFadeIn 0.5s ease-out forwards; }
            \\
        );
    }
    try w.writeAll("  </style>\n\n");

    // Card Background
    const stroke_attr = if (opts.hide_border)
        "stroke=\"none\""
    else
        "stroke=\"#24283b\" stroke-width=\"1\"";

    try w.print(
        \\  <rect width="{d}" height="{d}" rx="{d:.1}" fill="{s}" {s}/>
        \\
    , .{ width, height, opts.border_radius, opts.theme.bg_color, stroke_attr });

    // Header
    const header_y: f64 = 24.0;
    if (!opts.hide_title) {
        try w.print(
            \\  <!-- Header -->
            \\  <text x="18" y="{d:.1}" class="mil-title">CAREER MILESTONES</text>
            \\  <circle cx="145" cy="{d:.1}" r="1.8" fill="{s}"/>
            \\  <text x="153" y="{d:.1}" class="mil-sub">ACHIEVEMENTS &amp; TROPHIES</text>
            \\
        , .{
            header_y,
            header_y - 3.5,
            overview.master_color,
            header_y - 0.5,
        });

        // Master Achievement Badge on Top Right
        const badge_w: f64 = 142.0;
        const badge_h: f64 = 18.0;
        const badge_x: f64 = w_f - 18.0 - badge_w;
        const badge_y: f64 = header_y - 12.0;

        try w.print(
            \\  <rect x="{d:.1}" y="{d:.1}" width="{d:.1}" height="{d:.1}" rx="3.5" fill="{s}" fill-opacity="0.12" stroke="{s}" stroke-opacity="0.45" stroke-width="0.8"/>
            \\  <text x="{d:.1}" y="{d:.1}" text-anchor="middle" class="mil-badge-txt">{s} {s}</text>
            \\
        , .{
            badge_x,
            badge_y,
            badge_w,
            badge_h,
            overview.master_color,
            overview.master_color,
            badge_x + (badge_w / 2.0),
            badge_y + 12.0,
            overview.master_icon,
            esc_master_title,
        });
    }

    // 3x2 Grid of Milestone Tiles
    const available_w = w_f - 36.0;
    const gap_x: f64 = 9.5;
    const tile_w: f64 = (available_w - 2.0 * gap_x) / 3.0; // 123.0px for 424 width
    const tile_h: f64 = 58.0;

    const row0_y: f64 = 38.0;
    const row1_y: f64 = 105.0;

    for (overview.items, 0..) |item, idx| {
        const col = idx % 3;
        const row = idx / 3;
        const t_x = 18.0 + @as(f64, @floatFromInt(col)) * (tile_w + gap_x);
        const t_y = if (row == 0) row0_y else row1_y;
        const anim_delay = idx * 45;

        const esc_title = try escapeXml(allocator, item.title);
        defer allocator.free(esc_title);
        const esc_val = try escapeXml(allocator, item.value_str);
        defer allocator.free(esc_val);
        const esc_tier_label = try escapeXml(allocator, item.tier_label);
        defer allocator.free(esc_tier_label);
        const esc_target = try escapeXml(allocator, item.target_str);
        defer allocator.free(esc_target);

        try w.print(
            \\  <!-- Milestone Tile {d}: {s} -->
            \\  <g class="mil-anim" style="animation-delay: {d}ms;">
            \\    <rect x="{d:.1}" y="{d:.1}" width="{d:.1}" height="{d:.1}" rx="4.5" fill="#1f2335" fill-opacity="0.45" stroke="{s}" stroke-opacity="0.30" stroke-width="0.8"/>
            \\    <!-- Top Heading Row (Full Width) -->
            \\    <text x="{d:.1}" y="{d:.1}" class="mil-lbl">{s}</text>
            \\    <text x="{d:.1}" y="{d:.1}" text-anchor="end" class="mil-target-txt">{s}</text>
            \\    <!-- Bottom Section: Logo + Aligned Text -->
            \\    <circle cx="{d:.1}" cy="{d:.1}" r="11.5" fill="{s}" fill-opacity="0.12" stroke="{s}" stroke-opacity="0.40" stroke-width="0.8"/>
            \\    <text x="{d:.1}" y="{d:.1}" text-anchor="middle" font-size="11.5px">{s}</text>
            \\    <text x="{d:.1}" y="{d:.1}" class="mil-val">{s}</text>
            \\    <!-- Tier Pill -->
            \\    <rect x="{d:.1}" y="{d:.1}" width="44.0" height="11.5" rx="2.5" fill="{s}" fill-opacity="0.14" stroke="{s}" stroke-opacity="0.45" stroke-width="0.6"/>
            \\    <text x="{d:.1}" y="{d:.1}" text-anchor="middle" class="mil-tier-txt" fill="{s}">{s}</text>
            \\  </g>
            \\
        , .{
            idx + 1,
            esc_title,
            anim_delay,
            t_x,
            t_y,
            tile_w,
            tile_h,
            item.tier_color,
            t_x + 9.5,
            t_y + 13.5,
            esc_title,
            t_x + tile_w - 9.5,
            t_y + 13.5,
            esc_target,
            t_x + 19.5,
            t_y + 36.5,
            item.tier_color,
            item.tier_color,
            t_x + 19.5,
            t_y + 40.5,
            item.icon,
            t_x + 37.0,
            t_y + 33.0,
            esc_val,
            t_x + 37.0,
            t_y + 39.0,
            item.tier_color,
            item.tier_color,
            t_x + 59.0,
            t_y + 47.2,
            item.tier_color,
            esc_tier_label,
        });
    }

    try w.writeAll("</svg>");
    return try stream.toOwnedSlice();
}
