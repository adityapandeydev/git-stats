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

/// CommitRhythm represents a 7-day x 24-hour matrix of commit activity.
pub const CommitRhythm = struct {
    username: []const u8,
    // 7 days (0=Mon .. 6=Sun) x 24 hours (0..23)
    matrix: [7][24]u32 = [_][24]u32{[_]u32{0} ** 24} ** 7,
    total_commits: u64 = 0,
    night_commits: u64 = 0, // 20:00 to 05:00
    day_commits: u64 = 0,   // 05:00 to 20:00
    weekend_commits: u64 = 0, // Sat (5) + Sun (6)
    peak_hour: u8 = 0,
    peak_day: u8 = 0,
    peak_count: u32 = 0,
    persona_title: []const u8 = "Night Owl",
    persona_icon: []const u8 = "🌙",
    persona_color: []const u8 = "#bb9af7",
    peak_window_str: []const u8 = "20:00 – 01:00",
};

pub const RhythmPersona = struct {
    title: []const u8,
    icon: []const u8,
    color: []const u8,
};

pub fn calculateRhythmPersona(
    total_commits: u64,
    night_commits: u64,
    weekend_commits: u64,
    peak_hour: u8,
) RhythmPersona {
    const total_f: f64 = @floatFromInt(@max(1, total_commits));
    const night_pct: f64 = (@as(f64, @floatFromInt(night_commits)) / total_f) * 100.0;
    const weekend_pct: f64 = (@as(f64, @floatFromInt(weekend_commits)) / total_f) * 100.0;

    if (night_pct >= 40.0 or (peak_hour >= 21 or peak_hour <= 4)) {
        return .{
            .title = "Night Owl",
            .icon = "🌙",
            .color = "#bb9af7",
        };
    } else if (peak_hour >= 5 and peak_hour <= 10) {
        return .{
            .title = "Early Bird",
            .icon = "🌅",
            .color = "#e0af68",
        };
    } else if (weekend_pct >= 40.0) {
        return .{
            .title = "Weekend Warrior",
            .icon = "⚔️",
            .color = "#f7768e",
        };
    } else {
        return .{
            .title = "Day Architect",
            .icon = "⚡",
            .color = "#70a5fd",
        };
    }
}

pub const DomainKind = enum {
    systems,
    backend,
    frontend,
    devops,
    data,
};

pub fn classifyLanguageDomain(lang_name: []const u8) DomainKind {
    // Systems & Low-Level: Zig, Rust, C, C++, Assembly, D, Fortran, Ada, V
    if (std.ascii.eqlIgnoreCase(lang_name, "Zig") or
        std.ascii.eqlIgnoreCase(lang_name, "Rust") or
        std.ascii.eqlIgnoreCase(lang_name, "C") or
        std.ascii.eqlIgnoreCase(lang_name, "C++") or
        std.ascii.eqlIgnoreCase(lang_name, "Assembly") or
        std.ascii.eqlIgnoreCase(lang_name, "D") or
        std.ascii.eqlIgnoreCase(lang_name, "Fortran") or
        std.ascii.eqlIgnoreCase(lang_name, "Ada") or
        std.ascii.eqlIgnoreCase(lang_name, "V"))
    {
        return .systems;
    }

    // Web & Frontend: TypeScript, JavaScript, HTML, CSS, SCSS, Vue, Svelte, JSX, TSX
    if (std.ascii.eqlIgnoreCase(lang_name, "TypeScript") or
        std.ascii.eqlIgnoreCase(lang_name, "JavaScript") or
        std.ascii.eqlIgnoreCase(lang_name, "HTML") or
        std.ascii.eqlIgnoreCase(lang_name, "CSS") or
        std.ascii.eqlIgnoreCase(lang_name, "SCSS") or
        std.ascii.eqlIgnoreCase(lang_name, "Vue") or
        std.ascii.eqlIgnoreCase(lang_name, "Svelte") or
        std.ascii.eqlIgnoreCase(lang_name, "QML"))
    {
        return .frontend;
    }

    // DevOps & Infra: Shell, Bash, Nix, Dockerfile, HCL, Makefile, Lua, PowerShell
    if (std.ascii.eqlIgnoreCase(lang_name, "Shell") or
        std.ascii.eqlIgnoreCase(lang_name, "Bash") or
        std.ascii.eqlIgnoreCase(lang_name, "Nix") or
        std.ascii.eqlIgnoreCase(lang_name, "Dockerfile") or
        std.ascii.eqlIgnoreCase(lang_name, "HCL") or
        std.ascii.eqlIgnoreCase(lang_name, "Makefile") or
        std.ascii.eqlIgnoreCase(lang_name, "Lua") or
        std.ascii.eqlIgnoreCase(lang_name, "PowerShell"))
    {
        return .devops;
    }

    // Data & Functional: Jupyter Notebook, SQL, R, Julia, MATLAB, Haskell, OCaml, Clojure
    if (std.ascii.eqlIgnoreCase(lang_name, "Jupyter Notebook") or
        std.ascii.eqlIgnoreCase(lang_name, "SQL") or
        std.ascii.eqlIgnoreCase(lang_name, "R") or
        std.ascii.eqlIgnoreCase(lang_name, "Julia") or
        std.ascii.eqlIgnoreCase(lang_name, "MATLAB") or
        std.ascii.eqlIgnoreCase(lang_name, "Haskell") or
        std.ascii.eqlIgnoreCase(lang_name, "OCaml") or
        std.ascii.eqlIgnoreCase(lang_name, "Clojure"))
    {
        return .data;
    }

    // Default to Backend & Cloud (Go, Java, Python, C#, Kotlin, Scala, Ruby, PHP, etc.)
    return .backend;
}

