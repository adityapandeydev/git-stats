const std = @import("std");
const models = @import("../github/models.zig");
const themes = @import("themes.zig");

pub const RhythmRenderOptions = struct {
    theme: themes.Theme,
    card_width: u32 = 424,
    card_height: u32 = 180,
    border_radius: f64 = 4.5,
    hide_border: bool = false,
    hide_title: bool = false,
    animate: bool = true,
};

pub fn renderRhythmSVG(
    allocator: std.mem.Allocator,
    rhythm: *const models.CommitRhythm,
    opts: RhythmRenderOptions,
) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(allocator);
    defer stream.deinit();
    const w = &stream.writer;

    const width = opts.card_width;
    const height = opts.card_height;
    const h_f = @as(f64, @floatFromInt(height));

    const total_commits = rhythm.total_commits;
    const total_f: f64 = @floatFromInt(@max(1, total_commits));
    const day_pct: u32 = @intFromFloat((@as(f64, @floatFromInt(rhythm.day_commits)) / total_f) * 100.0);
    const night_pct: u32 = 100 - @min(100, day_pct);

    const bar_total_w: f64 = 92.0;
    const day_bar_w = @max(4.0, @min(bar_total_w - 4.0, (bar_total_w * @as(f64, @floatFromInt(day_pct))) / 100.0));
    const night_bar_w = bar_total_w - day_bar_w;

    // SVG Header & Defs
    try w.print(
        \\<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {d} {d}" width="{d}" height="{d}">
        \\  <defs>
        \\    <linearGradient id="rhythm-divider-grad" x1="0%" y1="0%" x2="0%" y2="100%">
        \\      <stop offset="0%" stop-color="{s}" stop-opacity="0.0"/>
        \\      <stop offset="50%" stop-color="#3b4261" stop-opacity="0.7"/>
        \\      <stop offset="100%" stop-color="{s}" stop-opacity="0.0"/>
        \\    </linearGradient>
        \\    <linearGradient id="rhythm-day-grad" x1="0%" y1="0%" x2="100%" y2="0%">
        \\      <stop offset="0%" stop-color="#70a5fd"/>
        \\      <stop offset="100%" stop-color="#7aa2f7"/>
        \\    </linearGradient>
        \\    <linearGradient id="rhythm-night-grad" x1="0%" y1="0%" x2="100%" y2="0%">
        \\      <stop offset="0%" stop-color="#bb9af7"/>
        \\      <stop offset="100%" stop-color="#9d7cd8"/>
        \\    </linearGradient>
        \\    <filter id="peak-glow" x="-50%" y="-50%" width="200%" height="200%">
        \\      <feGaussianBlur in="SourceGraphic" stdDeviation="2.5" result="blur"/>
        \\      <feMerge>
        \\        <feMergeNode in="blur"/>
        \\        <feMergeNode in="SourceGraphic"/>
        \\      </feMerge>
        \\    </filter>
        \\  </defs>
        \\
    , .{
        width,
        height,
        width,
        height,
        opts.theme.bg_color,
        opts.theme.bg_color,
    });

    // Stylesheet
    try w.print(
        \\  <style>
        \\    .rhythm-title {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 12.5px; letter-spacing: 1.2px; fill: {s}; }}
        \\    .rhythm-sub {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 9px; letter-spacing: 0.5px; fill: #787c99; }}
        \\    .rhythm-lbl {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 600; font-size: 8px; fill: #565f89; }}
        \\    .rhythm-persona-txt {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 10px; letter-spacing: 0.6px; fill: {s}; }}
        \\    .rhythm-kpi-lbl {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 8px; letter-spacing: 0.8px; fill: #7aa2f7; }}
        \\    .rhythm-kpi-val {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 13px; fill: #c0caf5; }}
        \\    .rhythm-stat-txt {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 600; font-size: 8.5px; fill: #7982a9; }}
        \\    .rhythm-count-txt {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 8px; fill: #565f89; }}
        \\  </style>
        \\
    , .{
        opts.theme.title_color,
        rhythm.persona_color,
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

    // Header
    const header_y: f64 = 25.0;
    if (!opts.hide_title) {
        try w.print(
            \\  <!-- Header -->
            \\  <text x="22" y="{d:.1}" class="rhythm-title">COMMIT RHYTHM</text>
            \\  <circle cx="152" cy="{d:.1}" r="2.5" fill="{s}"/>
            \\  <text x="160" y="{d:.1}" class="rhythm-sub">24H × 7D MATRIX</text>
            \\
        , .{
            header_y,
            header_y - 3.5,
            rhythm.persona_color,
            header_y - 0.5,
        });
    }

    // Day Labels on the Left
    const day_names = [_][]const u8{ "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" };
    const matrix_start_y: f64 = if (opts.hide_title) 28.0 else 50.0;
    const row_step: f64 = 12.0;

    for (day_names, 0..) |day, d_idx| {
        const y = matrix_start_y + @as(f64, @floatFromInt(d_idx)) * row_step + 8.0;
        try w.print(
            \\  <text x="34" y="{d:.1}" class="rhythm-lbl" text-anchor="end">{s}</text>
            \\
        , .{ y, day });
    }

    // Matrix Cells (24 columns x 7 rows)
    const col_step: f64 = 10.0;
    const cell_w: f64 = 8.0;
    const cell_h: f64 = 8.5;
    const matrix_start_x: f64 = 42.0;

    const peak_cnt = @max(1, rhythm.peak_count);
    const peak_f: f64 = @floatFromInt(peak_cnt);

    try w.print(
        \\  <!-- Matrix Cells -->
        \\  <g transform="translate({d:.1}, {d:.1})">
        \\
    , .{ matrix_start_x, matrix_start_y });

    for (0..7) |d| {
        const row_y = @as(f64, @floatFromInt(d)) * row_step;
        for (0..24) |h| {
            const col_x = @as(f64, @floatFromInt(h)) * col_step;
            const count = rhythm.matrix[d][h];

            if (count == 0) {
                try w.print(
                    \\    <rect x="{d:.1}" y="{d:.1}" width="{d:.1}" height="{d:.1}" rx="2" fill="#1f2335" fill-opacity="0.35"/>
                    \\
                , .{ col_x, row_y, cell_w, cell_h });
            } else {
                const ratio = @as(f64, @floatFromInt(count)) / peak_f;
                var fill_color: []const u8 = "#2e3c64";
                var is_glow: bool = false;

                if (count == rhythm.peak_count and count >= 5) {
                    fill_color = "#bb9af7";
                    is_glow = true;
                } else if (ratio >= 0.70) {
                    fill_color = "#bb9af7";
                } else if (ratio >= 0.40) {
                    fill_color = "#7aa2f7";
                } else if (ratio >= 0.15) {
                    fill_color = "#3d59a1";
                } else {
                    fill_color = "#2e3c64";
                }

                if (is_glow) {
                    try w.print(
                        \\    <rect x="{d:.1}" y="{d:.1}" width="{d:.1}" height="{d:.1}" rx="2" fill="{s}" filter="url(#peak-glow)"/>
                        \\
                    , .{ col_x, row_y, cell_w, cell_h, fill_color });
                } else {
                    try w.print(
                        \\    <rect x="{d:.1}" y="{d:.1}" width="{d:.1}" height="{d:.1}" rx="2" fill="{s}"/>
                        \\
                    , .{ col_x, row_y, cell_w, cell_h, fill_color });
                }
            }
        }
    }

    // Bottom Hour Labels
    const hour_lbl_y = 7.0 * row_step + 10.0;
    try w.print(
        \\    <text x="0" y="{d:.1}" class="rhythm-lbl" text-anchor="middle">12a</text>
        \\    <text x="40" y="{d:.1}" class="rhythm-lbl" text-anchor="middle">4a</text>
        \\    <text x="80" y="{d:.1}" class="rhythm-lbl" text-anchor="middle">8a</text>
        \\    <text x="120" y="{d:.1}" class="rhythm-lbl" text-anchor="middle">12p</text>
        \\    <text x="160" y="{d:.1}" class="rhythm-lbl" text-anchor="middle">4p</text>
        \\    <text x="200" y="{d:.1}" class="rhythm-lbl" text-anchor="middle">8p</text>
        \\    <text x="230" y="{d:.1}" class="rhythm-lbl" text-anchor="middle">11p</text>
        \\  </g>
        \\
    , .{ hour_lbl_y, hour_lbl_y, hour_lbl_y, hour_lbl_y, hour_lbl_y, hour_lbl_y, hour_lbl_y });

    // Vertical Divider Line
    const div_x: f64 = 296.0;
    try w.print(
        \\  <!-- Glass Divider -->
        \\  <line x1="{d:.1}" y1="22" x2="{d:.1}" y2="{d:.1}" stroke="url(#rhythm-divider-grad)" stroke-width="1"/>
        \\
    , .{ div_x, div_x, h_f - 22.0 });

    // Right Column: Persona & Analytics
    try w.print(
        \\  <!-- Right Column: Analytics & Persona -->
        \\  <g transform="translate(306, 0)">
        \\    <!-- Persona Badge Pill -->
        \\    <g transform="translate(54, 38)">
        \\      <rect x="-48" y="-12" width="96" height="24" rx="12" fill="#1f2335" stroke="{s}" stroke-opacity="0.4" stroke-width="1"/>
        \\      <text x="0" y="4" text-anchor="middle" class="rhythm-persona-txt">{s} {s}</text>
        \\    </g>
        \\
        \\    <!-- Peak Window KPI -->
        \\    <g transform="translate(8, 72)">
        \\      <text x="0" y="0" class="rhythm-kpi-lbl">PEAK WINDOW</text>
        \\      <text x="0" y="15" class="rhythm-kpi-val">{s}</text>
        \\    </g>
        \\
        \\    <!-- Circadian Split Bar -->
        \\    <g transform="translate(8, 108)">
        \\      <text x="0" y="0" class="rhythm-kpi-lbl">CIRCADIAN SPLIT</text>
        \\      <rect x="0" y="6" width="92" height="6" rx="3" fill="#24283b"/>
        \\      <rect x="0" y="6" width="{d:.1}" height="6" rx="3" fill="url(#rhythm-day-grad)"/>
        \\      <rect x="{d:.1}" y="6" width="{d:.1}" height="6" rx="3" fill="url(#rhythm-night-grad)"/>
        \\      <text x="0" y="24" class="rhythm-stat-txt">☀️ {d}% Day</text>
        \\      <text x="92" y="24" class="rhythm-stat-txt" text-anchor="end">🌙 {d}% Night</text>
        \\    </g>
        \\
        \\    <!-- Analyzed Commits Footnote -->
        \\    <text x="54" y="156" text-anchor="middle" class="rhythm-count-txt">{d} Commits Mapped</text>
        \\  </g>
        \\
    , .{
        rhythm.persona_color,
        rhythm.persona_icon,
        rhythm.persona_title,
        rhythm.peak_window_str,
        day_bar_w,
        day_bar_w,
        night_bar_w,
        day_pct,
        night_pct,
        total_commits,
    });

    try w.print("</svg>\n", .{});
    return try stream.toOwnedSlice();
}
