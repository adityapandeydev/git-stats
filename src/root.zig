const std = @import("std");

pub const models = @import("github/models.zig");
pub const colors = @import("github/colors.zig");
pub const client = @import("github/client.zig");
pub const themes = @import("renderer/themes.zig");
pub const svg = @import("renderer/svg.zig");
pub const streak = @import("renderer/streak.zig");
pub const stats = @import("renderer/stats.zig");
pub const rhythm = @import("renderer/rhythm.zig");
pub const radar = @import("renderer/radar.zig");
pub const velocity = @import("renderer/velocity.zig");
pub const milestones = @import("renderer/milestones.zig");
pub const bento = @import("renderer/bento.zig");
pub const icons = @import("renderer/icons.zig");

test "stats score ring is exact at zero, three quarters, and full score" {
    const a = std.testing.allocator;
    var data = models.OverallStats{ .username = "test", .name = "test", .total_commits = 0, .total_prs = 0, .merged_prs = 0, .total_issues = 0, .closed_issues = 0, .total_stars = 0, .contributed_repos = 0, .rating = models.calculateDeveloperRating(0, 0, 0, 0, 0, 0) };
    for ([_]u32{ 0, 750, 1000, 1200 }, [_][]const u8{ "100.000", "25.000", "0.000", "0.000" }) |score, offset| {
        data.rating.score = score;
        // The renderer must use score/1000, not an inconsistent stale progress.
        data.rating.progress = 0.9;
        const rendered = try stats.renderStatsSVG(a, &data, .{ .theme = themes.tokyonight, .animate = false });
        defer a.free(rendered);
        const expected = try std.fmt.allocPrint(a, "stroke-dashoffset=\"{s}\"", .{offset});
        defer a.free(expected);
        try std.testing.expect(std.mem.indexOf(u8, rendered, expected) != null);
        try std.testing.expect(std.mem.indexOf(u8, rendered, "pathLength=\"100\"") != null);
    }
}

test "DNA labels share one fixed gap from the outer vertices" {
    for (0..5) |i| {
        const v = radar.vertex(i, 1);
        const p = radar.labelPosition(i);
        const distance = @sqrt((p[0] - v[0]) * (p[0] - v[0]) + (p[1] - v[1]) * (p[1] - v[1]));
        try std.testing.expectApproxEqAbs(radar.label_gap, distance, 0.0001);
    }
}

test "DNA radius is relative to the strongest domain" {
    try std.testing.expectEqual(@as(f64, 1), radar.radiusFraction(37, 37));
    try std.testing.expectApproxEqAbs(@as(f64, 28.0 / 37.0), radar.radiusFraction(28, 37), 1e-9);
    try std.testing.expectEqual(@as(f64, 0), radar.radiusFraction(0, 0));
    // Vertex distance from the centre equals fraction x radius on every axis.
    for (0..5) |i| {
        const v = radar.vertex(i, 0.5);
        const d = @sqrt((v[0] - radar.chart_x) * (v[0] - radar.chart_x) + (v[1] - radar.chart_y) * (v[1] - radar.chart_y));
        try std.testing.expectApproxEqAbs(radar.chart_radius * 0.5, d, 1e-9);
    }
}

test "DNA honours hidden languages and splits multi-domain languages" {
    const a = std.testing.allocator;
    const langs = [_]models.LanguageStat{
        .{ .name = "Rust", .color = "#dea584", .size = 600, .percentage = 0 },
        .{ .name = "Python", .color = "#3572A5", .size = 200, .percentage = 0 },
        .{ .name = "Jupyter Notebook", .color = "#DA5B0B", .size = 5000, .percentage = 0 },
        .{ .name = "TeX", .color = "#3D6117", .size = 900, .percentage = 0 },
    };
    const visible = try models.filterHiddenLanguages(a, &langs, " jupyter notebook ,html");
    defer a.free(visible);
    try std.testing.expectEqual(@as(usize, 3), visible.len);
    const dna = models.calculateDeveloperDNA("t", visible);
    // TeX is ignored; Python splits half backend, half data.
    try std.testing.expectApproxEqAbs(@as(f64, 75), dna.systems_pct, 1e-9);
    try std.testing.expectApproxEqAbs(@as(f64, 12.5), dna.backend_pct, 1e-9);
    try std.testing.expectApproxEqAbs(@as(f64, 12.5), dna.data_pct, 1e-9);
    try std.testing.expectEqual(@as(usize, 2), dna.total_languages);
    try std.testing.expectEqualStrings("Systems Engineer", dna.archetype);
}