pub const DeveloperDNA = struct {
    username: []const u8,
    systems_pct: f64 = 0.0,
    backend_pct: f64 = 0.0,
    frontend_pct: f64 = 0.0,
    devops_pct: f64 = 0.0,
    data_pct: f64 = 0.0,
    archetype: []const u8 = "Fullstack Polyglot",
    archetype_icon: []const u8 = "🧬",
    archetype_color: []const u8 = "#70a5fd",
    total_languages: usize = 0,
    top_domain_name: []const u8 = "Systems",
};

pub fn calculateDeveloperDNA(username: []const u8, langs: []const LanguageStat) DeveloperDNA {
    var systems_bytes: u64 = 0;
    var backend_bytes: u64 = 0;
    var frontend_bytes: u64 = 0;
    var devops_bytes: u64 = 0;
    var data_bytes: u64 = 0;
    var total_bytes: u64 = 0;

    for (langs) |l| {
        total_bytes += l.size;
        switch (classifyLanguageDomain(l.name)) {
            .systems => systems_bytes += l.size,
            .backend => backend_bytes += l.size,
            .frontend => frontend_bytes += l.size,
            .devops => devops_bytes += l.size,
            .data => data_bytes += l.size,
        }
    }

    const total_f: f64 = @floatFromInt(@max(1, total_bytes));
    const s_pct = (@as(f64, @floatFromInt(systems_bytes)) / total_f) * 100.0;
    const b_pct = (@as(f64, @floatFromInt(backend_bytes)) / total_f) * 100.0;
    const f_pct = (@as(f64, @floatFromInt(frontend_bytes)) / total_f) * 100.0;
    const d_pct = (@as(f64, @floatFromInt(devops_bytes)) / total_f) * 100.0;
    const a_pct = (@as(f64, @floatFromInt(data_bytes)) / total_f) * 100.0;

    var archetype: []const u8 = "Polyglot Architect";
    var icon: []const u8 = "🧬";
    var color: []const u8 = "#bb9af7";
    var top_name: []const u8 = "Polyglot";

    const max_pct = @max(s_pct, @max(b_pct, @max(f_pct, @max(d_pct, a_pct))));

    if (s_pct == max_pct and s_pct >= 30.0) {
        archetype = "Systems Architect";
        icon = "⚙️";
        color = "#ec915c";
        top_name = "Systems";
    } else if (b_pct == max_pct and b_pct >= 35.0) {
        archetype = "Backend Specialist";
        icon = "🛡️";
        color = "#70a5fd";
        top_name = "Backend";
    } else if (f_pct == max_pct and f_pct >= 35.0) {
        archetype = "Frontend Craftsman";
        icon = "🎨";
        color = "#7aa2f7";
        top_name = "Frontend";
    } else if (d_pct == max_pct and d_pct >= 30.0) {
        archetype = "Platform Engineer";
        icon = "🚀";
        color = "#bb9af7";
        top_name = "DevOps";
    } else if (a_pct == max_pct and a_pct >= 30.0) {
        archetype = "Data Engineer";
        icon = "📊";
        color = "#73daca";
        top_name = "Data & AI";
    } else {
        archetype = "Polyglot Architect";
        icon = "🧬";
        color = "#70a5fd";
        top_name = "Polyglot";
    }

    return .{
        .username = username,
        .systems_pct = s_pct,
        .backend_pct = b_pct,
        .frontend_pct = f_pct,
        .devops_pct = d_pct,
        .data_pct = a_pct,
        .archetype = archetype,
        .archetype_icon = icon,
        .archetype_color = color,
        .total_languages = langs.len,
        .top_domain_name = top_name,
    };
}

pub const VelocityTier = struct {
    name: []const u8,
    icon: []const u8,
    color: []const u8,
    percentile: []const u8,
};

pub const VelocityStats = struct {
    username: []const u8,
    total_prs: u64 = 0,
    merged_prs: u64 = 0,
    open_prs: u64 = 0,
    closed_prs: u64 = 0,
    merge_rate: f64 = 0.0, // 0.0 - 100.0%

    // Turnaround time in hours
    avg_turnaround_hours: f64 = 0.0,
    turnaround_str: []const u8 = "18h",

    // Code churn
    total_additions: u64 = 0,
    total_deletions: u64 = 0,
    changed_files: u64 = 0,

    // Collaboration
    reviews_completed: u64 = 0,

    // Composite velocity score (0 - 100)
    velocity_score: u32 = 0,
    tier: VelocityTier,
};

pub fn calculateVelocityTier(score: u32) VelocityTier {
    if (score >= 88) {
        return .{
            .name = "Hypersonic Shipper",
            .icon = "⚡",
            .color = "#bb9af7",
            .percentile = "Top 2% Velocity",
        };
    } else if (score >= 75) {
        return .{
            .name = "Rapid Shipper",
            .icon = "🚀",
            .color = "#70a5fd",
            .percentile = "Top 10% Velocity",
        };
    } else if (score >= 60) {
        return .{
            .name = "High Momentum",
            .icon = "🔥",
            .color = "#73daca",
            .percentile = "Top 25% Velocity",
        };
    } else if (score >= 45) {
        return .{
            .name = "Steady Cadence",
            .icon = "🎯",
            .color = "#e0af68",
            .percentile = "Top 50% Velocity",
        };
    } else {
        return .{
            .name = "Deep Reviewer",
            .icon = "🔍",
            .color = "#9aa5ce",
            .percentile = "Standard Cadence",
        };
    }
}


