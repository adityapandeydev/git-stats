const std = @import("std");
const models = @import("../github/models.zig");
const themes = @import("themes.zig");
const c = @import("card.zig");
pub const RadarRenderOptions = struct {
    theme: themes.Theme,
    card_width: u32 = 424,
    card_height: u32 = 180,
    border_radius: f64 = 4.5,
    hide_border: bool = false,
    hide_title: bool = false,
    animate: bool = true,
};
pub const chart_x: f64 = 104;
pub const chart_y: f64 = 104;
pub const chart_radius: f64 = 44;
pub const label_gap: f64 = 8;
pub const names = [_][]const u8{ "Systems", "Backend", "Frontend", "DevOps", "Data & AI" };
const axis_names = [_][]const u8{ "Systems", "Backend", "Frontend", "DevOps", "Data" };

/// Axis i starts at the top and runs clockwise in 72° steps.
pub fn vertex(i: usize, scale: f64) [2]f64 {
    const angle = (-90 + @as(f64, @floatFromInt(i)) * 72) * std.math.pi / 180;
    return .{ chart_x + @cos(angle) * chart_radius * scale, chart_y + @sin(angle) * chart_radius * scale };
}

/// Radius fraction for a domain share. Shares always add up to 100%, so an
/// absolute 0–100 scale would keep the shape inside the inner ring. The
/// strongest domain reaches the outer ring instead; rings are 25/50/75/100%
/// of it, and the exact shares are listed beside the chart.
pub fn radiusFraction(value: f64, max_value: f64) f64 {
    if (!(max_value > 0)) return 0;
    return c.fraction(value / max_value);
}

/// Axis label anchor: label_gap outside the outer vertex, facing away from the chart.
pub fn labelPosition(i: usize) [2]f64 {
    const v = vertex(i, 1);
    return switch (i) {
        0 => .{ v[0], v[1] - label_gap },
        1 => .{ v[0] + label_gap, v[1] },
        4 => .{ v[0] - label_gap, v[1] },
        else => .{ v[0], v[1] + label_gap },
    };
}

pub fn renderRadarSVG(a: std.mem.Allocator, dna: *const models.DeveloperDNA, opts: RadarRenderOptions) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(a);
    defer stream.deinit();
    const w = &stream.writer;
    const t = opts.theme;
    const p = c.palette(t);
    const values = [_]f64{ dna.systems_pct, dna.backend_pct, dna.frontend_pct, dna.devops_pct, dna.data_pct };
    var desc_buf: [256]u8 = undefined;
    const desc = try std.fmt.bufPrint(&desc_buf, "Share of code by domain: Systems {d:.0}%, Backend {d:.0}%, Frontend {d:.0}%, DevOps {d:.0}%, Data and AI {d:.0}%.", .{ values[0], values[1], values[2], values[3], values[4] });
    const width = try c.begin(w, opts, "Developer DNA", desc);
    var meta_buf: [48]u8 = undefined;
    const meta = try std.fmt.bufPrint(&meta_buf, "{d} {s}", .{ dna.total_languages, if (dna.total_languages == 1) "language" else "languages" });
    try c.heading(w, width, "Developer DNA", meta, t, opts.hide_title);
    const colors = [_][]const u8{ t.title_color, p.mint, p.violet, p.gold, p.pink };

    var max_value: f64 = 0;
    var top: usize = 0;
    for (values, 0..) |v, i| if (v > max_value) {
        max_value = v;
        top = i;
    };

    for ([_]f64{ 0.25, 0.5, 0.75, 1 }) |s| {
        try w.writeAll("<polygon points=\"");
        for (0..5) |i| {
            const v = vertex(i, s);
            try w.print("{d:.2},{d:.2} ", .{ v[0], v[1] });
        }
        try w.print("\" fill=\"none\" stroke=\"{s}\"/>", .{t.border_color});
    }
    for (0..5) |i| {
        const v = vertex(i, 1);
        try w.print("<line x1=\"{d}\" y1=\"{d}\" x2=\"{d:.2}\" y2=\"{d:.2}\" stroke=\"{s}\"/>", .{ chart_x, chart_y, v[0], v[1], t.border_color });
    }
    if (max_value > 0) {
        try w.writeAll("<polygon class=\"dna-shape\" points=\"");
        for (values, 0..) |v, i| {
            const pt = vertex(i, radiusFraction(v, max_value));
            try w.print("{d:.2},{d:.2} ", .{ pt[0], pt[1] });
        }
        try w.print("\" fill=\"{s}\" fill-opacity=\".2\" stroke=\"{s}\" stroke-width=\"1.6\" stroke-linejoin=\"round\"/>", .{ t.title_color, t.title_color });
        for (values, 0..) |v, i| {
            const pt = vertex(i, radiusFraction(v, max_value));
            try w.print("<circle cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"2.6\" fill=\"{s}\"/>", .{ pt[0], pt[1], colors[i] });
        }
    }
    for (0..5) |i| {
        const pos = labelPosition(i);
        // Bottom labels hang below their vertex; side labels are vertically centred.
        const anchor = switch (i) {
            1 => "start",
            4 => "end",
            else => "middle",
        };
        const dy: f64 = switch (i) {
            0 => 0,
            2, 3 => 8,
            else => 3.5,
        };
        try c.text(w, pos[0], pos[1] + dy, axis_names[i], 10, colors[i], 600, anchor, 60);
    }

    const x0: f64 = 222;
    if (max_value > 0) {
        try c.text(w, x0, 58, dna.archetype, 15, t.text_color, 650, "start", width - c.pad - x0);
        var sub_buf: [64]u8 = undefined;
        const sub = if (std.mem.eql(u8, dna.top_domain_name, "Polyglot")) "Balanced across domains" else try std.fmt.bufPrint(&sub_buf, "Strongest in {s}", .{names[top]});
        try c.text(w, x0, 74, sub, 11, t.muted_color, 500, "start", width - c.pad - x0);
    } else {
        try c.text(w, x0, 58, "No language data yet", 13, t.text_color, 600, "start", width - c.pad - x0);
    }
    const bar_x = x0 + 62;
    const bar_w = width - c.pad - 35 - bar_x;
    for (values, 0..) |v, i| {
        const y = 96 + @as(f64, @floatFromInt(i)) * 16;
        try c.text(w, x0, y, names[i], 11, t.muted_color, 500, "start", 60);
        try c.meter(w, bar_x, y - 6, bar_w, radiusFraction(v, max_value), colors[i], t, 5);
        try c.fmt(w, width - c.pad, y, "{d:.0}%", .{c.fraction(v / 100) * 100}, 11, t.text_color, 600, "end", 34);
    }
    try c.end(w);
    return stream.toOwnedSlice();
}