test "rating breakdown always adds up to the score" {
    const cases = [_][6]u64{ .{ 2764, 113, 110, 6, 1, 44 }, .{ 0, 0, 0, 0, 0, 0 }, .{ 15, 0, 0, 0, 0, 1 }, .{ 99999, 500, 480, 300, 9000, 80 } };
    for (cases) |k| {
        const r = models.calculateDeveloperRating(k[0], k[1], k[2], k[3], k[4], k[5]);
        try std.testing.expectEqual(r.score, r.commits_pts + r.prs_pts + r.collab_pts + r.impact_pts);
        try std.testing.expect(r.commits_pts <= 350 and r.prs_pts <= 300 and r.collab_pts <= 200 and r.impact_pts <= 150);
    }
}

test "milestones use the real next tier threshold" {
    const a = std.testing.allocator;
    const star = try models.evaluateStarMilestone(a, 1);
    defer a.free(star.value_str);
    try std.testing.expectEqual(@as(u64, 3), star.next); // silver unlocks at 3
    const top = try models.evaluateStreakMilestone(a, 703);
    defer a.free(top.value_str);
    try std.testing.expectEqual(@as(u64, 0), top.next);
    try std.testing.expectEqual(@as(f64, 1), milestones.progress(top));
}

test "rhythm timezone labels and heat levels" {
    var buf: [32]u8 = undefined;
    try std.testing.expectEqualStrings("UTC+5:30", try rhythm.formatOffset(&buf, 5.5));
    try std.testing.expectEqualStrings("UTC\u{2212}3", try rhythm.formatOffset(&buf, -3));
    try std.testing.expectEqualStrings("UTC", try rhythm.formatOffset(&buf, 0));
    try std.testing.expectEqual(@as(u8, 0), rhythm.level(0, 10));
    try std.testing.expectEqual(@as(u8, 1), rhythm.level(1, 10));
    try std.testing.expectEqual(@as(u8, 4), rhythm.level(10, 10));
}

test "milestone progress retains empty, fractional and completed targets" {
    const a = std.testing.allocator;
    const empty = try models.evaluateStreakMilestone(a, 0);
    defer a.free(empty.value_str);
    const partial = try models.evaluateStreakMilestone(a, 69);
    defer a.free(partial.value_str);
    const complete = try models.evaluateStarMilestone(a, 520);
    defer a.free(complete.value_str);
    try std.testing.expectEqual(@as(f64, 0), milestones.progress(empty));
    try std.testing.expectApproxEqAbs(@as(f64, 0.69), milestones.progress(partial), 0.0001);
    try std.testing.expectEqual(@as(f64, 1), milestones.progress(complete));
}

