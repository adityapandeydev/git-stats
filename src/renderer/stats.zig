const std = @import("std");
const models = @import("../github/models.zig");
const themes = @import("themes.zig");

pub const StatsRenderOptions = struct {
    theme: themes.Theme,
    card_width: u32 = 424,
    card_height: u32 = 180,
    border_radius: f64 = 4.5,
    hide_border: bool = false,
    hide_title: bool = false,
    animate: bool = true,
};

pub fn formatCommas(allocator: std.mem.Allocator, num: u64) ![]const u8 {
    var buf: [32]u8 = undefined;
    const raw = try std.fmt.bufPrint(&buf, "{d}", .{num});
    if (raw.len <= 3) {
        return try allocator.dupe(u8, raw);
    }

    var out_buf: [48]u8 = undefined;
    var out_idx: usize = 0;
    const remainder = raw.len % 3;

    if (remainder > 0) {
        @memcpy(out_buf[out_idx .. out_idx + remainder], raw[0..remainder]);
        out_idx += remainder;
        if (raw.len > remainder) {
            out_buf[out_idx] = ',';
            out_idx += 1;
        }
    }

    var i = remainder;
    while (i < raw.len) : (i += 3) {
        @memcpy(out_buf[out_idx .. out_idx + 3], raw[i .. i + 3]);
        out_idx += 3;
        if (i + 3 < raw.len) {
            out_buf[out_idx] = ',';
            out_idx += 1;
        }
    }

    return try allocator.dupe(u8, out_buf[0..out_idx]);
}

