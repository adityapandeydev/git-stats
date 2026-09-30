const std = @import("std");
const models = @import("../github/models.zig");
const themes = @import("themes.zig");

pub const RenderOptions = struct {
    theme: themes.Theme = themes.tokyonight,
    card_width: u32 = 400,
    card_height: u32 = 364,
    langs_count: usize = 8,
    columns: usize = 2,
    layout: []const u8 = "standard",
    hide_title: bool = false,
    custom_title: ?[]const u8 = null,
    animate: bool = true,
    border_radius: f64 = 4.5,
    hide_border: bool = false,
    show_percent: bool = true,
};

/// Helper to escape XML / SVG strings
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

pub fn renderSVG(allocator: std.mem.Allocator, stats: *const models.UserStats, opts: RenderOptions) ![]u8 {
    var options = opts;
    if (options.card_width == 0) options.card_width = 450;
    if (options.langs_count == 0) options.langs_count = 8;
    if (options.border_radius <= 0) {
        options.border_radius = options.theme.border_radius;
        if (options.border_radius <= 0) options.border_radius = 4.5;
    }

    const count = @min(stats.languages.len, options.langs_count);
    const visible_langs = try allocator.alloc(models.LanguageStat, count);
    defer allocator.free(visible_langs);

    var total_visible_bytes: u64 = 0;
    for (stats.languages[0..count], 0..) |l, i| {
        visible_langs[i] = l;
        total_visible_bytes += l.size;
    }

    for (visible_langs) |*l| {
        if (total_visible_bytes > 0) {
            l.percentage = (@as(f64, @floatFromInt(l.size)) / @as(f64, @floatFromInt(total_visible_bytes))) * 100.0;
        } else {
            l.percentage = 0;
        }
    }

    if (std.mem.eql(u8, options.layout, "donut")) {
        return renderDonutLayout(allocator, visible_langs, options);
    } else if (std.mem.eql(u8, options.layout, "compact")) {
        return renderCompactLayout(allocator, visible_langs, options);
    } else {
        return renderStandardLayout(allocator, visible_langs, options);
    }
}

fn getColumnMajorPos(i: usize, total: usize, cols: usize) struct { col: usize, row: usize } {
    if (cols <= 1) return .{ .col = 0, .row = i };
    const base = total / cols;
    const rem = total % cols;

    var cur_idx: usize = 0;
    var c: usize = 0;
    while (c < cols) : (c += 1) {
        var count = base;
        if (c < rem) count += 1;
        if (i < cur_idx + count) {
            return .{ .col = c, .row = i - cur_idx };
        }
        cur_idx += count;
    }
    return .{ .col = cols - 1, .row = 0 };
}

