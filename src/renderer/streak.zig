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

pub fn renderStreakSVG(allocator: std.mem.Allocator, stats: *const models.StreakStats, opts: StreakRenderOptions) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(allocator);
    defer stream.deinit();
    const w = &stream.writer;
    const width = opts.card_width;
    const height = opts.card_height;
    const w_f: f64 = @floatFromInt(width);
    const h_f: f64 = @floatFromInt(height);
    const content_height: f64 = if (opts.show_sparkline) 180 else 124;
    // Scale the complete composition uniformly for compact/custom dimensions.
    const scale = @min(w_f / 424.0, h_f / content_height);
    const tier = getFlameTier(stats.current_streak);
    const badge = tier.badge_label[(std.mem.indexOfScalar(u8, tier.badge_label, ' ') orelse 0) + 1 ..];
    const digits = std.fmt.count("{d}", .{stats.current_streak});
    const count_size: u32 = if (digits <= 2) 45 else if (digits == 3) 36 else if (digits == 4) 28 else if (digits <= 6) 18 else 12;
    const days_x = 18.0 + @as(f64, @floatFromInt(digits * count_size)) * 0.60;
    const metric_size: u32 = if (stats.total_contributions >= 1000000 or stats.longest_streak >= 1000000) 14 else 20;
    const total_range = try dateRange(allocator, stats.first_contribution_date, stats.latest_contribution_date, stats.total_contributions == 0);
    defer allocator.free(total_range);
    const longest_range = try dateRange(allocator, stats.longest_streak_start, stats.longest_streak_end, stats.longest_streak == 0);
    defer allocator.free(longest_range);
    const current_range = if (stats.current_streak == 0) try allocator.dupe(u8, "No active streak") else try dateRange(allocator, stats.current_streak_start, stats.current_streak_end, false);
    defer allocator.free(current_range);
    try w.print(
        \\<svg xmlns="http://www.w3.org/2000/svg" width="{d}" height="{d}" viewBox="0 0 {d} {d}" role="img" aria-label="GitHub contribution streak">
        \\<defs><linearGradient id="bg" x2="1" y2="1"><stop stop-color="{s}"/><stop offset="1" stop-color="{s}"/></linearGradient><linearGradient id="sparkline-grad"><stop stop-color="{s}"/><stop offset="1" stop-color="{s}"/></linearGradient><linearGradient id="sparkline-fill" x2="0" y2="1"><stop stop-color="{s}" stop-opacity=".16"/><stop offset="1" stop-color="{s}" stop-opacity="0"/></linearGradient><radialGradient id="aura"><stop stop-color="{s}" stop-opacity=".12"/><stop offset="1" stop-color="{s}" stop-opacity="0"/></radialGradient><filter id="subtle-glow"><feGaussianBlur stdDeviation="1.2"/></filter></defs>
        \\<rect width="{d}" height="{d}" rx="{d:.1}" fill="url(#bg)" stroke="{s}"/>
        \\<g transform="translate({d:.2} {d:.2}) scale({d:.4})">
        \\<ellipse cx="64" cy="52" rx="76" ry="51" fill="url(#aura)"/>
        \\<style>@keyframes streak-flame {{ 50% {{ opacity:.55; }} }} @media(prefers-reduced-motion:reduce) {{ g {{ animation:none!important; }} }}</style>
        \\<g font-family="-apple-system,BlinkMacSystemFont,Segoe UI,Arial,sans-serif">
        \\<text x="18" y="22" fill="{s}" font-size="8" font-weight="600" letter-spacing="1.1">CURRENT STREAK</text>
        \\<text x="17" y="68" fill="{s}" font-size="{d}" font-weight="750" letter-spacing="-2">{d}</text>
    , .{
        width,
        height,
        width,
        height,
        opts.theme.bg_color,
        opts.theme.bg_color,
        opts.theme.title_color,
        tier.primary_color,
        tier.primary_color,
        tier.primary_color,
        tier.primary_color,
        tier.primary_color,
        width,
        height,
        opts.border_radius,
        if (opts.hide_border) "none" else opts.theme.border_color,
        (w_f - 424.0 * scale) / 2.0,
        (h_f - content_height * scale) / 2.0,
        scale,
        opts.theme.muted_color,
        tier.primary_color,
        count_size,
        stats.current_streak,
    });
    try w.print(
        \\<text x="{d:.1}" y="66" fill="{s}" font-size="11">{s}</text>
        \\<g transform="translate(108 37) scale(.85)" {s} fill="none" stroke="{s}" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3q1 4 4 6.5t3 5.5a1 1 0 0 1-14 0 5 5 0 0 1 1-3 1 1 0 0 0 5 0c0-2-1.5-3-1.5-5q0-2 2.5-4"/></g>
        \\<rect x="18" y="79" width="115" height="17" rx="8.5" fill="{s}" fill-opacity=".08" stroke="{s}" stroke-opacity=".3"/>
        \\<circle cx="28" cy="87.5" r="2" fill="{s}"/><text x="37" y="90.5" fill="{s}" font-size="7.7" font-weight="650" letter-spacing=".65">{s}</text>
        \\<path d="M149 18V96" stroke="{s}"/>
        \\<text x="165" y="28" fill="{s}" font-size="11">Total Contributions</text><text x="405" y="29" text-anchor="end" fill="{s}" font-size="{d}" font-weight="700">{d}</text>
        \\<text x="165" y="45" fill="{s}" font-size="9">{s}</text>
        \\<path d="M165 55H405" stroke="{s}"/>
        \\<text x="165" y="76" fill="{s}" font-size="11">Longest Streak</text><text x="405" y="77" text-anchor="end" fill="{s}" font-size="{d}" font-weight="700">{d}</text>
        \\<text x="165" y="93" fill="{s}" font-size="9">{s}</text>
        \\<path d="M18 105H406" stroke="{s}"/>
    , .{
        days_x,
        opts.theme.muted_color,
        if (stats.current_streak == 1) "day" else "days",
        if (opts.animate) "style=\"animation: streak-flame 2.8s ease-in-out infinite;transform-box:fill-box;transform-origin:center\"" else "",
        tier.primary_color,
        tier.primary_color,
        tier.primary_color,
        tier.primary_color,
        tier.primary_color,
        badge,
        opts.theme.border_color,
        opts.theme.text_color,
        opts.theme.text_color,
        metric_size,
        stats.total_contributions,
        opts.theme.muted_color,
        total_range,
        opts.theme.border_color,
        opts.theme.text_color,
        opts.theme.text_color,
        metric_size,
        stats.longest_streak,
        opts.theme.muted_color,
        longest_range,
        opts.theme.border_color,
    });
    try w.print(
        \\<text x="18" y="119" fill="{s}" font-size="8" letter-spacing=".7">CURRENT</text><text x="405" y="119" text-anchor="end" fill="{s}" font-size="9">{s}</text>
    , .{
        opts.theme.muted_color,
        opts.theme.muted_color,
        current_range,
    });

    // --- 14-DAY MOMENTUM SPARKLINE ---
    if (opts.show_sparkline) {
        const spark_x_start = 18.0;
        const spark_x_end = 406.0;
        const spark_width = spark_x_end - spark_x_start;
        const spark_base_y = 169.0;
        const spark_max_h = 22.0;

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
            \\  <text x="{d:.1}" y="{d:.1}" class="spark-lbl" font-size="7.5" letter-spacing="0.8" fill="{s}">14-DAY MOMENTUM</text>
            \\  <text x="{d:.1}" y="{d:.1}" text-anchor="end" class="spark-lbl" font-size="7.5" letter-spacing="0.5" fill="{s}">{d} COMMITS</text>
            \\
        , .{
            spark_x_start,
            spark_base_y - spark_max_h - 9.0,
            opts.theme.muted_color,
            spark_x_end,
            spark_base_y - spark_max_h - 9.0,
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

    try w.writeAll("</g></g></svg>\n");
    return stream.toOwnedSlice();
}

// API dates are plain text. Escape them before writing into XML; empty accounts
// must not display synthetic ranges such as "None – None".
fn dateRange(a: std.mem.Allocator, start: []const u8, end: []const u8, empty: bool) ![]u8 {
    if (empty) return a.dupe(u8, "No activity yet");
    var out = std.Io.Writer.Allocating.init(a);
    defer out.deinit();
    for ([_][]const u8{ start, " – ", end }) |part| {
        for (part) |c| switch (c) {
            '&' => try out.writer.writeAll("&amp;"),
            '<' => try out.writer.writeAll("&lt;"),
            '>' => try out.writer.writeAll("&gt;"),
            else => try out.writer.writeByte(c),
        };
    }
    return out.toOwnedSlice();
}
