//! Shared primitives for the compact profile cards. Coordinates use a 180px
//! design height; smaller custom cards fit uniformly without clipping text.
const std = @import("std");
const themes = @import("themes.zig");
const assets = @import("card_icons.zig");
pub const mint = "#73daca";
pub const violet = "#bb9af7";
pub const gold = "#e0af68";
pub const pink = "#f7768e";
pub const Writer = std.Io.Writer;
pub fn fraction(value: f64) f64 {
    return if (std.math.isFinite(value)) std.math.clamp(value, 0, 1) else 0;
}
pub fn escape(w: *Writer, value: []const u8) !void {
    for (value) |ch| switch (ch) {
        '&' => try w.writeAll("&amp;"),
        '<' => try w.writeAll("&lt;"),
        '>' => try w.writeAll("&gt;"),
        '"' => try w.writeAll("&quot;"),
        '\'' => try w.writeAll("&#39;"),
        else => try w.writeByte(ch),
    };
}
pub fn begin(w: *Writer, opts: anytype, title: []const u8, description: []const u8) !f64 {
    const actual_width: u32 = if (opts.card_width == 0) 424 else opts.card_width;
    const actual_height: u32 = if (opts.card_height == 0) 180 else opts.card_height;
    const width: f64 = @floatFromInt(actual_width);
    const height: f64 = @floatFromInt(actual_height);
    const scale = @min(width / 424, height / 180);
    const logical_w = width / scale;
    const radius = if (std.math.isFinite(opts.border_radius)) @max(0, opts.border_radius) else 4.5;
    try w.print("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 {d} {d}\" width=\"{d}\" height=\"{d}\" role=\"img\"><title>", .{ actual_width, actual_height, actual_width, actual_height });
    try escape(w, title);
    try w.writeAll("</title><desc>");
    try escape(w, description);
    try w.writeAll("</desc>");
    try w.print("<rect width=\"{d}\" height=\"{d}\" rx=\"{d:.1}\" fill=\"{s}\" stroke=\"{s}\" stroke-width=\"{d}\"/><g transform=\"translate(0 {d:.3}) scale({d:.5})\" font-family=\"-apple-system,BlinkMacSystemFont,'Segoe UI',Arial,sans-serif\">", .{ actual_width, actual_height, radius, opts.theme.bg_color, opts.theme.border_color, @as(u8, if (opts.hide_border) 0 else 1), (height - 180 * scale) / 2, scale });
    if (opts.animate) try w.writeAll("<style>@keyframes cardReveal{from{opacity:0}to{opacity:1}}.card-content{animation:cardReveal .45s ease-out}@media(prefers-reduced-motion:reduce){.card-content{animation:none}}</style>");
    try w.writeAll("<g class=\"card-content\">");
    return logical_w;
}
pub fn end(w: *Writer) !void {
    try w.writeAll("</g></g></svg>");
}
pub fn text(w: *Writer, x: f64, y: f64, value: []const u8, size: f64, color: []const u8, weight: u16, anchor: []const u8, max_width: f64) !void {
    const count = std.unicode.utf8CountCodepoints(value) catch value.len;
    const fitted = @min(size, max_width / @max(1, @as(f64, @floatFromInt(count))) / 0.60);
    try w.print("<text x=\"{d:.2}\" y=\"{d:.2}\" font-size=\"{d:.2}\" fill=\"{s}\" font-weight=\"{d}\" text-anchor=\"{s}\">", .{ x, y, fitted, color, weight, anchor });
    try escape(w, value);
    try w.writeAll("</text>");
}
pub fn fmt(w: *Writer, x: f64, y: f64, comptime pattern: []const u8, args: anytype, size: f64, color: []const u8, weight: u16, anchor: []const u8, max_width: f64) !void {
    var buf: [256]u8 = undefined;
    try text(w, x, y, try std.fmt.bufPrint(&buf, pattern, args), size, color, weight, anchor, max_width);
}
pub fn rect(w: *Writer, x: f64, y: f64, width: f64, height: f64, radius: f64, color: []const u8, opacity: f64) !void {
    try w.print("<rect x=\"{d:.2}\" y=\"{d:.2}\" width=\"{d:.2}\" height=\"{d:.2}\" rx=\"{d:.1}\" fill=\"{s}\" fill-opacity=\"{d:.3}\"/>", .{ x, y, @max(0, width), @max(0, height), radius, color, fraction(opacity) });
}
pub fn rule(w: *Writer, x: f64, y: f64, width: f64, theme: themes.Theme) !void {
    try rect(w, x, y, width, 1, 0, theme.border_color, 1);
}
pub fn bar(w: *Writer, x: f64, y: f64, width: f64, progress: f64, color: []const u8, theme: themes.Theme) !void {
    try rect(w, x, y, width, 3, 1.5, theme.border_color, 1);
    try rect(w, x, y, width * fraction(progress), 3, 1.5, color, 1);
}
pub fn pill(w: *Writer, x: f64, y: f64, width: f64, value: []const u8, color: []const u8) !void {
    try w.print("<rect x=\"{d:.1}\" y=\"{d:.1}\" width=\"{d:.1}\" height=\"20\" rx=\"10\" fill=\"{s}\" fill-opacity=\".09\" stroke=\"{s}\" stroke-opacity=\".28\"/>", .{ x, y, width, color, color });
    try text(w, x + width / 2, y + 13, value, 9, color, 600, "middle", width - 12);
}
pub fn header(w: *Writer, width: f64, title: []const u8, scope: []const u8, theme: themes.Theme, hide: bool) !void {
    if (hide) return;
    try text(w, 18, 25, title, 11, theme.title_color, 700, "start", width * 0.58);
    try text(w, width - 18, 25, scope, 9, theme.muted_color, 500, "end", width * 0.36);
}
pub fn icon(w: *Writer, name: assets.Icon, x: f64, y: f64, size: f64, color: []const u8) !void {
    try w.print("<svg x=\"{d:.1}\" y=\"{d:.1}\" width=\"{d:.1}\" height=\"{d:.1}\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"{s}\" color=\"{s}\" stroke-width=\"1.6\" stroke-linecap=\"round\" stroke-linejoin=\"round\">{s}</svg>", .{ x, y, size, size, color, color, assets.paths(name) });
}
pub fn compact(a: std.mem.Allocator, n: u64) ![]const u8 {
    if (n >= 1_000_000_000) return std.fmt.allocPrint(a, "{d:.1}B", .{@as(f64, @floatFromInt(n)) / 1_000_000_000});
    if (n >= 1_000_000) return std.fmt.allocPrint(a, "{d:.1}M", .{@as(f64, @floatFromInt(n)) / 1_000_000});
    if (n >= 1000) return std.fmt.allocPrint(a, "{d:.1}k", .{@as(f64, @floatFromInt(n)) / 1000});
    return std.fmt.allocPrint(a, "{d}", .{n});
}