test "optional SVG icons preserve plain labels and release temporary allocations" {
    const allocator = std.testing.allocator;
    const input = "<svg><text x=\"20\" y=\"30\" font-size=\"10\">\u{1f525} Active</text><text x=\"1\" y=\"2\">Plain label</text></svg>";
    const output = try icons.replace(allocator, input, "#ffffff");
    defer allocator.free(output);
    try std.testing.expect(std.mem.indexOf(u8, output, "viewBox=\"0 0 24 24\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "\u{1f525}") == null);
    try std.testing.expect(std.mem.indexOf(u8, output, "Active</text>") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "<text x=\"1\" y=\"2\">Plain label</text>") != null);
}

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
    try std.testing.expect(std.mem.indexOf(u8, rendered, "14-DAY MOMENTUM") != null);
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

    try std.testing.expect(std.mem.indexOf(u8, rendered_no_spark, "14-DAY MOMENTUM") == null);
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
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Developer Stats") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "2,030") != null);
    for ([_][]const u8{ "Commits", "Merged PRs", "Stars", "Repos", "Pull requests", "Collaboration", "Impact", "rating-progress" }) |label|
        try std.testing.expect(std.mem.indexOf(u8, rendered, label) != null);
    // No unsupported percentile claim on the card.
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Top ") == null);
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
        .tz_offset_hours = 5.5,
    });
    defer allocator.free(rendered);

    try std.testing.expect(std.mem.indexOf(u8, rendered, "<svg xmlns=\"http://www.w3.org/2000/svg\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "width=\"424\" height=\"180\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Commit Rhythm") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "UTC+5:30") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "21:00 – 01:00") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "240 recent commits sampled") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Night Owl") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "rhythm-matrix") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "</svg>") != null);
}

test "radar: renderRadarSVG produces valid polyglot radar chart" {
    const allocator = std.testing.allocator;
    const dna = models.DeveloperDNA{
        .username = "testuser",
        .systems_pct = 45.0,
        .backend_pct = 30.0,
        .frontend_pct = 15.0,
        .devops_pct = 7.0,
        .data_pct = 3.0,
        .archetype = "Systems Architect",
        .archetype_icon = "⚙️",
        .archetype_color = "#ec915c",
        .total_languages = 8,
        .top_domain_name = "Systems",
    };

    const t = themes.getTheme("tokyonight");
    const rendered = try radar.renderRadarSVG(allocator, &dna, .{
        .theme = t,
        .card_width = 424,
        .card_height = 180,
        .border_radius = 4.5,
    });
    defer allocator.free(rendered);

    try std.testing.expect(std.mem.indexOf(u8, rendered, "<svg xmlns=\"http://www.w3.org/2000/svg\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "width=\"424\" height=\"180\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Developer DNA") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Systems Architect") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "8 languages") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Strongest in Systems") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Data &amp; AI") != null);
    // The strongest domain (45%) reaches the outer ring: the shape starts at the top outer vertex.
    try std.testing.expect(std.mem.indexOf(u8, rendered, "class=\"dna-shape\" points=\"104.00,60.00 ") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "</svg>") != null);
}

test "velocity: renderVelocitySVG produces valid PR velocity & cadence card" {
    const allocator = std.testing.allocator;
    const tier = models.calculateVelocityTier(94);
    const vel_stats = models.VelocityStats{
        .username = "testuser",
        .total_prs = 32,
        .merged_prs = 28,
        .open_prs = 2,
        .closed_prs = 2,
        .merge_rate = 87.5,
        .avg_turnaround_hours = 18.5,
        .turnaround_str = "18.5h",
        .total_additions = 42800,
        .total_deletions = 14300,
        .changed_files = 186,
        .reviews_completed = 24,
        .velocity_score = 94,
        .tier = tier,
    };

    const t = themes.getTheme("tokyonight");
    const rendered = try velocity.renderVelocitySVG(allocator, &vel_stats, .{
        .theme = t,
        .card_width = 424,
        .card_height = 180,
        .border_radius = 4.5,
    });
    defer allocator.free(rendered);

    try std.testing.expect(std.mem.indexOf(u8, rendered, "<svg xmlns=\"http://www.w3.org/2000/svg\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "width=\"424\" height=\"180\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Pull Requests") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "18.5h") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Merge rate") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "88%") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "28 merged") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "+42.8k / \u{2212}14.3k") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Reviews given") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Velocity") == null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "</svg>") != null);
}

