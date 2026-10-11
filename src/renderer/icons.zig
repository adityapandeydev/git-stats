//! Optional Lucide SVG replacement. Legacy CLI output remains unchanged unless requested.
const std = @import("std");
const paths = @import("icon_paths.zig");

fn attribute(tag: []const u8, name: []const u8) ?[]const u8 {
    var buf: [64]u8 = undefined;
    const prefix = std.fmt.bufPrint(&buf, " {s}=\"", .{name}) catch return null;
    const start = (std.mem.indexOf(u8, tag, prefix) orelse return null) + prefix.len;
    const end = std.mem.indexOfScalarPos(u8, tag, start, '"') orelse return null;
    return tag[start..end];
}

pub fn replace(a: std.mem.Allocator, svg: []const u8, color: []const u8) ![]const u8 {
    var stream = std.Io.Writer.Allocating.init(a);
    const w = &stream.writer;
    var cursor: usize = 0;
    while (std.mem.indexOfPos(u8, svg, cursor, "<text ")) |start| {
        try w.writeAll(svg[cursor..start]);
        const open = std.mem.indexOfScalarPos(u8, svg, start, '>') orelse break;
        const end = std.mem.indexOfPos(u8, svg, open, "</text>") orelse break;
        const tag = svg[start..open];
        const text = svg[open + 1 .. end];
        var changed = false;
        for (paths.icons) |icon| {
            if (std.mem.indexOf(u8, text, icon.symbol)) |pos| {
                const clean = std.mem.trim(u8, try std.mem.concat(a, u8, &.{ text[0..pos], text[pos + icon.symbol.len ..] }), " ");
                const x = std.fmt.parseFloat(f64, attribute(tag, "x") orelse "0") catch 0;
                const y = std.fmt.parseFloat(f64, attribute(tag, "y") orelse "0") catch 0;
                const size_str = std.mem.trimEnd(u8, attribute(tag, "font-size") orelse "9", "px");
                const size = std.fmt.parseFloat(f64, size_str) catch 9;
                const anchor = attribute(tag, "text-anchor") orelse "start";
                const estimated_width = @as(f64, @floatFromInt(clean.len)) * size * 0.53;
                const left = if (std.mem.eql(u8, anchor, "middle")) x - (estimated_width + size + 3) / 2 else if (std.mem.eql(u8, anchor, "end")) x - estimated_width - size - 3 else x;
                try w.print("<svg x=\"{d:.1}\" y=\"{d:.1}\" width=\"{d:.1}\" height=\"{d:.1}\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"{s}\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\">{s}</svg>", .{ if (clean.len == 0) x - size / 2 else left, y - size + 1, size, size, attribute(tag, "fill") orelse color, icon.paths });
                if (clean.len > 0) {
                    const new_x = if (std.mem.eql(u8, anchor, "middle")) x + (size + 3) / 2 else if (std.mem.eql(u8, anchor, "end")) x else x + size + 3;
                    const x_prefix = std.mem.indexOf(u8, tag, " x=\"") orelse return error.MissingPosition;
                    const x_end = std.mem.indexOfScalarPos(u8, tag, x_prefix + 4, '"') orelse return error.MissingPosition;
                    try w.print("{s} x=\"{d:.1}\"{s}>{s}</text>", .{ tag[0..x_prefix], new_x, tag[x_end + 1 ..], clean });
                }
                changed = true;
                break;
            }
        }
        if (!changed) try w.writeAll(svg[start .. end + 7]);
        cursor = end + 7;
    }
    try w.writeAll(svg[cursor..]);
    return stream.toOwnedSlice();
}
