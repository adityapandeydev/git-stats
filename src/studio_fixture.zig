//! Native fixture runner for browser parity checks. Separate from the production CLI.
const std = @import("std");
const studio = @import("studio.zig");
pub fn main(init: std.process.Init) !void {
    const a = init.arena.allocator();
    const args = try init.minimal.args.toSlice(a);
    if (args.len != 3) return error.ExpectedInputAndOutputPaths;
    const cwd = std.Io.Dir.cwd();
    const bytes = try cwd.readFileAlloc(init.io, args[1], a, .limited(2 * 1024 * 1024));
    const parsed = try std.json.parseFromSlice(studio.Request, a, bytes, .{ .ignore_unknown_fields = true });
    const svg = try studio.render(a, parsed.value);
    const result = try @import("renderer/icons.zig").replace(a, svg, @import("renderer/themes.zig").getTheme(parsed.value.theme).title_color);
    try cwd.writeFile(init.io, .{ .sub_path = args[2], .data = result });
}
