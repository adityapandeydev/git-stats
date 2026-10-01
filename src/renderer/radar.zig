const std = @import("std");
const models = @import("../github/models.zig");
const themes = @import("themes.zig");

pub const RadarRenderOptions = struct {
    theme: themes.Theme,
    card_width: u32 = 424,
    card_height: u32 = 180,
    border_radius: f64 = 4.5,
    hide_border: bool = false,
    hide_title: bool = false,
    animate: bool = true,
};

pub fn renderRadarSVG(
    allocator: std.mem.Allocator,
    dna: *const models.DeveloperDNA,
    opts: RadarRenderOptions,
) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(allocator);
    defer stream.deinit();
    const w = &stream.writer;

    const width = opts.card_width;
    const height = opts.card_height;

    // Radar Chart Geometry
    const xc: f64 = 120.0;
    const yc: f64 = 104.0;
    const max_r: f64 = 52.0;

    // Unit circle directions for 5 pentagon vertices (starting top, clockwise)
    // 0: Top (-90 deg)
    // 1: Top-Right (-18 deg)
    // 2: Bottom-Right (54 deg)
    // 3: Bottom-Left (126 deg)
    // 4: Top-Left (198 deg)
    const cos_vals = [5]f64{ 0.0, 0.9510565, 0.5877853, -0.5877853, -0.9510565 };
    const sin_vals = [5]f64{ -1.0, -0.3090170, 0.8090170, 0.8090170, -0.3090170 };

    // Calculate radii for each of the 5 domains (min 12% baseline so shape remains visible)
    const pcts = [5]f64{
        @max(0.0, @min(100.0, dna.systems_pct)),
        @max(0.0, @min(100.0, dna.backend_pct)),
        @max(0.0, @min(100.0, dna.frontend_pct)),
        @max(0.0, @min(100.0, dna.devops_pct)),
        @max(0.0, @min(100.0, dna.data_pct)),
    };

    var v_x: [5]f64 = undefined;
    var v_y: [5]f64 = undefined;
    for (0..5) |i| {
        const norm_r = max_r * (0.12 + 0.88 * (pcts[i] / 100.0));
        v_x[i] = xc + cos_vals[i] * norm_r;
        v_y[i] = yc + sin_vals[i] * norm_r;
    }

    // SVG Header & Defs
    try w.print(
        \\<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {d} {d}" width="{d}" height="{d}">
        \\  <defs>
        \\    <linearGradient id="radar-divider-grad" x1="0%" y1="0%" x2="0%" y2="100%">
        \\      <stop offset="0%" stop-color="{s}" stop-opacity="0.0"/>
        \\      <stop offset="50%" stop-color="#3b4261" stop-opacity="0.7"/>
        \\      <stop offset="100%" stop-color="{s}" stop-opacity="0.0"/>
        \\    </linearGradient>
        \\    <linearGradient id="radar-poly-grad" x1="0%" y1="0%" x2="100%" y2="100%">
        \\      <stop offset="0%" stop-color="{s}" stop-opacity="0.55"/>
        \\      <stop offset="100%" stop-color="#7aa2f7" stop-opacity="0.2"/>
        \\    </linearGradient>
        \\    <filter id="radar-glow" x="-20%" y="-20%" width="140%" height="140%">
        \\      <feGaussianBlur stdDeviation="2.2" result="blur"/>
        \\      <feMerge>
        \\        <feMergeNode in="blur"/>
        \\        <feMergeNode in="SourceGraphic"/>
        \\      </feMerge>
        \\    </filter>
        \\  </defs>
        \\  <style>
        \\    .radar-title {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 12px; letter-spacing: 0.8px; fill: {s}; }}
        \\    .radar-sub {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 8px; letter-spacing: 0.4px; fill: #787c99; }}
        \\    .radar-axis-lbl {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 8px; }}
        \\    .radar-archetype-txt {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 10px; letter-spacing: 0.5px; fill: #c0caf5; }}
        \\    .radar-domain-lbl {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 600; font-size: 8px; fill: #7982a9; }}
        \\    .radar-domain-val {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 8px; fill: #c0caf5; }}
        \\    .radar-footnote {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 8px; fill: #565f89; }}
        \\  </style>
        \\  <rect width="{d}" height="{d}" rx="{d:.1}" fill="{s}" stroke="{s}" stroke-width="{d}"/>
        \\
    , .{
        width,
        height,
        width,
        height,
        opts.theme.bg_color,
        opts.theme.bg_color,
        dna.archetype_color,
        opts.theme.title_color,
        width,
        height,
        opts.border_radius,
        opts.theme.bg_color,
        opts.theme.border_color,
        if (opts.hide_border) @as(u32, 0) else @as(u32, 1),
    });

    // Card Header
    if (!opts.hide_title) {
        try w.print(
            \\  <!-- Header -->
            \\  <text x="16" y="24.0" class="radar-title">DEVELOPER DNA</text>
            \\  <circle cx="120" cy="20.5" r="2.0" fill="{s}"/>
            \\  <text x="128" y="23.5" class="radar-sub">5-AXIS POLYGLOT RADAR</text>
            \\
        , .{opts.theme.title_color});
    }

    // Concentric Pentagons (25%, 50%, 75%, 100%)
    const ring_scales = [4]f64{ 0.25, 0.50, 0.75, 1.00 };
    for (ring_scales, 0..) |scale, ring_idx| {
        const r = max_r * scale;
        const fill_style = if (ring_idx == 3) "rgba(31, 35, 53, 0.25)" else if (ring_idx == 1) "rgba(31, 35, 53, 0.15)" else "none";
        const stroke_color = if (ring_idx == 3) "#2e3c64" else "#24283b";

        try w.print(
            \\  <polygon points="{d:.1},{d:.1} {d:.1},{d:.1} {d:.1},{d:.1} {d:.1},{d:.1} {d:.1},{d:.1}" fill="{s}" stroke="{s}" stroke-width="0.8"/>
            \\
        , .{
            xc + cos_vals[0] * r, yc + sin_vals[0] * r,
            xc + cos_vals[1] * r, yc + sin_vals[1] * r,
            xc + cos_vals[2] * r, yc + sin_vals[2] * r,
            xc + cos_vals[3] * r, yc + sin_vals[3] * r,
            xc + cos_vals[4] * r, yc + sin_vals[4] * r,
            fill_style,
            stroke_color,
        });
    }

    // Spoke Lines from Center to Outer Vertices
    for (0..5) |i| {
        try w.print(
            \\  <line x1="{d:.1}" y1="{d:.1}" x2="{d:.1}" y2="{d:.1}" stroke="#2e3c64" stroke-width="0.8" stroke-dasharray="2,2"/>
            \\
        , .{
            xc,
            yc,
            xc + cos_vals[i] * max_r,
            yc + sin_vals[i] * max_r,
        });
    }

    // Filled Data Polygon
    try w.print(
        \\  <!-- Data Polygon -->
        \\  <polygon points="{d:.1},{d:.1} {d:.1},{d:.1} {d:.1},{d:.1} {d:.1},{d:.1} {d:.1},{d:.1}" fill="url(#radar-poly-grad)" stroke="{s}" stroke-width="1.8" filter="url(#radar-glow)"/>
        \\
    , .{
        v_x[0], v_y[0],
        v_x[1], v_y[1],
        v_x[2], v_y[2],
        v_x[3], v_y[3],
        v_x[4], v_y[4],
        dna.archetype_color,
    });

    // Vertex Nodes
    for (0..5) |i| {
        try w.print(
            \\  <circle cx="{d:.1}" cy="{d:.1}" r="2.8" fill="{s}" stroke="#1a1b27" stroke-width="1"/>
            \\
        , .{ v_x[i], v_y[i], dna.archetype_color });
    }

    // Spoke Tip Labels
    try w.print(
        \\  <!-- Spoke Labels -->
        \\  <text x="{d:.1}" y="{d:.1}" class="radar-axis-lbl" text-anchor="middle" fill="#ec915c">Systems</text>
        \\  <text x="{d:.1}" y="{d:.1}" class="radar-axis-lbl" text-anchor="start" fill="#70a5fd">Backend</text>
        \\  <text x="{d:.1}" y="{d:.1}" class="radar-axis-lbl" text-anchor="start" fill="#7aa2f7">Frontend</text>
        \\  <text x="{d:.1}" y="{d:.1}" class="radar-axis-lbl" text-anchor="end" fill="#bb9af7">DevOps</text>
        \\  <text x="{d:.1}" y="{d:.1}" class="radar-axis-lbl" text-anchor="end" fill="#73daca">Data &amp; AI</text>
        \\
    , .{
        xc,                  yc - max_r - 9.0, // Systems (top)
        xc + cos_vals[1] * max_r + 6.0, yc + sin_vals[1] * max_r + 2.0, // Backend (top-right)
        xc + cos_vals[2] * max_r + 4.0, yc + sin_vals[2] * max_r + 12.0, // Frontend (bottom-right)
        xc + cos_vals[3] * max_r - 4.0, yc + sin_vals[3] * max_r + 12.0, // DevOps (bottom-left)
        xc + cos_vals[4] * max_r - 6.0, yc + sin_vals[4] * max_r + 2.0, // Data (top-left)
    });

    // Glass Divider
    try w.print(
        \\  <!-- Glass Divider -->
        \\  <line x1="246.0" y1="22" x2="246.0" y2="158.0" stroke="url(#radar-divider-grad)" stroke-width="1"/>
        \\
    , .{});

    // Right Column: Archetype Pill & Domain Breakdown Bars
    try w.print(
        \\  <!-- Right Column: DNA Breakdown -->
        \\  <g transform="translate(254, 0)">
        \\    <!-- Archetype Badge Pill -->
        \\    <g transform="translate(75, 34)">
        \\      <rect x="-70" y="-12" width="140" height="24" rx="12" fill="#1f2335" stroke="{s}" stroke-opacity="0.45" stroke-width="1"/>
        \\      <text x="0" y="4" text-anchor="middle" class="radar-archetype-txt">{s} {s}</text>
        \\    </g>
        \\
    , .{
        dna.archetype_color,
        dna.archetype_icon,
        dna.archetype,
    });

    // 5 Domain Breakdown Rows
    const domain_names = [5][]const u8{ "Systems", "Backend", "Frontend", "DevOps", "Data &amp; AI" };
    const domain_colors = [5][]const u8{ "#ec915c", "#70a5fd", "#7aa2f7", "#bb9af7", "#73daca" };
    const bar_total_w: f64 = 142.0;

    for (0..5) |i| {
        const y_text: f64 = 56.0 + @as(f64, @floatFromInt(i)) * 18.0;
        const y_bar: f64 = y_text + 4.0;
        const pct_val = pcts[i];
        const fill_w = if (pct_val > 0.0) @max(3.5, (bar_total_w * pct_val) / 100.0) else 0.0;

        try w.print(
            \\    <text x="4" y="{d:.1}" class="radar-domain-lbl">{s}</text>
            \\    <text x="146" y="{d:.1}" class="radar-domain-val" text-anchor="end">{d:.0}%</text>
            \\    <rect x="4" y="{d:.1}" width="{d:.1}" height="3.5" rx="1.75" fill="#24283b"/>
            \\
        , .{
            y_text,
            domain_names[i],
            y_text,
            pct_val,
            y_bar,
            bar_total_w,
        });

        if (fill_w > 0.0) {
            try w.print(
                \\    <rect x="4" y="{d:.1}" width="{d:.1}" height="3.5" rx="1.75" fill="{s}"/>
                \\
            , .{ y_bar, fill_w, domain_colors[i] });
        }
    }

    // Languages Mapped Footnote
    try w.print(
        \\    <!-- Analyzed Languages Footnote -->
        \\    <text x="75" y="156" text-anchor="middle" class="radar-footnote">{d} Languages Mapped</text>
        \\  </g>
        \\</svg>
        \\
    , .{dna.total_languages});

    return try stream.toOwnedSlice();
}
