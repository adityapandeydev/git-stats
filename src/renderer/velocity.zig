const std = @import("std");
const models = @import("../github/models.zig");
const themes = @import("themes.zig");

pub const VelocityRenderOptions = struct {
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

fn formatK(allocator: std.mem.Allocator, num: u64) ![]const u8 {
    if (num < 1000) {
        return try std.fmt.allocPrint(allocator, "{d}", .{num});
    } else if (num < 1_000_000) {
        const val_f = @as(f64, @floatFromInt(num)) / 1000.0;
        if (val_f >= 100.0) {
            return try std.fmt.allocPrint(allocator, "{d:.0}k", .{val_f});
        } else {
            return try std.fmt.allocPrint(allocator, "{d:.1}k", .{val_f});
        }
    } else {
        const val_f = @as(f64, @floatFromInt(num)) / 1_000_000.0;
        return try std.fmt.allocPrint(allocator, "{d:.1}M", .{val_f});
    }
}

pub fn renderVelocitySVG(
    allocator: std.mem.Allocator,
    stats: *const models.VelocityStats,
    opts: VelocityRenderOptions,
) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(allocator);
    defer stream.deinit();
    const w = &stream.writer;

    const width = if (opts.card_width > 0) opts.card_width else 424;
    const height = if (opts.card_height > 0) opts.card_height else 180;
    const w_f = @as(f64, @floatFromInt(width));

    const tier = stats.tier;
    const esc_turnaround = try escapeXml(allocator, stats.turnaround_str);
    defer allocator.free(esc_turnaround);
    const esc_tier_name = try escapeXml(allocator, tier.name);
    defer allocator.free(esc_tier_name);
    const esc_tier_percentile = try escapeXml(allocator, tier.percentile);
    defer allocator.free(esc_tier_percentile);

    // SVG Root & Defs
    try w.print(
        \\<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {d} {d}" width="{d}" height="{d}">
        \\  <defs>
        \\    <linearGradient id="vel-divider-grad" x1="0%" y1="0%" x2="0%" y2="100%">
        \\      <stop offset="0%" stop-color="#3b4261" stop-opacity="0.0"/>
        \\      <stop offset="25%" stop-color="#3b4261" stop-opacity="0.7"/>
        \\      <stop offset="75%" stop-color="#3b4261" stop-opacity="0.7"/>
        \\      <stop offset="100%" stop-color="#3b4261" stop-opacity="0.0"/>
        \\    </linearGradient>
        \\    <linearGradient id="vel-gauge-grad" x1="0%" y1="100%" x2="100%" y2="0%">
        \\      <stop offset="0%" stop-color="#70a5fd"/>
        \\      <stop offset="100%" stop-color="{s}"/>
        \\    </linearGradient>
        \\    <filter id="vel-glow" x="-20%" y="-20%" width="140%" height="140%">
        \\      <feGaussianBlur stdDeviation="2.5" result="blur"/>
        \\      <feMerge>
        \\        <feMergeNode in="blur"/>
        \\        <feMergeNode in="SourceGraphic"/>
        \\      </feMerge>
        \\    </filter>
        \\    <clipPath id="vel-dist-clip">
        \\      <rect x="22" y="142" width="134" height="6" rx="3"/>
        \\    </clipPath>
        \\  </defs>
        \\
    , .{ width, height, width, height, tier.color });

    // Stylesheet
    try w.print(
        \\  <style>
        \\    .vel-title {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 11px; letter-spacing: 0.6px; fill: {s}; }}
        \\    .vel-sub {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 7.5px; letter-spacing: 0.35px; fill: #787c99; }}
        \\    .vel-badge-txt {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 9px; letter-spacing: 0.4px; fill: {s}; }}
        \\    .vel-gauge-val {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 17px; fill: #c0caf5; }}
        \\    .vel-gauge-sub {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 7.5px; letter-spacing: 0.7px; fill: #7982a9; }}
        \\    .vel-kpi-lbl {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 7.5px; letter-spacing: 0.5px; fill: #7aa2f7; }}
        \\    .vel-kpi-val {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 13.5px; fill: #c0caf5; }}
        \\    .vel-kpi-sub {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 7.5px; fill: #7982a9; }}
        \\    .vel-rate-txt {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 10px; fill: #73daca; }}
        \\    .vel-legend-txt {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 7px; fill: #565f89; }}
        \\
    , .{ opts.theme.title_color, tier.color });

    if (opts.animate) {
        try w.writeAll(
            \\    @keyframes velFadeIn {
            \\      from { opacity: 0; transform: translateY(4px); }
            \\      to { opacity: 1; transform: translateY(0); }
            \\    }
            \\    .vel-anim { animation: velFadeIn 0.5s ease-out forwards; }
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
            \\  <text x="18" y="{d:.1}" class="vel-title">PULL REQUEST VELOCITY</text>
            \\  <circle cx="169" cy="{d:.1}" r="1.8" fill="{s}"/>
            \\  <text x="177" y="{d:.1}" class="vel-sub">CADENCE &amp; IMPACT</text>
            \\
        , .{
            header_y,
            header_y - 3.5,
            tier.color,
            header_y - 0.5,
        });

        // Archetype / Speed Tier Badge on Right
        const badge_w: f64 = 122.0;
        const badge_h: f64 = 18.0;
        const badge_x: f64 = w_f - 18.0 - badge_w;
        const badge_y: f64 = header_y - 12.0;

        try w.print(
            \\  <rect x="{d:.1}" y="{d:.1}" width="{d:.1}" height="{d:.1}" rx="3.5" fill="{s}" fill-opacity="0.12" stroke="{s}" stroke-opacity="0.45" stroke-width="0.8"/>
            \\  <text x="{d:.1}" y="{d:.1}" text-anchor="middle" class="vel-badge-txt">{s} {s}</text>
            \\
        , .{
            badge_x,
            badge_y,
            badge_w,
            badge_h,
            tier.color,
            tier.color,
            badge_x + (badge_w / 2.0),
            badge_y + 12.0,
            tier.icon,
            esc_tier_name,
        });
    }

    // Left Section: Speedometer Turnaround Gauge
    // Gauge center: (89, 86), radius = 37.
    // 220-degree sweep arc: starts at 160 deg, sweeps 220 deg to 380 deg (20 deg).
    const arc_r: f64 = 37.0;
    const arc_cx: f64 = 89.0;
    const arc_cy: f64 = 86.0;
    const full_circumference: f64 = 2.0 * std.math.pi * arc_r; // ~232.478
    const sweep_angle: f64 = 220.0;
    const sweep_len: f64 = (sweep_angle / 360.0) * full_circumference; // ~142.07

    const progress_ratio = @as(f64, @floatFromInt(stats.velocity_score)) / 100.0;
    const active_len = sweep_len * @max(0.05, @min(1.0, progress_ratio));

    try w.print(
        \\  <!-- Left Section: Turnaround Speedometer Gauge -->
        \\  <circle cx="{d:.1}" cy="{d:.1}" r="{d:.1}" fill="none" stroke="#212337" stroke-width="5.5" stroke-linecap="round"
        \\          stroke-dasharray="{d:.2} {d:.2}" transform="rotate(160 {d:.1} {d:.1})"/>
        \\  <circle cx="{d:.1}" cy="{d:.1}" r="{d:.1}" fill="none" stroke="url(#vel-gauge-grad)" stroke-width="5.5" stroke-linecap="round"
        \\          stroke-dasharray="{d:.2} {d:.2}" transform="rotate(160 {d:.1} {d:.1})" filter="url(#vel-glow)"/>
        \\  <text x="{d:.1}" y="{d:.1}" text-anchor="middle" class="vel-gauge-val">{s}</text>
        \\  <text x="{d:.1}" y="{d:.1}" text-anchor="middle" class="vel-gauge-sub">AVG MERGE</text>
        \\
    , .{
        arc_cx,
        arc_cy,
        arc_r,
        sweep_len,
        full_circumference,
        arc_cx,
        arc_cy,
        arc_cx,
        arc_cy,
        arc_r,
        active_len,
        full_circumference,
        arc_cx,
        arc_cy,
        arc_cx,
        arc_cy - 1.0,
        esc_turnaround,
        arc_cx,
        arc_cy + 11.5,
    });

    // Merge Rate Header & Distribution Bar (Below Gauge)
    const bar_x: f64 = 22.0;
    const bar_w: f64 = 134.0;
    const bar_y: f64 = 140.0;

    try w.print(
        \\  <!-- Merge Rate & Distribution Bar -->
        \\  <text x="{d:.1}" y="{d:.1}" class="vel-kpi-lbl">MERGE RATE</text>
        \\  <text x="{d:.1}" y="{d:.1}" text-anchor="end" class="vel-rate-txt">{d:.1}%</text>
        \\  <rect x="{d:.1}" y="{d:.1}" width="{d:.1}" height="5.5" rx="2.75" fill="#212337"/>
        \\  <g clip-path="url(#vel-dist-clip)">
        \\
    , .{
        bar_x,
        bar_y - 4.0,
        bar_x + bar_w,
        bar_y - 4.0,
        stats.merge_rate,
        bar_x,
        bar_y,
        bar_w,
    });

    // Compute segment widths for Merged, Open, Closed
    const total_p = @as(f64, @floatFromInt(@max(1, stats.total_prs)));
    const merged_w = (@as(f64, @floatFromInt(stats.merged_prs)) / total_p) * bar_w;
    const open_w = (@as(f64, @floatFromInt(stats.open_prs)) / total_p) * bar_w;
    const closed_w = (@as(f64, @floatFromInt(stats.closed_prs)) / total_p) * bar_w;

    var cur_seg_x = bar_x;
    if (merged_w > 0.0) {
        try w.print(
            \\    <rect x="{d:.2}" y="{d:.1}" width="{d:.2}" height="5.5" fill="#73daca"/>
            \\
        , .{ cur_seg_x, bar_y, merged_w });
        cur_seg_x += merged_w;
    }
    if (open_w > 0.0) {
        try w.print(
            \\    <rect x="{d:.2}" y="{d:.1}" width="{d:.2}" height="5.5" fill="#70a5fd"/>
            \\
        , .{ cur_seg_x, bar_y, open_w });
        cur_seg_x += open_w;
    }
    if (closed_w > 0.0) {
        try w.print(
            \\    <rect x="{d:.2}" y="{d:.1}" width="{d:.2}" height="5.5" fill="#565f89"/>
            \\
        , .{ cur_seg_x, bar_y, closed_w });
    }

    try w.print(
        \\  </g>
        \\  <text x="{d:.1}" y="159.0" text-anchor="middle" class="vel-legend-txt">{d} merged · {d} open · {d} closed</text>
        \\
    , .{
        bar_x + (bar_w / 2.0),
        stats.merged_prs,
        stats.open_prs,
        stats.closed_prs,
    });

    // Vertical Divider Line
    const divider_x: f64 = 172.0;
    try w.print(
        \\  <!-- Center Divider -->
        \\  <line x1="{d:.1}" y1="36" x2="{d:.1}" y2="164" stroke="url(#vel-divider-grad)" stroke-width="1"/>
        \\
    , .{ divider_x, divider_x });

    // Right Section: 2x2 Glassmorphic Metric Matrix
    const right_start_x: f64 = 182.0;
    const right_w = w_f - right_start_x - 18.0;
    const gap_x: f64 = 10.0;
    const tile_w = (right_w - gap_x) / 2.0;
    const tile_h: f64 = 58.0;

    const row0_y: f64 = 38.0;
    const row1_y: f64 = 104.0;

    // Tile 1: Merged PRs
    const t1_x = right_start_x;
    const t1_y = row0_y;
    try w.print(
        \\  <!-- Tile 1: Merged PRs -->
        \\  <g class="vel-anim">
        \\    <rect x="{d:.1}" y="{d:.1}" width="{d:.1}" height="{d:.1}" rx="4" fill="#1f2335" fill-opacity="0.45" stroke="#292e42" stroke-width="0.8"/>
        \\    <text x="{d:.1}" y="{d:.1}" class="vel-kpi-lbl">🔀 MERGED PRS</text>
        \\    <text x="{d:.1}" y="{d:.1}" class="vel-kpi-val">{d}</text>
        \\    <text x="{d:.1}" y="{d:.1}" class="vel-kpi-sub">of {d} authored ({d:.0}%)</text>
        \\  </g>
        \\
    , .{
        t1_x,
        t1_y,
        tile_w,
        tile_h,
        t1_x + 9.0,
        t1_y + 14.0,
        t1_x + 9.0,
        t1_y + 33.0,
        stats.merged_prs,
        t1_x + 9.0,
        t1_y + 47.0,
        stats.total_prs,
        stats.merge_rate,
    });

    // Tile 2: Code Impact / Churn
    const t2_x = right_start_x + tile_w + gap_x;
    const t2_y = row0_y;
    const adds_str = try formatK(allocator, stats.total_additions);
    defer allocator.free(adds_str);
    const dels_str = try formatK(allocator, stats.total_deletions);
    defer allocator.free(dels_str);

    try w.print(
        \\  <!-- Tile 2: Code Volume Impact -->
        \\  <g class="vel-anim" style="animation-delay: 60ms;">
        \\    <rect x="{d:.1}" y="{d:.1}" width="{d:.1}" height="{d:.1}" rx="4" fill="#1f2335" fill-opacity="0.45" stroke="#292e42" stroke-width="0.8"/>
        \\    <text x="{d:.1}" y="{d:.1}" class="vel-kpi-lbl">📦 CODE SHIPPED</text>
        \\    <text x="{d:.1}" y="{d:.1}" class="vel-kpi-val"><tspan fill="#73daca">+{s}</tspan> <tspan font-size="10px" fill="#787c99">/</tspan> <tspan font-size="11.5px" fill="#f7768e">-{s}</tspan></text>
        \\    <text x="{d:.1}" y="{d:.1}" class="vel-kpi-sub">{d} files modified</text>
        \\  </g>
        \\
    , .{
        t2_x,
        t2_y,
        tile_w,
        tile_h,
        t2_x + 9.0,
        t2_y + 14.0,
        t2_x + 9.0,
        t2_y + 33.0,
        adds_str,
        dels_str,
        t2_x + 9.0,
        t2_y + 47.0,
        stats.changed_files,
    });

    // Tile 3: Code Reviews Done
    const t3_x = right_start_x;
    const t3_y = row1_y;
    try w.print(
        \\  <!-- Tile 3: Reviews Conducted -->
        \\  <g class="vel-anim" style="animation-delay: 120ms;">
        \\    <rect x="{d:.1}" y="{d:.1}" width="{d:.1}" height="{d:.1}" rx="4" fill="#1f2335" fill-opacity="0.45" stroke="#292e42" stroke-width="0.8"/>
        \\    <text x="{d:.1}" y="{d:.1}" class="vel-kpi-lbl">👁️ PEER REVIEWS</text>
        \\    <text x="{d:.1}" y="{d:.1}" class="vel-kpi-val">{d}</text>
        \\    <text x="{d:.1}" y="{d:.1}" class="vel-kpi-sub">PR Reviews Completed</text>
        \\  </g>
        \\
    , .{
        t3_x,
        t3_y,
        tile_w,
        tile_h,
        t3_x + 9.0,
        t3_y + 14.0,
        t3_x + 9.0,
        t3_y + 33.0,
        stats.reviews_completed,
        t3_x + 9.0,
        t3_y + 47.0,
    });

    // Tile 4: Velocity Index
    const t4_x = right_start_x + tile_w + gap_x;
    const t4_y = row1_y;
    try w.print(
        \\  <!-- Tile 4: Velocity Index -->
        \\  <g class="vel-anim" style="animation-delay: 180ms;">
        \\    <rect x="{d:.1}" y="{d:.1}" width="{d:.1}" height="{d:.1}" rx="4" fill="#1f2335" fill-opacity="0.45" stroke="#292e42" stroke-width="0.8"/>
        \\    <text x="{d:.1}" y="{d:.1}" class="vel-kpi-lbl">⚡ VELOCITY INDEX</text>
        \\    <text x="{d:.1}" y="{d:.1}" class="vel-kpi-val" fill="{s}">{d} <tspan font-size="10px" fill="#787c99">/ 100</tspan></text>
        \\    <text x="{d:.1}" y="{d:.1}" class="vel-kpi-sub">{s}</text>
        \\  </g>
        \\
    , .{
        t4_x,
        t4_y,
        tile_w,
        tile_h,
        t4_x + 9.0,
        t4_y + 14.0,
        t4_x + 9.0,
        t4_y + 33.0,
        tier.color,
        stats.velocity_score,
        t4_x + 9.0,
        t4_y + 47.0,
        esc_tier_percentile,
    });

    try w.writeAll("</svg>");
    return try stream.toOwnedSlice();
}
