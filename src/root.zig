const std = @import("std");

pub const models = @import("github/models.zig");
pub const colors = @import("github/colors.zig");
pub const client = @import("github/client.zig");
pub const themes = @import("renderer/themes.zig");
pub const svg = @import("renderer/svg.zig");
pub const streak = @import("renderer/streak.zig");
pub const stats = @import("renderer/stats.zig");
pub const rhythm = @import("renderer/rhythm.zig");

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

test "streak: renderStreakSVG produces valid reimagined card with sparkline and flame core" {
    const allocator = std.testing.allocator;

    const streak_stats = models.StreakStats{
        .username = "adityapandeydev",
        .total_contributions = 2026,
        .first_contribution_date = "Oct 7, 2022",
        .latest_contribution_date = "Present",
        .current_streak = 551,
        .current_streak_start = "Mar 28, 2025",
        .current_streak_end = "Sep 29",
        .is_streak_active = true,
        .longest_streak = 551,
        .longest_streak_start = "Mar 28, 2025",
        .longest_streak_end = "Sep 29",
        .recent_14_days = [_]u32{ 4, 7, 2, 8, 12, 5, 9, 3, 6, 11, 8, 4, 7, 10 },
        .max_14_day_count = 12,
        .total_14_day_count = 96,
    };

    const t = themes.getTheme("tokyonight");
    const rendered = try streak.renderStreakSVG(allocator, &streak_stats, .{
        .theme = t,
        .card_width = 424,
        .card_height = 180,
        .border_radius = 4.5,
    });
    defer allocator.free(rendered);

    try std.testing.expect(std.mem.indexOf(u8, rendered, "<svg xmlns=\"http://www.w3.org/2000/svg\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "width=\"424\" height=\"180\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Total Contributions") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "2026") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "551") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Longest Streak") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "14-DAY ACTIVITY MOMENTUM") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "96 COMMITS") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "</svg>") != null);

    // Test with show_sparkline = false
    const rendered_no_spark = try streak.renderStreakSVG(allocator, &streak_stats, .{
        .theme = t,
        .card_width = 424,
        .card_height = 180,
        .border_radius = 4.5,
        .show_sparkline = false,
    });
    defer allocator.free(rendered_no_spark);

    try std.testing.expect(std.mem.indexOf(u8, rendered_no_spark, "14-DAY ACTIVITY MOMENTUM") == null);
    try std.testing.expect(std.mem.indexOf(u8, rendered_no_spark, "96 COMMITS") == null);
    try std.testing.expect(std.mem.indexOf(u8, rendered_no_spark, "Total Contributions") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered_no_spark, "</svg>") != null);
}

test "rating: calculateDeveloperRating correctly computes scores and tiers" {
    // High-impact engineer
    const mythic = models.calculateDeveloperRating(2500, 40, 38, 30, 100, 25);
    try std.testing.expect(mythic.score >= 880);
    try std.testing.expectEqualStrings("S+", mythic.tier);
    try std.testing.expectEqualStrings("Mythic Architect", mythic.title);

    // Active contributor
    const active = models.calculateDeveloperRating(300, 10, 8, 4, 15, 6);
    try std.testing.expect(active.score >= 350 and active.score < 600);
    try std.testing.expect(active.progress > 0.35 and active.progress < 0.60);

    // Beginner
    const beginner = models.calculateDeveloperRating(15, 0, 0, 0, 0, 1);
    try std.testing.expect(beginner.score < 280);
    try std.testing.expectEqualStrings("C", beginner.tier);
}

test "stats: renderStatsSVG produces valid reimagined card with radial rating ring" {
    const allocator = std.testing.allocator;

    const rating = models.calculateDeveloperRating(2030, 32, 28, 16, 48, 18);
    const overall = models.OverallStats{
        .username = "adityapandeydev",
        .name = "Aditya Pandey",
        .timeframe = "all-time",
        .total_commits = 2030,
        .total_prs = 32,
        .merged_prs = 28,
        .total_issues = 22,
        .closed_issues = 16,
        .total_stars = 48,
        .contributed_repos = 18,
        .rating = rating,
    };

    const t = themes.getTheme("tokyonight");
    const rendered = try stats.renderStatsSVG(allocator, &overall, .{
        .theme = t,
        .card_width = 424,
        .card_height = 180,
        .border_radius = 4.5,
    });
    defer allocator.free(rendered);

    try std.testing.expect(std.mem.indexOf(u8, rendered, "<svg xmlns=\"http://www.w3.org/2000/svg\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "width=\"424\" height=\"180\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "DEVELOPER STATS") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "2,030") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "COMMITS") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "MERGED PRS") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "TOTAL STARS") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "REPOSITORIES") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "tier-badge-txt") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "</svg>") != null);
}

test "rhythm: renderRhythmSVG produces valid circadian punchcard matrix" {
    const allocator = std.testing.allocator;

    var matrix: [7][24]u32 = [_][24]u32{[_]u32{0} ** 24} ** 7;
    matrix[0][22] = 14;
    matrix[1][23] = 18;
    matrix[2][0] = 12;

    const rhythm_stats = models.CommitRhythm{
        .username = "adityapandeydev",
        .matrix = matrix,
        .total_commits = 240,
        .night_commits = 150,
        .day_commits = 90,
        .weekend_commits = 30,
        .peak_hour = 23,
        .peak_day = 1,
        .peak_count = 18,
        .persona_title = "Night Owl",
        .persona_icon = "🌙",
        .persona_color = "#bb9af7",
        .peak_window_str = "21:00 – 01:00",
    };

    const t = themes.getTheme("tokyonight");
    const rendered = try rhythm.renderRhythmSVG(allocator, &rhythm_stats, .{
        .theme = t,
        .card_width = 424,
        .card_height = 180,
        .border_radius = 4.5,
    });
    defer allocator.free(rendered);

    try std.testing.expect(std.mem.indexOf(u8, rendered, "<svg xmlns=\"http://www.w3.org/2000/svg\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "width=\"424\" height=\"180\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "COMMIT RHYTHM") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "24H × 7D MATRIX") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "PEAK WINDOW") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "21:00 – 01:00") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "CIRCADIAN SPLIT") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Night Owl") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "</svg>") != null);
}