pub fn renderStatsSVG(
    allocator: std.mem.Allocator,
    stats: *const models.OverallStats,
    opts: StatsRenderOptions,
) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(allocator);
    defer stream.deinit();
    const w = &stream.writer;

    const width = opts.card_width;
    const height = opts.card_height;
    const w_f = @as(f64, @floatFromInt(width));
    const h_f = @as(f64, @floatFromInt(height));

    const rating = stats.rating;

    // Ring Geometry (R = 42 -> Circumference ~ 263.89)
    const ring_r: f64 = 42.0;
    const circumference: f64 = 2.0 * std.math.pi * ring_r;
    const target_offset: f64 = circumference * (1.0 - std.math.clamp(rating.progress, 0.05, 1.0));

    // Formatted numbers
    const commits_str = try formatCommas(allocator, stats.total_commits);
    defer allocator.free(commits_str);
    const prs_str = try formatCommas(allocator, stats.merged_prs);
    defer allocator.free(prs_str);
    const stars_str = try formatCommas(allocator, stats.total_stars);
    defer allocator.free(stars_str);
    const repos_str = try formatCommas(allocator, stats.contributed_repos);
    defer allocator.free(repos_str);

    // SVG Header
    try w.print(
        \\<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {d} {d}" width="{d}" height="{d}">
        \\  <defs>
        \\    <filter id="ring-glow" x="-50%" y="-50%" width="200%" height="200%">
        \\      <feGaussianBlur in="SourceGraphic" stdDeviation="4" result="blur1"/>
        \\      <feGaussianBlur in="SourceGraphic" stdDeviation="10" result="blur2"/>
        \\      <feMerge>
        \\        <feMergeNode in="blur2"/>
        \\        <feMergeNode in="blur1"/>
        \\        <feMergeNode in="SourceGraphic"/>
        \\      </feMerge>
        \\    </filter>
        \\    <linearGradient id="tier-grad" x1="0%" y1="0%" x2="100%" y2="100%">
        \\      <stop offset="0%" stop-color="{s}"/>
        \\      <stop offset="100%" stop-color="{s}"/>
        \\    </linearGradient>
        \\    <linearGradient id="stats-divider-grad" x1="0%" y1="0%" x2="0%" y2="100%">
        \\      <stop offset="0%" stop-color="{s}" stop-opacity="0.0"/>
        \\      <stop offset="50%" stop-color="#3b4261" stop-opacity="0.7"/>
        \\      <stop offset="100%" stop-color="{s}" stop-opacity="0.0"/>
        \\    </linearGradient>
        \\    <radialGradient id="ring-aura" cx="50%" cy="50%" r="50%">
        \\      <stop offset="0%" stop-color="{s}" stop-opacity="0.28"/>
        \\      <stop offset="65%" stop-color="{s}" stop-opacity="0.10"/>
        \\      <stop offset="100%" stop-color="{s}" stop-opacity="0.0"/>
        \\    </radialGradient>
        \\  </defs>
        \\
    , .{
        width,
        height,
        width,
        height,
        rating.color,
        rating.glow_color,
        opts.theme.bg_color,
        opts.theme.bg_color,
        rating.color,
        rating.glow_color,
        rating.glow_color,
    });

    // Stylesheet & Keyframes
    try w.print(
        \\  <style>
        \\    @keyframes ringFlow {{
        \\      from {{ stroke-dashoffset: {d:.1}; }}
        \\      to {{ stroke-dashoffset: {d:.1}; }}
        \\    }}
        \\    @keyframes auraBreathe {{
        \\      0%, 100% {{ transform: scale(1.0); opacity: 0.8; }}
        \\      50% {{ transform: scale(1.12); opacity: 1.0; }}
        \\    }}
        \\    .stat-heading {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; }}
        \\    .matrix-val {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 18.5px; fill: #c0caf5; }}
        \\    .matrix-lbl {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 8.5px; letter-spacing: 0.7px; }}
        \\    .matrix-sub {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; }}
        \\    .tier-badge-txt {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 900; }}
        \\    .tier-sub-txt {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; }}
        \\  </style>
        \\
    , .{
        circumference,
        target_offset,
    });

    // Card Background
    const stroke_attr = if (opts.hide_border)
        "stroke=\"none\""
    else
        "stroke=\"#24283b\" stroke-width=\"1\"";

    try w.print(
        \\  <rect width="{d}" height="{d}" rx="{d:.1}" fill="{s}" {s}/>
        \\
    , .{ width, height, opts.border_radius, opts.theme.bg_color, stroke_attr });

    // Header (Title & Scope)
    const header_y: f64 = 25.0;
    if (!opts.hide_title) {
        try w.print(
            \\  <!-- Header -->
            \\  <text x="22" y="{d:.1}" class="stat-heading" font-size="12.5" letter-spacing="1.2" fill="{s}">DEVELOPER STATS</text>
            \\  <circle cx="178" cy="{d:.1}" r="2.5" fill="{s}"/>
            \\  <text x="186" y="{d:.1}" class="matrix-sub" font-size="9" letter-spacing="0.5" fill="#787c99">{s}</text>
            \\
        , .{
            header_y,
            opts.theme.title_color,
            header_y - 3.5,
            rating.color,
            header_y - 0.5,
            if (std.mem.eql(u8, stats.timeframe, "this-year")) "2026" else "ALL-TIME",
        });
    }

    // 2x2 Glass Matrix Layout
    const m_start_y: f64 = if (opts.hide_title) 22.0 else 38.0;
    const col1_x: f64 = 22.0;
    const col2_x: f64 = 138.0;
    const tile_w: f64 = 108.0;
    const tile_h: f64 = if (opts.hide_title) 62.0 else 56.0;
    const row2_y: f64 = m_start_y + tile_h + 8.0;
    const lbl_y: f64 = if (opts.hide_title) 23.0 else 21.0;
    const badge_cy: f64 = if (opts.hide_title) 19.0 else 17.0;
    const val_y: f64 = if (opts.hide_title) 50.0 else 45.5;

    // Tile 1: Total Commits
    try w.print(
        \\  <!-- Tile 1: Commits -->
        \\  <g transform="translate({d:.1}, {d:.1})">
        \\    <rect width="{d:.1}" height="{d:.1}" rx="6" fill="#1f2335" fill-opacity="0.5" stroke="#292e42" stroke-width="0.8"/>
        \\    <text x="13" y="{d:.1}" class="matrix-lbl" fill="#7aa2f7">COMMITS</text>
        \\    <circle cx="92" cy="{d:.1}" r="10" fill="#7aa2f7" fill-opacity="0.12"/>
        \\    <circle cx="92" cy="{d:.1}" r="4.2" fill="none" stroke="{s}" stroke-width="1.6"/>
        \\    <circle cx="92" cy="{d:.1}" r="1.8" fill="{s}"/>
        \\    <text x="13" y="{d:.1}" class="matrix-val">{s}</text>
        \\  </g>
        \\
    , .{
        col1_x,
        m_start_y,
        tile_w,
        tile_h,
        lbl_y,
        badge_cy,
        badge_cy,
        opts.theme.title_color,
        badge_cy,
        opts.theme.title_color,
        val_y,
        commits_str,
    });

    // Tile 2: Merged PRs
    try w.print(
        \\  <!-- Tile 2: Merged PRs -->
        \\  <g transform="translate({d:.1}, {d:.1})">
        \\    <rect width="{d:.1}" height="{d:.1}" rx="6" fill="#1f2335" fill-opacity="0.5" stroke="#292e42" stroke-width="0.8"/>
        \\    <text x="13" y="{d:.1}" class="matrix-lbl" fill="#bb9af7">MERGED PRS</text>
        \\    <circle cx="92" cy="{d:.1}" r="10" fill="#bb9af7" fill-opacity="0.12"/>
        \\    <g transform="translate(92, {d:.1})">
        \\      <path d="M -3 -5 L -3 5 M 3 -5 L 3 -1 C 3 2 -3 2 -3 2" fill="none" stroke="#bb9af7" stroke-width="1.4" stroke-linecap="round"/>
        \\      <circle cx="-3" cy="-5" r="1.6" fill="#bb9af7"/>
        \\      <circle cx="3" cy="-5" r="1.6" fill="#bb9af7"/>
        \\      <circle cx="-3" cy="5" r="1.6" fill="#bb9af7"/>
        \\    </g>
        \\    <text x="13" y="{d:.1}" class="matrix-val">{s}</text>
        \\  </g>
        \\
    , .{
        col2_x,
        m_start_y,
        tile_w,
        tile_h,
        lbl_y,
        badge_cy,
        badge_cy,
        val_y,
        prs_str,
    });

    // Tile 3: Total Stars
    try w.print(
        \\  <!-- Tile 3: Stars Earned -->
        \\  <g transform="translate({d:.1}, {d:.1})">
        \\    <rect width="{d:.1}" height="{d:.1}" rx="6" fill="#1f2335" fill-opacity="0.5" stroke="#292e42" stroke-width="0.8"/>
        \\    <text x="13" y="{d:.1}" class="matrix-lbl" fill="#e0af68">TOTAL STARS</text>
        \\    <circle cx="92" cy="{d:.1}" r="10" fill="#e0af68" fill-opacity="0.12"/>
        \\    <g transform="translate(92, {d:.1})">
        \\      <path d="M 0 -5 L 1.3 -1.5 L 5 -1.2 L 2.3 1.2 L 3 5 L 0 3.1 L -3 5 L -2.3 1.2 L -5 -1.2 L -1.3 -1.5 Z" fill="#e0af68"/>
        \\    </g>
        \\    <text x="13" y="{d:.1}" class="matrix-val">{s}</text>
        \\  </g>
        \\
    , .{
        col1_x,
        row2_y,
        tile_w,
        tile_h,
        lbl_y,
        badge_cy,
        badge_cy,
        val_y,
        stars_str,
    });

    // Tile 4: Contributed Repos
    try w.print(
        \\  <!-- Tile 4: Repositories -->
        \\  <g transform="translate({d:.1}, {d:.1})">
        \\    <rect width="{d:.1}" height="{d:.1}" rx="6" fill="#1f2335" fill-opacity="0.5" stroke="#292e42" stroke-width="0.8"/>
        \\    <text x="13" y="{d:.1}" class="matrix-lbl" letter-spacing="0.6" fill="#73daca">REPOSITORIES</text>
        \\    <circle cx="92" cy="{d:.1}" r="10" fill="#73daca" fill-opacity="0.12"/>
        \\    <g transform="translate(92, {d:.1})">
        \\      <path d="M -4.5 -4.5 C -2.5 -5.5 0 -5.5 0 -3.5 L 0 4.5 C 0 2.5 -2.5 2.5 -4.5 3.5 Z M 4.5 -4.5 C 2.5 -5.5 0 -5.5 0 -3.5 L 0 4.5 C 0 2.5 2.5 2.5 4.5 3.5 Z" fill="none" stroke="#73daca" stroke-width="1.3" stroke-linejoin="round"/>
        \\    </g>
        \\    <text x="13" y="{d:.1}" class="matrix-val">{s}</text>
        \\  </g>
        \\
    , .{
        col2_x,
        row2_y,
        tile_w,
        tile_h,
        lbl_y,
        badge_cy,
        badge_cy,
        val_y,
        repos_str,
    });

    // Vertical Divider Line
    const div_x: f64 = 254.0;
    try w.print(
        \\  <!-- Glass Divider -->
        \\  <line x1="{d:.1}" y1="22" x2="{d:.1}" y2="{d:.1}" stroke="url(#stats-divider-grad)" stroke-width="1"/>
        \\
    , .{ div_x, div_x, h_f - 22.0 });

    // Right Section: Radial Rating Ring
    const ring_cx: f64 = w_f * 0.79;
    const ring_cy: f64 = 75.0;

    const anim_aura = if (opts.animate) "style=\"animation: auraBreathe 4s ease-in-out infinite; transform-origin: 0px 0px;\"" else "";
    const anim_ring = if (opts.animate) "style=\"animation: ringFlow 1.6s cubic-bezier(0.16, 1, 0.3, 1) forwards;\"" else "";

    try w.print(
        \\  <!-- Radial Rating Gauge -->
        \\  <g transform="translate({d:.1}, {d:.1})">
        \\    <!-- Aura Glow -->
        \\    <circle cx="0" cy="0" r="54" fill="url(#ring-aura)" {s}/>
        \\    <!-- Inactive Track -->
        \\    <circle cx="0" cy="0" r="{d:.1}" fill="none" stroke="#24283b" stroke-width="6.5" stroke-linecap="round"/>
        \\    <!-- Active Gradient Progress Ring -->
        \\    <circle cx="0" cy="0" r="{d:.1}" fill="none" stroke="url(#tier-grad)" stroke-width="6.5" stroke-linecap="round"
        \\      stroke-dasharray="{d:.1}" stroke-dashoffset="{d:.1}" transform="rotate(-90)" {s}/>
        \\    <!-- Tier Grade Badge Text -->
        \\    <text x="0" y="5" text-anchor="middle" class="tier-badge-txt" font-size="28" fill="url(#tier-grad)" filter="url(#ring-glow)">{s}</text>
        \\    <!-- Numeric Score -->
        \\    <text x="0" y="22" text-anchor="middle" class="tier-sub-txt" font-size="10.5" fill="#a9b1d6">{d} / 1000</text>
        \\  </g>
        \\
    , .{
        ring_cx,
        ring_cy,
        anim_aura,
        ring_r,
        ring_r,
        circumference,
        target_offset,
        anim_ring,
        rating.tier,
        rating.score,
    });

    // Pill Badge Below Ring
    const pill_w: f64 = 114.0;
    const pill_h: f64 = 19.0;
    const pill_x: f64 = ring_cx - (pill_w / 2.0);
    const pill_y: f64 = 138.0;

    try w.print(
        \\  <!-- Rank Pill Badge -->
        \\  <g transform="translate({d:.1}, {d:.1})">
        \\    <rect width="{d:.1}" height="{d:.1}" rx="9.5" fill="{s}" fill-opacity="0.16" stroke="url(#tier-grad)" stroke-width="1"/>
        \\    <text x="{d:.1}" y="12.5" text-anchor="middle" class="stat-heading" font-size="8.8" letter-spacing="0.8" fill="#ffffff">{s}</text>
        \\  </g>
        \\
    , .{
        pill_x,
        pill_y,
        pill_w,
        pill_h,
        rating.color,
        pill_w / 2.0,
        rating.percentile,
    });

    // Subtitle under pill: Tier Title
    try w.print(
        \\  <text x="{d:.1}" y="169" text-anchor="middle" class="matrix-sub" font-size="9.5" letter-spacing="0.5" fill="#787c99">{s}</text>
        \\
    , .{
        ring_cx,
        rating.title,
    });

    try w.print("</svg>\n", .{});

    return try stream.toOwnedSlice();
}
