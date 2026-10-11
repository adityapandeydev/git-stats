//! Browser-only entry point. Shares renderers with the production CLI; no network or OS imports.
const std = @import("std");
const models = @import("github/models.zig");
const themes = @import("renderer/themes.zig");
const host_allocator = if (@import("builtin").target.cpu.arch == .wasm32) std.heap.wasm_allocator else std.heap.page_allocator;
var arena: ?std.heap.ArenaAllocator = null;
var output: []const u8 = "";

const Metrics = struct {
    commits: u64 = 0,
    total_prs: u64 = 0,
    merged_prs: u64 = 0,
    closed_issues: u64 = 0,
    stars: u64 = 0,
    contributed_repos: u64 = 0,
    repos: u64 = 0,
};
pub const Request = struct {
    card: []const u8,
    theme: []const u8 = "tokyonight",
    username: []const u8 = "demo",
    width: u32 = 424,
    height: u32 = 180,
    count: usize = 12,
    sparkline: bool = true,
    timeframe: []const u8 = "all-time",
    languages: []models.LanguageStat = &.{},
    metrics: Metrics = .{},
    streak: ?models.StreakStats = null,
    rhythm: ?models.CommitRhythm = null,
    velocity: ?models.VelocityStats = null,
};

export fn studio_alloc(len: usize) usize {
    const buf = host_allocator.alloc(u8, len) catch return 0;
    return @intFromPtr(buf.ptr);
}
export fn studio_free(ptr: usize, len: usize) void {
    host_allocator.free(@as([*]u8, @ptrFromInt(ptr))[0..len]);
}
export fn studio_output_len() usize {
    return output.len;
}
export fn studio_render(ptr: usize, len: usize) usize {
    if (arena) |*a| a.deinit();
    arena = std.heap.ArenaAllocator.init(host_allocator);
    output = "";
    const allocator = arena.?.allocator();
    const request = std.json.parseFromSlice(Request, allocator, @as([*]const u8, @ptrFromInt(ptr))[0..len], .{ .ignore_unknown_fields = true }) catch return 0;
    const svg = render(allocator, request.value) catch return 0;
    output = @import("renderer/icons.zig").replace(allocator, svg, themes.getTheme(request.value.theme).title_color) catch return 0;
    return @intFromPtr(output.ptr);
}

pub fn render(a: std.mem.Allocator, r: Request) ![]const u8 {
    const theme = themes.getTheme(r.theme);
    const width = std.math.clamp(r.width, 300, 1200);
    const height = std.math.clamp(r.height, 124, 1500);
    if (std.mem.eql(u8, r.card, "languages")) {
        const data = models.UserStats{ .username = r.username, .total_bytes = 0, .languages = r.languages };
        return @import("renderer/svg.zig").renderSVG(a, &data, .{ .theme = theme, .card_width = width, .card_height = height, .langs_count = r.count, .columns = 2, .animate = false });
    }
    if (std.mem.eql(u8, r.card, "stats")) {
        const m = r.metrics;
        const data = models.OverallStats{ .username = r.username, .name = r.username, .timeframe = r.timeframe, .total_commits = m.commits, .total_prs = m.total_prs, .merged_prs = m.merged_prs, .total_issues = 0, .closed_issues = m.closed_issues, .total_stars = m.stars, .contributed_repos = m.contributed_repos, .rating = models.calculateDeveloperRating(m.commits, m.total_prs, m.merged_prs, m.closed_issues, m.stars, m.contributed_repos) };
        return @import("renderer/stats.zig").renderStatsSVG(a, &data, .{ .theme = theme, .card_width = width, .card_height = height, .animate = false });
    }
    if (std.mem.eql(u8, r.card, "streak")) {
        const data = r.streak orelse return error.MissingData;
        return @import("renderer/streak.zig").renderStreakSVG(a, &data, .{ .theme = theme, .card_width = width, .card_height = height, .show_sparkline = r.sparkline, .animate = false });
    }
    if (std.mem.eql(u8, r.card, "radar")) {
        const data = models.calculateDeveloperDNA(r.username, r.languages);
        return @import("renderer/radar.zig").renderRadarSVG(a, &data, .{ .theme = theme, .card_width = width, .card_height = height, .animate = false });
    }
    if (std.mem.eql(u8, r.card, "rhythm")) {
        var data = r.rhythm orelse return error.MissingData;
        const persona = models.calculateRhythmPersona(data.total_commits, data.night_commits, data.weekend_commits, data.peak_hour);
        data.persona_title = if (data.total_commits == 0) "No commit activity" else persona.title;
        data.persona_icon = persona.icon;
        data.persona_color = persona.color;
        return @import("renderer/rhythm.zig").renderRhythmSVG(a, &data, .{ .theme = theme, .card_width = width, .card_height = height, .animate = false });
    }
    if (std.mem.eql(u8, r.card, "velocity")) {
        var data = r.velocity orelse return error.MissingData;
        data.tier = models.calculateVelocityTier(data.velocity_score);
        return @import("renderer/velocity.zig").renderVelocitySVG(a, &data, .{ .theme = theme, .card_width = width, .card_height = height, .animate = false });
    }
    if (std.mem.eql(u8, r.card, "milestones")) {
        const s = r.streak orelse return error.MissingData;
        const m = r.metrics;
        const items = [6]models.MilestoneItem{
            try models.evaluateStreakMilestone(a, s.longest_streak),
            try models.evaluatePolyglotMilestone(a, r.languages.len),
            try models.evaluateContribsMilestone(a, s.total_contributions),
            try models.evaluatePRMilestone(a, m.merged_prs),
            try models.evaluateRepoMilestone(a, m.repos),
            try models.evaluateStarMilestone(a, m.stars),
        };
        var score: u32 = 0;
        for (items) |item| score += item.tier.points();
        const master = models.calculateMasterMilestoneTier(score);
        const data = models.MilestonesOverview{ .username = r.username, .master_title = master.title, .master_icon = master.icon, .master_color = master.color, .master_score = score, .unlocked_count = 6, .total_count = 6, .items = items };
        return @import("renderer/milestones.zig").renderMilestonesSVG(a, &data, .{ .theme = theme, .card_width = width, .card_height = height, .animate = false });
    }
    return error.UnknownCard;
}