fn renderStandardLayout(allocator: std.mem.Allocator, langs: []const models.LanguageStat, opts: RenderOptions) ![]u8 {
    var width = opts.card_width;
    if (width < 300) width = 300 else if (width > 1200) width = 1200;

    const padding_x: i32 = 25;
    const padding_y: i32 = 28;

    const raw_title = if (opts.custom_title) |t| (if (t.len > 0) t else "Most Used Languages") else "Most Used Languages";
    const escaped_title = try escapeXml(allocator, raw_title);
    defer allocator.free(escaped_title);

    var cols: usize = opts.columns;
    if (cols == 0) {
        if (langs.len <= 4) {
            cols = 1;
        } else if (langs.len > 10 and width >= 550) {
            cols = 3;
        } else {
            cols = 2;
        }
    }
    if (cols < 1) cols = 1;
    if (cols > 3) cols = 3;

    var rows = (langs.len + cols - 1) / cols;
    if (rows < 1) rows = 1;

    const bar_y: i32 = if (opts.hide_title) 28 else 52;
    const bar_height: i32 = 10;
    const bar_width: i32 = @as(i32, @intCast(width)) - (padding_x * 2);

    var row_height: i32 = 26;
    var list_start_y: i32 = bar_y + bar_height + 22;
    const min_required_height: i32 = list_start_y + (@as(i32, @intCast(rows)) * row_height) + 16;
    var height: i32 = min_required_height;

    if (opts.card_height > 0) {
        height = @intCast(opts.card_height);
        if (height < min_required_height) height = min_required_height;
        if (height > 1500) height = 1500;

        const target_bottom_margin: i32 = padding_y + 7;
        const last_row_y = height - target_bottom_margin;

        var intervals: i32 = @as(i32, @intCast(rows)) - 1;
        if (intervals < 1) intervals = 1;

        const bar_bottom = bar_y + bar_height;
        const avail_middle = last_row_y - bar_bottom;

        const total_slots = intervals + 1;
        var unit_spacing = @divTrunc(avail_middle, total_slots);
        if (unit_spacing > 80) {
            unit_spacing = 80;
        } else if (unit_spacing < 26) {
            unit_spacing = 26;
        }

        row_height = unit_spacing;
        var bar_to_list = avail_middle - (intervals * row_height);
        if (bar_to_list < 35) {
            bar_to_list = 35;
            if (intervals > 0) {
                row_height = @divTrunc(avail_middle - bar_to_list, intervals);
            }
        }
        list_start_y = bar_bottom + bar_to_list;
    }

    var stream = std.Io.Writer.Allocating.init(allocator);
    defer stream.deinit();

    // SVG Header
    try stream.writer.print(
        \\<svg width="{d}" height="{d}" viewBox="0 0 {d} {d}" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="{s}">
    , .{ width, height, width, height, escaped_title });

    // Styles
    try stream.writer.print(
        \\<style>
        \\        .card-title {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 16px; font-weight: 600; fill: {s}; }}
        \\        .lang-name {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 12.5px; font-weight: 500; fill: {s}; }}
        \\        .lang-pct {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 12px; font-weight: 400; fill: {s}; }}
        \\        .bar-bg {{ fill: {s}; rx: 5px; }}
        \\        .bar-segment {{ transition: all 0.3s ease; }}
        \\    
    , .{
        opts.theme.title_color,
        opts.theme.text_color,
        opts.theme.muted_color,
        opts.theme.bar_bg_color,
    });

    if (opts.animate) {
        try stream.writer.writeAll(
            \\
            \\        @keyframes fadeIn {
            \\            from { opacity: 0; transform: translateY(4px); }
            \\            to { opacity: 1; transform: translateY(0); }
            \\        }
            \\        @keyframes scaleBar {
            \\            from { transform: scaleX(0); }
            \\            to { transform: scaleX(1); }
            \\        }
            \\        .animate-item { animation: fadeIn 0.4s ease-out forwards; }
            \\        .bar-container { transform-origin: left; animation: scaleBar 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
            \\        
        );
    }
    try stream.writer.writeAll("</style>");

    // Background
    var stroke_buf: [128]u8 = undefined;
    const stroke_attr = if (opts.hide_border)
        "stroke=\"none\""
    else
        try std.fmt.bufPrint(&stroke_buf, "stroke=\"{s}\" stroke-width=\"1\"", .{opts.theme.border_color});

    try stream.writer.print(
        \\<rect width="{d}" height="{d}" rx="{d:.1}" fill="{s}" {s}/>
    , .{ width, height, opts.border_radius, opts.theme.bg_color, stroke_attr });

    // Title
    if (!opts.hide_title) {
        try stream.writer.print(
            \\<text x="{d}" y="{d}" class="card-title">{s}</text>
        , .{ padding_x, padding_y, escaped_title });
    }

    // Clip path & bar track
    const clip_id = "bar-clip";
    try stream.writer.print(
        \\
        \\    <defs>
        \\        <clipPath id="{s}">
        \\            <rect x="{d}" y="{d}" width="{d}" height="{d}" rx="5" ry="5"/>
        \\        </clipPath>
        \\    </defs>
        \\    <rect class="bar-bg" x="{d}" y="{d}" width="{d}" height="{d}" rx="5"/>
        \\<g clip-path="url(#{s})" class="bar-container">
    , .{ clip_id, padding_x, bar_y, bar_width, bar_height, padding_x, bar_y, bar_width, bar_height, clip_id });

    // Bar segments
    var current_x: f64 = @floatFromInt(padding_x);
    for (langs) |l| {
        var seg_width = (l.percentage / 100.0) * @as(f64, @floatFromInt(bar_width));
        if (seg_width < 1.0 and l.percentage > 0) {
            seg_width = 1.0;
        }
        const esc_name = try escapeXml(allocator, l.name);
        defer allocator.free(esc_name);

        try stream.writer.print(
            \\<rect x="{d:.2}" y="{d}" width="{d:.2}" height="{d}" fill="{s}" class="bar-segment"><title>{s}: {d:.2}%</title></rect>
        , .{ current_x, bar_y, seg_width, bar_height, l.color, esc_name, l.percentage });
        current_x += seg_width;
    }
    try stream.writer.writeAll("</g>");

    // Multi-column list
    const col_width = @as(f64, @floatFromInt(bar_width)) / @as(f64, @floatFromInt(cols));
    for (langs, 0..) |l, i| {
        const pos = getColumnMajorPos(i, langs.len, cols);
        const item_x = @as(f64, @floatFromInt(padding_x)) + (@as(f64, @floatFromInt(pos.col)) * col_width);
        const item_y = @as(f64, @floatFromInt(list_start_y)) + (@as(f64, @floatFromInt(pos.row)) * @as(f64, @floatFromInt(row_height)));

        var delay_buf: [64]u8 = undefined;
        const delay_style = if (opts.animate)
            try std.fmt.bufPrint(&delay_buf, " style=\"animation-delay: {d}ms;\"", .{100 + (i * 40)})
        else
            "";

        const dot_radius: f64 = 4.5;
        const dot_y = item_y - 4.5;
        const text_y = item_y;

        const esc_name = try escapeXml(allocator, l.name);
        defer allocator.free(esc_name);

        try stream.writer.print(
            \\<g class="animate-item"{s}>
            \\<circle cx="{d:.1}" cy="{d:.1}" r="{d:.1}" fill="{s}"/>
            \\<text x="{d:.1}" y="{d:.1}" class="lang-name">{s}</text>
        , .{ delay_style, item_x + 5.0, dot_y, dot_radius, l.color, item_x + 16.0, text_y, esc_name });

        var pct_x = item_x + col_width - 15.0;
        if (cols == 1) {
            pct_x = @floatFromInt(width - @as(u32, @intCast(padding_x)));
        }
        try stream.writer.print(
            \\<text x="{d:.1}" y="{d:.1}" text-anchor="end" class="lang-pct">{d:.2}%</text>
            \\</g>
        , .{ pct_x, text_y, l.percentage });
    }

    try stream.writer.writeAll("</svg>");
    return try stream.toOwnedSlice();
}