test "milestones: renderMilestonesSVG produces valid achievements showcase card" {
    const allocator = std.testing.allocator;

    const m1 = try models.evaluateStreakMilestone(allocator, 184);
    defer allocator.free(m1.value_str);
    const m2 = try models.evaluatePolyglotMilestone(allocator, 14);
    defer allocator.free(m2.value_str);
    const m3 = try models.evaluateContribsMilestone(allocator, 2480);
    defer allocator.free(m3.value_str);
    const m4 = try models.evaluatePRMilestone(allocator, 28);
    defer allocator.free(m4.value_str);
    const m5 = try models.evaluateRepoMilestone(allocator, 22);
    defer allocator.free(m5.value_str);
    const m6 = try models.evaluateStarMilestone(allocator, 65);
    defer allocator.free(m6.value_str);

    const overview = models.MilestonesOverview{
        .username = "testuser",
        .master_title = "Diamond Architect",
        .master_icon = "💎",
        .master_color = "#70a5fd",
        .master_score = 22,
        .unlocked_count = 6,
        .total_count = 6,
        .items = [6]models.MilestoneItem{ m1, m2, m3, m4, m5, m6 },
    };

    const t = themes.getTheme("tokyonight");
    const rendered = try milestones.renderMilestonesSVG(allocator, &overview, .{
        .theme = t,
        .card_width = 424,
        .card_height = 180,
        .border_radius = 4.5,
    });
    defer allocator.free(rendered);

    try std.testing.expect(std.mem.indexOf(u8, rendered, "<svg xmlns=\"http://www.w3.org/2000/svg\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "width=\"424\" height=\"180\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Milestones") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Diamond Architect") != null);
    for ([_][]const u8{ "184 days", "Languages", "2,480", "Merged PRs", "Repositories", "Stars", "PLATINUM", "next 365" }) |label|
        try std.testing.expect(std.mem.indexOf(u8, rendered, label) != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Max Tier") == null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "</svg>") != null);
}

test "bento: language card height bounds matrix (48 variations)" {
    // 6 languages: rows = 3
    const b6 = bento.getLanguageHeightBounds(6);
    try std.testing.expectEqual(@as(u32, 192), b6.min);
    try std.testing.expectEqual(@as(u32, 216), b6.opt);
    try std.testing.expectEqual(@as(u32, 240), b6.max);

    // 12 languages: rows = 6
    const b12 = bento.getLanguageHeightBounds(12);
    try std.testing.expectEqual(@as(u32, 294), b12.min);
    try std.testing.expectEqual(@as(u32, 339), b12.opt);
    try std.testing.expectEqual(@as(u32, 381), b12.max);

    // 16 languages: rows = 8
    const b16 = bento.getLanguageHeightBounds(16);
    try std.testing.expectEqual(@as(u32, 362), b16.min);
    try std.testing.expectEqual(@as(u32, 421), b16.opt);
    try std.testing.expectEqual(@as(u32, 475), b16.max);
}

test "bento: compute layout geometries for N=1 to N=7" {
    const allocator = std.testing.allocator;

    // N = 1 (solo)
    const cards1 = [_][]const u8{"streak"};
    var l1 = try bento.computeBentoLayout(allocator, &cards1, "solo", 840.0, 12.0, null, null);
    defer l1.deinit();
    try std.testing.expectEqual(@as(usize, 1), l1.slots.len);
    try std.testing.expectEqual(bento.SlotAspect.wide_hero, l1.slots[0].aspect);

    // N = 2 (split-2x1)
    const cards2 = [_][]const u8{ "streak", "stats" };
    var l2 = try bento.computeBentoLayout(allocator, &cards2, "split-2x1", 840.0, 12.0, null, null);
    defer l2.deinit();
    try std.testing.expectEqual(@as(usize, 2), l2.slots.len);
    try std.testing.expectEqual(bento.SlotAspect.standard, l2.slots[0].aspect);

    // N = 3 (pillar-right-stack / profile)
    const cards3 = [_][]const u8{ "streak", "stats", "languages" };
    var l3 = try bento.computeBentoLayout(allocator, &cards3, "pillar-right-stack", 840.0, 8.0, null, null);
    defer l3.deinit();
    try std.testing.expectEqual(@as(usize, 3), l3.slots.len);
    try std.testing.expectEqual(bento.SlotAspect.tall_pillar, l3.slots[2].aspect);
    try std.testing.expectEqual(@as(f64, 368.0), l3.slots[2].h); // Harmonized height: 180 + 8 + 180 = 368

    // N = 4 (matrix-2x2)
    const cards4 = [_][]const u8{ "streak", "stats", "rhythm", "radar" };
    var l4 = try bento.computeBentoLayout(allocator, &cards4, "matrix-2x2", 864.0, 12.0, null, null);
    defer l4.deinit();
    try std.testing.expectEqual(@as(usize, 4), l4.slots.len);

    // N = 7 (master-dashboard)
    const cards7 = [_][]const u8{ "milestones", "streak", "stats", "languages", "rhythm", "radar", "velocity" };
    var l7 = try bento.computeBentoLayout(allocator, &cards7, "master-dashboard", 864.0, 12.0, null, null);
    defer l7.deinit();
    try std.testing.expectEqual(@as(usize, 7), l7.slots.len);
    try std.testing.expectEqual(bento.SlotAspect.wide_hero, l7.slots[0].aspect); // Milestones top ribbon
    try std.testing.expectEqual(@as(f64, 180.0), l7.slots[0].h); // Full 180px height: zero cutoff
    try std.testing.expectEqual(bento.SlotAspect.standard, l7.slots[1].aspect);
    try std.testing.expectEqual(bento.SlotAspect.standard, l7.slots[2].aspect);
    try std.testing.expectEqual(bento.SlotAspect.standard, l7.slots[4].aspect);
    try std.testing.expectEqual(bento.SlotAspect.standard, l7.slots[5].aspect);
    try std.testing.expectEqual(bento.SlotAspect.standard, l7.slots[6].aspect);

    // Mobile stack
    var l_mob = try bento.computeBentoLayout(allocator, &cards3, "mobile-stack", 400.0, 10.0, null, null);
    defer l_mob.deinit();
    try std.testing.expectEqual(@as(usize, 3), l_mob.slots.len);
    try std.testing.expect(l_mob.canvas_h > 500.0);
}

test "bento: composeBentoSVG produces isolated valid SVG" {
    const allocator = std.testing.allocator;
    const cards = [_][]const u8{ "streak", "stats" };
    var layout = try bento.computeBentoLayout(allocator, &cards, "split-2x1", 840.0, 12.0, null, null);
    defer layout.deinit();

    const dummy_card_1 = "<svg width=\"414\" height=\"180\"><defs><linearGradient id=\"test-grad\"></linearGradient></defs><rect fill=\"url(#test-grad)\"/></svg>";
    const dummy_card_2 = "<svg width=\"414\" height=\"180\"><defs><linearGradient id=\"test-grad\"></linearGradient></defs><rect fill=\"url(#test-grad)\"/></svg>";
    const rendered = [_][]const u8{ dummy_card_1, dummy_card_2 };

    const t = themes.getTheme("tokyonight");
    const bento_svg = try bento.composeBentoSVG(allocator, &layout, &rendered, t, 4.5, false);
    defer allocator.free(bento_svg);

    // Verify master SVG
    try std.testing.expect(std.mem.indexOf(u8, bento_svg, "<svg xmlns=\"http://www.w3.org/2000/svg\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, bento_svg, "width=\"840.0\"") != null);
    // Verify namespacing: b0_ and b1_
    try std.testing.expect(std.mem.indexOf(u8, bento_svg, "id=\"b0_test-grad\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, bento_svg, "id=\"b1_test-grad\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, bento_svg, "url(#b0_test-grad)") != null);
    try std.testing.expect(std.mem.indexOf(u8, bento_svg, "url(#b1_test-grad)") != null);
}
