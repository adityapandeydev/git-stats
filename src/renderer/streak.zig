const std = @import("std");
const models = @import("../github/models.zig");
const themes = @import("themes.zig");

pub const StreakRenderOptions = struct {
    theme: themes.Theme,
    card_width: u32 = 424,
    card_height: u32 = 180,
    border_radius: f64 = 4.5,
    hide_border: bool = false,
    animate: bool = true,
    show_sparkline: bool = true,
    mode: []const u8 = "standard", // "standard", "hero_wide", "hero_tall", "compact_col"
};

pub const FlameTier = struct {
    name: []const u8,
    primary_color: []const u8,
    secondary_color: []const u8,
    tertiary_color: ?[]const u8 = null,
    aura_opacity: []const u8,
    badge_label: []const u8,
};

pub fn getFlameTier(streak: u32) FlameTier {
    if (streak >= 365) {
        return .{
            .name = "Mythic Celestial",
            .primary_color = "#bb9af7",
            .secondary_color = "#f7768e",
            .tertiary_color = "#ff9e64",
            .aura_opacity = "0.35",
            .badge_label = "⚡ MYTHIC STREAK",
        };
    } else if (streak >= 100) {
        return .{
            .name = "Blazing Ember",
            .primary_color = "#f7768e",
            .secondary_color = "#ff9e64",
            .aura_opacity = "0.30",
            .badge_label = "🔥 CENTURY STREAK",
        };
    } else if (streak >= 30) {
        return .{
            .name = "Electric Amber",
            .primary_color = "#ff9e64",
            .secondary_color = "#e0af68",
            .aura_opacity = "0.25",
            .badge_label = "🔥 ACTIVE STREAK",
        };
    } else if (streak >= 7) {
        return .{
            .name = "Neon Purple",
            .primary_color = "#bb9af7",
            .secondary_color = "#7aa2f7",
            .aura_opacity = "0.20",
            .badge_label = "⚡ ON A ROLL",
        };
    } else {
        return .{
            .name = "Electric Blue",
            .primary_color = "#70a5fd",
            .secondary_color = "#7dcfff",
            .aura_opacity = "0.15",
            .badge_label = "🌱 BUILDING HABIT",
        };
    }
}