fn renderDonutLayout(allocator: std.mem.Allocator, langs: []const models.LanguageStat, opts: RenderOptions) ![]u8 {
    const width = opts.card_width;
    const padding_x: i32 = 25;
    const padding_y: i32 = 28;

    const raw_title = if (opts.custom_title) |t| (if (t.len > 0) t else "Most Used Languages") else "Most Used Languages";
    const escaped_title = try escapeXml(allocator, raw_title);
    defer allocator.free(escaped_title);

    const chart_center_x = @as(f64, @floatFromInt(width)) / 2.0;
    const chart_radius: f64 = 44.0;
    const chart_stroke: f64 = 12.0;
    const chart_center_y: f64 = if (opts.hide_title) 66.0 else 92.0;

    var cols = opts.columns;
    if (cols == 0) {
        if (langs.len <= 4) {
            cols = 2;
        } else if (width < 420) {
            cols = 2;
        } else {
            cols = 3;
        }
    }
    if (cols < 1) cols = 1;
    if (cols > 4) cols = 4;

    const row_height: i32 = 24;
    const grid_start_y: i32 = @as(i32, @intFromFloat(chart_center_y + chart_radius)) + 26;
    var rows = (langs.len + cols - 1) / cols;
    if (rows < 1) rows = 1;
    const height = grid_start_y + (@as(i32, @intCast(rows)) * row_height) + 16;

    var stream = std.Io.Writer.Allocating.init(allocator);
    defer stream.deinit();

    try stream.writer.print(
        \\<svg width="{d}" height="{d}" viewBox="0 0 {d} {d}" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="{s}">
    , .{ width, height, width, height, escaped_title });

    try stream.writer.print(
        \\<style>
        \\        .card-title {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 16px; font-weight: 600; fill: {s}; }}
        \\        .lang-name {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 12px; font-weight: 500; fill: {s}; }}
        \\        .lang-pct {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 11.5px; font-weight: 400; fill: {s}; }}
        \\        .donut-track {{ fill: none; stroke: {s}; stroke-width: {d:.1}; }}
        \\        .donut-segment {{ fill: none; stroke-width: {d:.1}; transition: stroke-dasharray 0.5s ease; }}
        \\    
    , .{
        opts.theme.title_color,
        opts.theme.text_color,
        opts.theme.muted_color,
        opts.theme.bar_bg_color,
        chart_stroke,
        chart_stroke,
    });

    if (opts.animate) {
        try stream.writer.writeAll(
            \\
            \\        @keyframes fadeIn {
            \\            from { opacity: 0; transform: translateY(4px); }
            \\            to { opacity: 1; transform: translateY(0); }
            \\        }
            \\        .animate-item { animation: fadeIn 0.4s ease-out forwards; }
            \\        
        );
    }
    try stream.writer.writeAll("</style>");

    var stroke_buf: [128]u8 = undefined;
    const stroke_attr = if (opts.hide_border)
        "stroke=\"none\""
    else
        try std.fmt.bufPrint(&stroke_buf, "stroke=\"{s}\" stroke-width=\"1\"", .{opts.theme.border_color});

    try stream.writer.print(
        \\<rect width="{d}" height="{d}" rx="{d:.1}" fill="{s}" {s}/>
    , .{ width, height, opts.border_radius, opts.theme.bg_color, stroke_attr });

    if (!opts.hide_title) {
        try stream.writer.print(
            \\<text x="{d}" y="{d}" class="card-title">{s}</text>
        , .{ padding_x, padding_y, escaped_title });
    }

    const circumference = 2.0 * std.math.pi * chart_radius;
    try stream.writer.print(
        \\<circle class="donut-track" cx="{d:.1}" cy="{d:.1}" r="{d:.1}"/>
    , .{ chart_center_x, chart_center_y, chart_radius });

    var accumulated_offset: f64 = 0.0;
    for (langs) |l| {
        const dash_length = (l.percentage / 100.0) * circumference;
        const esc_name = try escapeXml(allocator, l.name);
        defer allocator.free(esc_name);

        try stream.writer.print(
            \\
            \\        <circle class="donut-segment" cx="{d:.1}" cy="{d:.1}" r="{d:.1}" stroke="{s}"
            \\            stroke-dasharray="{d:.2} {d:.2}" stroke-dashoffset="{d:.2}"
            \\            transform="rotate(-90 {d:.1} {d:.1})">
            \\            <title>{s}: {d:.2}%</title>
            \\        </circle>
        , .{
            chart_center_x,
            chart_center_y,
            chart_radius,
            l.color,
            dash_length,
            circumference - dash_length,
            -accumulated_offset,
            chart_center_x,
            chart_center_y,
            esc_name,
            l.percentage,
        });
        accumulated_offset += dash_length;
    }

    try stream.writer.print(
        \\<text x="{d:.1}" y="{d:.1}" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="13" font-weight="700" fill="{s}">{d}</text>
        \\<text x="{d:.1}" y="{d:.1}" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="9.5" font-weight="500" fill="{s}">LANGS</text>
    , .{
        chart_center_x,
        chart_center_y - 1.0,
        opts.theme.title_color,
        langs.len,
        chart_center_x,
        chart_center_y + 12.0,
        opts.theme.muted_color,
    });

    const grid_width = @as(f64, @floatFromInt(width - (padding_x * 2)));
    const col_width = grid_width / @as(f64, @floatFromInt(cols));

    for (langs, 0..) |l, i| {
        const pos = getColumnMajorPos(i, langs.len, cols);
        const item_x = @as(f64, @floatFromInt(padding_x)) + (@as(f64, @floatFromInt(pos.col)) * col_width);
        const item_y = @as(f64, @floatFromInt(grid_start_y)) + (@as(f64, @floatFromInt(pos.row)) * @as(f64, @floatFromInt(row_height)));

        var delay_buf: [64]u8 = undefined;
        const delay_style = if (opts.animate)
            try std.fmt.bufPrint(&delay_buf, " style=\"animation-delay: {d}ms;\"", .{80 + (i * 35)})
        else
            "";

        const dot_radius: f64 = 4.0;
        const dot_y = item_y - 4.0;
        const text_y = item_y;

        const esc_name = try escapeXml(allocator, l.name);
        defer allocator.free(esc_name);

        try stream.writer.print(
            \\<g class="animate-item"{s}>
            \\<circle cx="{d:.1}" cy="{d:.1}" r="{d:.1}" fill="{s}"/>
            \\<text x="{d:.1}" y="{d:.1}" class="lang-name">{s}</text>
            \\<text x="{d:.1}" y="{d:.1}" text-anchor="end" class="lang-pct">{d:.1}%</text>
            \\</g>
        , .{ delay_style, item_x + 4.0, dot_y, dot_radius, l.color, item_x + 14.0, text_y, esc_name, item_x + col_width - 10.0, text_y, l.percentage });
    }

    try stream.writer.writeAll("</svg>");
    return try stream.toOwnedSlice();
}

