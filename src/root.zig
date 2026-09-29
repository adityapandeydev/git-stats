const std = @import("std");

pub const models = @import("github/models.zig");
pub const colors = @import("github/colors.zig");
pub const client = @import("github/client.zig");
pub const themes = @import("renderer/themes.zig");
pub const svg = @import("renderer/svg.zig");

test "colors: official Linguist mapping and fallback" {
    try std.testing.expectEqualStrings("#ec915c", colors.getLanguageColor("Zig", null));
    try std.testing.expectEqualStrings("#ec915c", colors.getLanguageColor("zig", null));
    try std.testing.expectEqualStrings("#3178c6", colors.getLanguageColor("TypeScript", null));
    try std.testing.expectEqualStrings("#00ADD8", colors.getLanguageColor("Go", null));
    try std.testing.expectEqualStrings("#ff0000", colors.getLanguageColor("UnknownLang", "#ff0000"));
    try std.testing.expectEqualStrings(colors.default_language_color, colors.getLanguageColor("UnknownLang", null));
}

test "client: token cleaning and masking" {
    try std.testing.expectEqualStrings("ghp_xyz", client.cleanToken("  Bearer ghp_xyz  "));
    try std.testing.expectEqualStrings("ghp_xyz", client.cleanToken("\"token ghp_xyz\""));
    try std.testing.expectEqualStrings("", client.cleanToken("true"));
    try std.testing.expectEqualStrings("", client.cleanToken("false"));

    const masked = try client.maskToken(std.testing.allocator, "ghp_1234567890abcdefghijklmnopqrstuvwxyz");
    defer std.testing.allocator.free(masked);
    try std.testing.expect(std.mem.startsWith(u8, masked, "ghp_..."));
    try std.testing.expect(std.mem.endsWith(u8, masked, " (len: 40)"));
}

test "themes: preset selection and overrides" {
    const t = themes.getTheme("tokyonight");
    try std.testing.expectEqualStrings("#1a1b27", t.bg_color);
    try std.testing.expectEqualStrings("#70a5fd", t.title_color);
    try std.testing.expect(t.border_radius == 4.5);

    const overridden = themes.applyThemeOverrides(t, "#000000", null, null, null, null, 10.0);
    try std.testing.expectEqualStrings("#000000", overridden.bg_color);
    try std.testing.expectEqualStrings("#70a5fd", overridden.title_color);
    try std.testing.expect(overridden.border_radius == 10.0);
}

test "svg: layout rendering produces valid svg" {
    const allocator = std.testing.allocator;

    var langs = [_]models.LanguageStat{
        .{ .name = "Zig", .color = "#ec915c", .size = 1000, .percentage = 50.0 },
        .{ .name = "Go", .color = "#00ADD8", .size = 1000, .percentage = 50.0 },
    };

    const user_stats = models.UserStats{
        .username = "testuser",
        .total_bytes = 2000,
        .languages = &langs,
    };

    const rendered = try svg.renderSVG(allocator, &user_stats, .{
        .card_width = 400,
        .card_height = 368,
        .langs_count = 2,
        .border_radius = 4.5,
    });
    defer allocator.free(rendered);

    try std.testing.expect(std.mem.startsWith(u8, rendered, "<svg width=\"400\" height=\"368\""));
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Zig") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Go") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "50.00%") != null);
    try std.testing.expect(std.mem.endsWith(u8, rendered, "</svg>"));
}