pub fn renderStreakSVG(
    allocator: std.mem.Allocator,
    stats: *const models.StreakStats,
    opts: StreakRenderOptions,
) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(allocator);
    defer stream.deinit();
    const w = &stream.writer;

    const width = opts.card_width;
    const height = opts.card_height;
    const tier = getFlameTier(stats.current_streak);

    const w_f = @as(f64, @floatFromInt(width));
    const h_f = @as(f64, @floatFromInt(height));

    // Column positions
    const col1_x = w_f * 0.22;
    const col2_x = w_f * 0.50;
    const col3_x = w_f * 0.78;

    const div1_x = w_f * 0.355;
    const div2_x = w_f * 0.645;

    // SVG Header
    try w.print(
        \\<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {d} {d}" width="{d}" height="{d}">
        \\  <defs>
        \\    <filter id="core-glow" x="-50%" y="-50%" width="200%" height="200%">
        \\      <feGaussianBlur in="SourceGraphic" stdDeviation="4" result="blur1"/>
        \\      <feGaussianBlur in="SourceGraphic" stdDeviation="8" result="blur2"/>
        \\      <feMerge>
        \\        <feMergeNode in="blur2"/>
        \\        <feMergeNode in="blur1"/>
        \\        <feMergeNode in="SourceGraphic"/>
        \\      </feMerge>
        \\    </filter>
        \\    <filter id="subtle-glow" x="-30%" y="-30%" width="160%" height="160%">
        \\      <feGaussianBlur in="SourceGraphic" stdDeviation="2.5" result="blur"/>
        \\      <feMerge>
        \\        <feMergeNode in="blur"/>
        \\        <feMergeNode in="SourceGraphic"/>
        \\      </feMerge>
        \\    </filter>
        \\
    , .{ width, height, width, height });

    // Flame Tier Gradient
    if (tier.tertiary_color) |tertiary| {
        try w.print(
            \\    <linearGradient id="flame-grad" x1="0%" y1="100%" x2="0%" y2="0%">
            \\      <stop offset="0%" stop-color="{s}"/>
            \\      <stop offset="50%" stop-color="{s}"/>
            \\      <stop offset="100%" stop-color="{s}"/>
            \\    </linearGradient>
            \\
        , .{ tertiary, tier.secondary_color, tier.primary_color });
    } else {
        try w.print(
            \\    <linearGradient id="flame-grad" x1="0%" y1="100%" x2="0%" y2="0%">
            \\      <stop offset="0%" stop-color="{s}"/>
            \\      <stop offset="100%" stop-color="{s}"/>
            \\    </linearGradient>
            \\
        , .{ tier.secondary_color, tier.primary_color });
    }

    // Energy Aura Gradient
    try w.print(
        \\    <radialGradient id="energy-aura" cx="50%" cy="50%" r="50%">
        \\      <stop offset="0%" stop-color="{s}" stop-opacity="{s}"/>
        \\      <stop offset="60%" stop-color="{s}" stop-opacity="0.08"/>
        \\      <stop offset="100%" stop-color="{s}" stop-opacity="0.0"/>
        \\    </radialGradient>
        \\    <linearGradient id="divider-grad" x1="0%" y1="0%" x2="0%" y2="100%">
        \\      <stop offset="0%" stop-color="{s}" stop-opacity="0.0"/>
        \\      <stop offset="50%" stop-color="{s}" stop-opacity="0.35"/>
        \\      <stop offset="100%" stop-color="{s}" stop-opacity="0.0"/>
        \\    </linearGradient>
        \\    <linearGradient id="sparkline-grad" x1="0%" y1="0%" x2="100%" y2="0%">
        \\      <stop offset="0%" stop-color="#70a5fd"/>
        \\      <stop offset="50%" stop-color="{s}"/>
        \\      <stop offset="100%" stop-color="{s}"/>
        \\    </linearGradient>
        \\    <linearGradient id="sparkline-fill" x1="0%" y1="0%" x2="0%" y2="100%">
        \\      <stop offset="0%" stop-color="{s}" stop-opacity="0.22"/>
        \\      <stop offset="100%" stop-color="{s}" stop-opacity="0.0"/>
        \\    </linearGradient>
        \\  </defs>
        \\
    , .{
        tier.primary_color,
        tier.aura_opacity,
        tier.secondary_color,
        opts.theme.bg_color,
        opts.theme.title_color,
        opts.theme.title_color,
        opts.theme.title_color,
        tier.primary_color,
        tier.secondary_color,
        tier.primary_color,
        opts.theme.bg_color,
    });

    // Stylesheet & Keyframes
    try w.print(
        \\  <style>
        \\    @keyframes flamePulse {{
        \\      0%, 100% {{ transform: scale(1.0); }}
        \\      50% {{ transform: scale(1.08); }}
        \\    }}
        \\    @keyframes auraPulse {{
        \\      0%, 100% {{ transform: scale(1.0); opacity: 0.8; }}
        \\      50% {{ transform: scale(1.15); opacity: 1.0; }}
        \\    }}
        \\    @keyframes ringSpin {{
        \\      from {{ stroke-dashoffset: 0; }}
        \\      to {{ stroke-dashoffset: 48; }}
        \\    }}
        \\    @keyframes cardFadeIn {{
        \\      from {{ opacity: 0; transform: translateY(4px); }}
        \\      to {{ opacity: 1; transform: translateY(0); }}
        \\    }}
        \\    .stat-val {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; }}
        \\    .stat-lbl {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 600; }}
        \\    .stat-sub {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 400; }}
        \\    .spark-lbl {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; }}
        \\  </style>
        \\
    , .{});

    // Card Background
    const stroke_attr = if (opts.hide_border)
        "stroke=\"none\""
    else
        "stroke=\"#24283b\" stroke-width=\"1\"";

    try w.print(
        \\  <rect width="{d}" height="{d}" rx="{d:.1}" fill="{s}" {s}/>
        \\
    , .{ width, height, opts.border_radius, opts.theme.bg_color, stroke_attr });

    // Vertical alignment shift when sparkline is hidden to keep card perfectly balanced
    const y_shift: f64 = if (!opts.show_sparkline) 12.0 else 0.0;

    // Glass Divider Lines
    const div_top = 22.0 + y_shift;
    const div_bot = if (!opts.show_sparkline) @min(h_f - 22.0, 142.0) else @min(h_f - 48.0, 130.0);
    try w.print(
        \\  <line x1="{d:.1}" y1="{d:.1}" x2="{d:.1}" y2="{d:.1}" stroke="url(#divider-grad)" stroke-width="1"/>
        \\  <line x1="{d:.1}" y1="{d:.1}" x2="{d:.1}" y2="{d:.1}" stroke="url(#divider-grad)" stroke-width="1"/>
        \\
    , .{ div1_x, div_top, div1_x, div_bot, div2_x, div_top, div2_x, div_bot });

    // --- LEFT COLUMN: Total Contributions ---
    try w.print(
        \\  <!-- Left Column: Total Contributions -->
        \\  <g transform="translate({d:.1}, {d:.1})">
        \\    <text x="0" y="60" text-anchor="middle" class="stat-val" font-size="24" fill="{s}">{d}</text>
        \\    <text x="0" y="82" text-anchor="middle" class="stat-lbl" font-size="12" fill="#a9b1d6">Total Contributions</text>
        \\    <text x="0" y="103" text-anchor="middle" class="stat-sub" font-size="10.5" fill="#565f89">{s} - {s}</text>
        \\  </g>
        \\
    , .{
        col1_x,
        y_shift,
        opts.theme.title_color,
        stats.total_contributions,
        stats.first_contribution_date,
        stats.latest_contribution_date,
    });

    // --- CENTER COLUMN: Energy Core & Current Streak ---
    const flame_cy = 33.0 + y_shift;
    const anim_flame = if (opts.animate) "style=\"animation: flamePulse 2.8s ease-in-out infinite; transform-origin: 0px 0px;\"" else "";
    const anim_aura = if (opts.animate) "style=\"animation: auraPulse 3.5s ease-in-out infinite; transform-origin: 0px 0px;\"" else "";
    const anim_ring = if (opts.animate) "style=\"animation: ringSpin 12s linear infinite;\"" else "";

    try w.print(
        \\  <!-- Center Column: Glowing Energy Core -->
        \\  <g transform="translate({d:.1}, {d:.1})">
        \\    <!-- Radial Aura -->
        \\    <circle cx="0" cy="0" r="30" fill="url(#energy-aura)" {s}/>
        \\    <!-- Orbit Ring -->
        \\    <circle cx="0" cy="0" r="21" fill="none" stroke="url(#flame-grad)" stroke-width="1.3" stroke-dasharray="5 3.5" opacity="0.65" {s}/>
        \\    <!-- Vector Flame Core -->
        \\    <g {s}>
        \\      <!-- Flame Silhouette -->
        \\      <path d="M 0 -12 C 1.2 -7.5 3.5 -4.5 6 -2.5 C 8 -1 9.5 1.5 9.5 4.5 C 9.5 9.5 5 13.5 0 13.5 C -5 13.5 -9.5 9.5 -9.5 4.5 C -9.5 1 -7 -2 -4.5 -4 C -4 -1 -2 1.5 -0.5 1.5 C -0.5 1.5 0.5 -1 0.5 -3.5 C 0.5 -6 -0.5 -8.5 0 -12 Z" fill="url(#flame-grad)" filter="url(#core-glow)"/>
        \\      <!-- Inner Flame Highlight -->
        \\      <path d="M 0 -3.5 C 1 -1.5 2.5 0.5 2.5 3 C 2.5 5 1.2 6.5 0 6.5 C -1.2 6.5 -2.5 5 -2.5 3 C -2.5 1 -1 -0.5 0 -3.5 Z" fill="#ffffff" opacity="0.9"/>
        \\    </g>
        \\  </g>
        \\
        \\  <!-- Current Streak Count -->
        \\  <text x="{d:.1}" y="{d:.1}" text-anchor="middle" class="stat-val" font-size="28" fill="url(#flame-grad)" filter="url(#subtle-glow)">{d}</text>
        \\
        \\  <!-- Streak Pill Badge -->
        \\  <g transform="translate({d:.1}, {d:.1})">
        \\    <rect x="-60" y="0" width="120" height="17" rx="8.5" fill="{s}" fill-opacity="0.16" stroke="url(#flame-grad)" stroke-width="1"/>
        \\    <text x="0" y="11.5" text-anchor="middle" class="stat-lbl" font-size="8.8" letter-spacing="0.8" fill="#ffffff">{s}</text>
        \\  </g>
        \\
        \\  <!-- Range Subtitle -->
        \\  <text x="{d:.1}" y="{d:.1}" text-anchor="middle" class="stat-sub" font-size="10.5" fill="#787c99">{s} - {s}</text>
        \\
    , .{
        col2_x,
        flame_cy,
        anim_aura,
        anim_ring,
        anim_flame,
        col2_x,
        76.0 + y_shift,
        stats.current_streak,
        col2_x,
        86.0 + y_shift,
        tier.primary_color,
        tier.badge_label,
        col2_x,
        118.0 + y_shift,
        stats.current_streak_start,
        stats.current_streak_end,
    });

    // --- RIGHT COLUMN: Longest Streak ---
    try w.print(
        \\  <!-- Right Column: Longest Streak -->
        \\  <g transform="translate({d:.1}, {d:.1})">
        \\    <text x="0" y="60" text-anchor="middle" class="stat-val" font-size="24" fill="{s}">{d}</text>
        \\    <text x="0" y="82" text-anchor="middle" class="stat-lbl" font-size="12" fill="#a9b1d6">Longest Streak</text>
        \\    <text x="0" y="103" text-anchor="middle" class="stat-sub" font-size="10.5" fill="#565f89">{s} - {s}</text>
        \\  </g>
        \\
    , .{
        col3_x,
        y_shift,
        opts.theme.title_color,
        stats.longest_streak,
        stats.longest_streak_start,
        stats.longest_streak_end,
    });

    // --- 14-DAY ACTIVITY MOMENTUM SPARKLINE ---
    if (opts.show_sparkline) {
        const spark_x_start = 28.0;
        const spark_x_end = w_f - 28.0;
        const spark_width = spark_x_end - spark_x_start;
        const spark_base_y = h_f - 14.0;
        const spark_max_h = 24.0;

        const max_c = @max(stats.max_14_day_count, 1);

        var pt_x: [14]f64 = undefined;
        var pt_y: [14]f64 = undefined;

        for (0..14) |i| {
            const i_f = @as(f64, @floatFromInt(i));
            pt_x[i] = spark_x_start + (i_f / 13.0) * spark_width;
            const cnt_f = @as(f64, @floatFromInt(stats.recent_14_days[i]));
            const ratio = @min(cnt_f / @as(f64, @floatFromInt(max_c)), 1.0);
            pt_y[i] = spark_base_y - (ratio * spark_max_h);
        }

        // Header label above sparkline
        try w.print(
            \\  <!-- 14-Day Activity Sparkline -->
            \\  <text x="{d:.1}" y="{d:.1}" class="spark-lbl" font-size="8.5" letter-spacing="0.8" fill="#565f89">14-DAY ACTIVITY MOMENTUM</text>
            \\  <text x="{d:.1}" y="{d:.1}" text-anchor="end" class="spark-lbl" font-size="8.5" letter-spacing="0.5" fill="{s}">{d} COMMITS</text>
            \\
        , .{
            spark_x_start,
            spark_base_y - spark_max_h - 6.0,
            spark_x_end,
            spark_base_y - spark_max_h - 6.0,
            tier.primary_color,
            stats.total_14_day_count,
        });

        // Build smooth cubic bezier curve
        var path_d = std.Io.Writer.Allocating.init(allocator);
        defer path_d.deinit();
        const pw = &path_d.writer;

        try pw.print("M {d:.2} {d:.2}", .{ pt_x[0], pt_y[0] });

        for (0..13) |i| {
            const dx = (pt_x[i + 1] - pt_x[i]) / 2.5;
            const cp1x = pt_x[i] + dx;
            const cp1y = pt_y[i];
            const cp2x = pt_x[i + 1] - dx;
            const cp2y = pt_y[i + 1];
            try pw.print(" C {d:.2} {d:.2}, {d:.2} {d:.2}, {d:.2} {d:.2}", .{
                cp1x, cp1y, cp2x, cp2y, pt_x[i + 1], pt_y[i + 1],
            });
        }

        // Sparkline Fill Path
        try w.print(
            \\  <path d="{s} L {d:.2} {d:.2} L {d:.2} {d:.2} Z" fill="url(#sparkline-fill)"/>
            \\  <path d="{s}" fill="none" stroke="url(#sparkline-grad)" stroke-width="2" stroke-linecap="round"/>
            \\
        , .{
            path_d.written(),
            pt_x[13],
            spark_base_y + 4.0,
            pt_x[0],
            spark_base_y + 4.0,
            path_d.written(),
        });

        // Mini dots along the sparkline
        for (0..13) |i| {
            if (stats.recent_14_days[i] > 0) {
                try w.print(
                    \\  <circle cx="{d:.2}" cy="{d:.2}" r="1.8" fill="#70a5fd" opacity="0.6"/>
                    \\
                , .{ pt_x[i], pt_y[i] });
            }
        }

        // Glowing today dot on the 14th point
        try w.print(
            \\  <!-- Today Active Dot -->
            \\  <circle cx="{d:.2}" cy="{d:.2}" r="3.2" fill="{s}" filter="url(#subtle-glow)"/>
            \\  <circle cx="{d:.2}" cy="{d:.2}" r="1.5" fill="#ffffff"/>
            \\
        , .{ pt_x[13], pt_y[13], tier.primary_color, pt_x[13], pt_y[13] });
    }

    try w.print("</svg>\n", .{});

    return try stream.toOwnedSlice();
}
