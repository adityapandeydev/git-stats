const std = @import("std");

/// LanguageStat represents a single language's statistics.
pub const LanguageStat = struct {
    name: []const u8,
    color: []const u8,
    size: u64,
    percentage: f64,
};

/// UserStats represents aggregated language stats for a GitHub user.
pub const UserStats = struct {
    username: []const u8,
    total_bytes: u64,
    languages: []LanguageStat,
};

/// ContributionDay represents a single day's contribution count.
pub const ContributionDay = struct {
    date: []const u8, // "YYYY-MM-DD"
    count: u32,
};

/// StreakStats represents aggregated streak and contribution momentum stats.
pub const StreakStats = struct {
    username: []const u8,
    total_contributions: u64,
    first_contribution_date: []const u8,
    latest_contribution_date: []const u8,

    current_streak: u32,
    current_streak_start: []const u8,
    current_streak_end: []const u8,
    is_streak_active: bool,

    longest_streak: u32,
    longest_streak_start: []const u8,
    longest_streak_end: []const u8,

    // 14-day momentum sparkline
    recent_14_days: [14]u32 = [_]u32{0} ** 14,
    max_14_day_count: u32 = 0,
    total_14_day_count: u32 = 0,
};

/// DeveloperRating represents the Craft & Consistency developer rating.
pub const DeveloperRating = struct {
    score: u32, // 0 - 1000
    tier: []const u8, // "S+", "S", "A+", "A", "B+", "B", "C"
    title: []const u8, // e.g. "Mythic Architect", "Master Craftsman"
    percentile: []const u8, // e.g. "Top 0.5%", "Top 2%"
    color: []const u8, // Primary tier color
    glow_color: []const u8, // Secondary aura color
    progress: f64, // 0.0 - 1.0 (for circular ring gauge stroke-dashoffset)
};

/// Calculate 1000-point Craft & Consistency Developer Rating.
pub fn calculateDeveloperRating(
    commits: u64,
    total_prs: u64,
    merged_prs: u64,
    closed_issues: u64,
    stars: u64,
    contributed_repos: u64,
) DeveloperRating {
    // 1. Commits (Max 350 pts)
    var s_commits: f64 = 0.0;
    const c = @as(f64, @floatFromInt(commits));
    if (c < 100.0) {
        s_commits = c * 1.2; // 0 - 120
    } else if (c < 500.0) {
        s_commits = 120.0 + (c - 100.0) * 0.25; // 120 - 220
    } else if (c < 1500.0) {
        s_commits = 220.0 + (c - 500.0) * 0.08; // 220 - 300
    } else {
        s_commits = @min(350.0, 300.0 + (c - 1500.0) * 0.04); // 300 - 350
    }

    // 2. Pull Requests (Max 300 pts)
    const m_pts = @min(200.0, @as(f64, @floatFromInt(merged_prs)) * 14.0);
    const pr_ratio: f64 = if (total_prs > 0)
        @as(f64, @floatFromInt(merged_prs)) / @as(f64, @floatFromInt(total_prs))
    else if (commits > 50)
        0.80
    else
        0.50;
    const ratio_pts = pr_ratio * 100.0;
    const s_prs = @min(300.0, m_pts + ratio_pts);

    // 3. Collaboration & Resolution (Issues & Repos) (Max 200 pts)
    const issue_pts = @min(110.0, @as(f64, @floatFromInt(closed_issues)) * 12.0);
    const repo_pts = @min(90.0, @as(f64, @floatFromInt(contributed_repos)) * 10.0);
    const s_collab = @min(200.0, issue_pts + repo_pts);

    // 4. Stargazers / Ecosystem Impact (Max 150 pts)
    const st = @as(f64, @floatFromInt(stars));
    var s_stars: f64 = 0.0;
    if (st == 0) {
        s_stars = 25.0; // Baseline for active open-source creator
    } else if (st < 10.0) {
        s_stars = 25.0 + st * 4.0; // 25 - 65
    } else if (st < 50.0) {
        s_stars = 65.0 + (st - 10.0) * 1.5; // 65 - 125
    } else {
        s_stars = @min(150.0, 125.0 + (st - 50.0) * 0.25); // 125 - 150
    }

    const total_f = @min(1000.0, s_commits + s_prs + s_collab + s_stars);
    const score = @as(u32, @intFromFloat(total_f));
    const progress = total_f / 1000.0;

    if (score >= 880) {
        return .{
            .score = score,
            .tier = "S+",
            .title = "Mythic Architect",
            .percentile = "Top 0.5%",
            .color = "#f7768e",
            .glow_color = "#ff9e64",
            .progress = progress,
        };
    } else if (score >= 760) {
        return .{
            .score = score,
            .tier = "S",
            .title = "Master Craftsman",
            .percentile = "Top 2%",
            .color = "#bb9af7",
            .glow_color = "#7aa2f7",
            .progress = progress,
        };
    } else if (score >= 640) {
        return .{
            .score = score,
            .tier = "A+",
            .title = "Lead Engineer",
            .percentile = "Top 6%",
            .color = "#70a5fd",
            .glow_color = "#7dcfff",
            .progress = progress,
        };
    } else if (score >= 520) {
        return .{
            .score = score,
            .tier = "A",
            .title = "Senior Builder",
            .percentile = "Top 14%",
            .color = "#7dcfff",
            .glow_color = "#73daca",
            .progress = progress,
        };
    } else if (score >= 400) {
        return .{
            .score = score,
            .tier = "B+",
            .title = "Proficient Contributor",
            .percentile = "Top 28%",
            .color = "#73daca",
            .glow_color = "#9ece6a",
            .progress = progress,
        };
    } else if (score >= 280) {
        return .{
            .score = score,
            .tier = "B",
            .title = "Active Contributor",
            .percentile = "Top 45%",
            .color = "#e0af68",
            .glow_color = "#ff9e64",
            .progress = progress,
        };
    } else {
        return .{
            .score = score,
            .tier = "C",
            .title = "Rising Talent",
            .percentile = "Top 70%",
            .color = "#9aa5ce",
            .glow_color = "#565f89",
            .progress = progress,
        };
    }
}

/// OverallStats represents aggregated stats across commits, PRs, issues, stars, and developer rating.
pub const OverallStats = struct {
    username: []const u8,
    name: []const u8,
    timeframe: []const u8 = "all-time", // "all-time" or "this-year"

    total_commits: u64,
    total_prs: u64,
    merged_prs: u64,
    total_issues: u64,
    closed_issues: u64,
    total_stars: u64,
    contributed_repos: u64,

    rating: DeveloperRating,
};

