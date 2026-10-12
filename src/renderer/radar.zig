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
pub const chart_x: f64 = 97;
pub const chart_y: f64 = 102;
pub const chart_radius: f64 = 49;
pub const label_gap: f64 = 8;
pub fn vertex(i: usize, scale: f64) [2]f64 {
    const angle = (-90 + @as(f64, @floatFromInt(i)) * 72) * std.math.pi / 180;
    return .{ chart_x + @cos(angle) * chart_radius * scale, chart_y + @sin(angle) * chart_radius * scale };
}
// Position each label's near edge exactly label_gap from its outer vertex.
// The anchor faces away from the polygon; text length never moves it inward.
pub fn labelPosition(i: usize) [2]f64 {
    const v = vertex(i, 1);
    return .{ v[0] + (if (i == 0) @as(f64, 0) else if (i < 3) label_gap else -label_gap), v[1] + (if (i == 0) -label_gap else 0) };
}
pub fn renderRadarSVG(a: std.mem.Allocator, dna: *const models.DeveloperDNA, opts: RadarRenderOptions) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(a);
    defer stream.deinit();
    const w = &stream.writer;
    const width = try c.begin(w, opts, "Developer DNA", "5-AXIS POLYGLOT RADAR. Language share in Systems, Backend, Frontend, DevOps, and Data & AI.");
    var scope_buf: [64]u8 = undefined;
    try c.header(w, width, "DEVELOPER DNA", try std.fmt.bufPrint(&scope_buf, "{d} LANGUAGES", .{dna.total_languages}), opts.theme, opts.hide_title);
    const values = [_]f64{ dna.systems_pct, dna.backend_pct, dna.frontend_pct, dna.devops_pct, dna.data_pct };
    const names = [_][]const u8{ "Systems", "Backend", "Frontend", "DevOps", "Data & AI" };
    const colors = [_][]const u8{ opts.theme.title_color, c.mint, c.violet, c.gold, c.pink };
    for ([_]f64{ 0.25, 0.5, 0.75, 1 }) |s| {
        try w.writeAll("<polygon points=\"");
        for (0..5) |i| {
            const v = vertex(i, s);
            try w.print("{d:.2},{d:.2} ", .{ v[0], v[1] });
        }
        try w.print("\" fill=\"none\" stroke=\"{s}\"/>", .{opts.theme.border_color});
    }
    for (0..5) |i| {
        const v = vertex(i, 1);
        try w.print("<path d=\"M{d} {d}L{d:.2} {d:.2}\" stroke=\"{s}\"/>", .{ chart_x, chart_y, v[0], v[1], opts.theme.border_color });
    }
    try w.writeAll("<polygon class=\"dna-shape\" points=\"");
    for (values, 0..) |p, i| {
        const v = vertex(i, c.fraction(p / 100));
        try w.print("{d:.2},{d:.2} ", .{ v[0], v[1] });
    }
    try w.print("\" fill=\"{s}\" fill-opacity=\"0.18\" stroke=\"{s}\" stroke-width=\"1.6\"/>", .{ opts.theme.title_color, opts.theme.title_color });
    for (values, 0..) |p, i| {
        const v = vertex(i, c.fraction(p / 100));
        try w.print("<circle cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"2.3\" fill=\"{s}\"/>", .{ v[0], v[1], colors[i] });
        const pos = labelPosition(i);
        // Text uses an explicit middle baseline, so side labels have the same
        // 8px edge gap. The top label's bottom edge is 8px above its vertex.
        try w.print("<text class=\"dna-axis\" x=\"{d:.2}\" y=\"{d:.2}\" text-anchor=\"{s}\" dominant-baseline=\"{s}\" font-size=\"8\" font-weight=\"600\" fill=\"{s}\">", .{ pos[0], pos[1], if (i == 0) "middle" else if (i < 3) "start" else "end", if (i == 0) "text-after-edge" else "central", colors[i] });
        try c.escape(w, names[i]);
        try w.writeAll("</text>");
    }
    try c.text(w, 196, 49, dna.archetype, 15, opts.theme.text_color, 650, "start", width - 214);
    for (values, 0..) |p, i| {
        const y = 70 + @as(f64, @floatFromInt(i)) * 20;
        try c.text(w, 196, y, names[i], 9, opts.theme.muted_color, 500, "start", 65);
        try c.fmt(w, width - 18, y, "{d:.0}%", .{c.fraction(p / 100) * 100}, 10, colors[i], 650, "end", 34);
        try c.bar(w, 268, y - 5, width - 324, p / 100, colors[i], opts.theme);
    }
    try c.text(w, 18, 171, "Language share by domain", 8, opts.theme.muted_color, 500, "start", 170);
    try c.fmt(w, width - 18, 171, "{d} Languages Mapped", .{dna.total_languages}, 8, opts.theme.muted_color, 500, "end", 160);
    try c.end(w);
    return stream.toOwnedSlice();
}