fn renderCompactLayout(allocator: std.mem.Allocator, langs: []const models.LanguageStat, opts: RenderOptions) ![]u8 {
    const width = opts.card_width;
    const padding_x: i32 = 20;
    const bar_height: i32 = 8;
    const bar_y: i32 = if (opts.hide_title) 20 else 42;
    const bar_width: i32 = @as(i32, @intCast(width)) - (padding_x * 2);

    const raw_title = if (opts.custom_title) |t| (if (t.len > 0) t else "Most Used Languages") else "Most Used Languages";
    const escaped_title = try escapeXml(allocator, raw_title);
    defer allocator.free(escaped_title);

    const tag_y = bar_y + bar_height + 18;
    const height = tag_y + 24;

    var stream = std.Io.Writer.Allocating.init(allocator);
    defer stream.deinit();

    try stream.writer.print(
        \\<svg width="{d}" height="{d}" viewBox="0 0 {d} {d}" fill="none" xmlns="http://www.w3.org/2000/svg">
        \\<style>
        \\        .card-title {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 14px; font-weight: 600; fill: {s}; }}
        \\        .lang-name {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 11px; font-weight: 500; fill: {s}; }}
        \\        .bar-bg {{ fill: {s}; rx: 4px; }}
        \\    </style>
    , .{ width, height, width, height, opts.theme.title_color, opts.theme.text_color, opts.theme.bar_bg_color });

    var stroke_buf: [128]u8 = undefined;
    const stroke_attr = if (opts.hide_border)
        "stroke=\"none\""
    else
        try std.fmt.bufPrint(&stroke_buf, "stroke=\"{s}\" stroke-width=\"1\"", .{opts.theme.border_color});

    try stream.writer.print(
        \\<rect width="{d}" height="{d}" rx="{d:.1}" fill="{s}" {s}/>
    , .{ width, height, opts.border_radius, opts.theme.bg_color, stroke_attr });

    if (!opts.hide_title) {
        try stream.writer.print(
            \\<text x="{d}" y="24" class="card-title">{s}</text>
        , .{ padding_x, escaped_title });
    }

    const clip_id = "compact-bar-clip";
    try stream.writer.print(
        \\<rect class="bar-bg" x="{d}" y="{d}" width="{d}" height="{d}" rx="4"/>
        \\    <defs>
        \\        <clipPath id="{s}">
        \\            <rect x="{d}" y="{d}" width="{d}" height="{d}" rx="4"/>
        \\        </clipPath>
        \\    </defs>
        \\    <g clip-path="url(#{s})">
    , .{ padding_x, bar_y, bar_width, bar_height, clip_id, padding_x, bar_y, bar_width, bar_height, clip_id });

    var current_x: f64 = @floatFromInt(padding_x);
    for (langs) |l| {
        var seg_width = (l.percentage / 100.0) * @as(f64, @floatFromInt(bar_width));
        if (seg_width < 1.0 and l.percentage > 0) seg_width = 1.0;
        const esc_name = try escapeXml(allocator, l.name);
        defer allocator.free(esc_name);

        try stream.writer.print(
            \\<rect x="{d:.2}" y="{d}" width="{d:.2}" height="{d}" fill="{s}"><title>{s}: {d:.2}%</title></rect>
        , .{ current_x, bar_y, seg_width, bar_height, l.color, esc_name, l.percentage });
        current_x += seg_width;
    }
    try stream.writer.writeAll("</g>");

    var cur_tag_x: f64 = @floatFromInt(padding_x);
    for (langs) |l| {
        if (cur_tag_x + 60.0 > @as(f64, @floatFromInt(width - @as(u32, @intCast(padding_x))))) break;
        const esc_name = try escapeXml(allocator, l.name);
        defer allocator.free(esc_name);

        try stream.writer.print(
            \\<circle cx="{d:.1}" cy="{d:.1}" r="3.5" fill="{s}"/>
            \\<text x="{d:.1}" y="{d}" class="lang-name">{s} {d:.0}%</text>
        , .{ cur_tag_x + 4.0, @as(f64, @floatFromInt(tag_y)) - 3.5, l.color, cur_tag_x + 12.0, tag_y, esc_name, l.percentage });
        cur_tag_x += @as(f64, @floatFromInt(l.name.len * 7 + 45));
    }

    try stream.writer.writeAll("</svg>");
    return try stream.toOwnedSlice();
}
