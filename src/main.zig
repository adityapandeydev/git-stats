const std = @import("std");
const git_stats = @import("git_stats");
const models = git_stats.models;
const colors = git_stats.colors;
const github_client = git_stats.client;
const themes = git_stats.themes;
const svg_renderer = git_stats.svg;
const streak_renderer = git_stats.streak;
const stats_renderer = git_stats.stats;

const CliConfig = struct {
    generate: bool = false,
    card: []const u8 = "languages", // "languages", "streak", or "stats"
    timeframe: []const u8 = "all-time", // "all-time" or "this-year"
    username: ?[]const u8 = null,
    output: []const u8 = "languages.svg",
    langs_count: usize = 8,
    hide: ?[]const u8 = null,
    theme: []const u8 = "tokyonight",
    layout: []const u8 = "standard",
    columns: usize = 2,
    card_width: u32 = 400,
    card_height: u32 = 364,
    border_radius: f64 = 4.5,
    token: ?[]const u8 = null,
    exclude_repo: ?[]const u8 = null,
    title: ?[]const u8 = null,
    hide_title: bool = false,
    hide_border: bool = false,
    animate: bool = true,
    show_sparkline: bool = true,
    title_color: ?[]const u8 = null,
    text_color: ?[]const u8 = null,
    bg_color: ?[]const u8 = null,
    border_color: ?[]const u8 = null,
};

fn parseDotEnv(allocator: std.mem.Allocator, io: std.Io, cwd: std.Io.Dir) ?std.StringHashMap([]const u8) {
    const content = cwd.readFileAlloc(io, ".env", allocator, .limited(1024 * 1024)) catch return null;
    var map = std.StringHashMap([]const u8).init(allocator);

    var line_iter = std.mem.splitScalar(u8, content, '\n');
    while (line_iter.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r\n");
        if (trimmed.len == 0 or trimmed[0] == '#') continue;

        if (std.mem.indexOfScalar(u8, trimmed, '=')) |eq_idx| {
            const key = std.mem.trim(u8, trimmed[0..eq_idx], " \t\r\n");
            var val = std.mem.trim(u8, trimmed[eq_idx + 1 ..], " \t\r\n");
            val = std.mem.trim(u8, val, "\"'");
            map.put(key, val) catch {};
        }
    }
    return map;
}

fn parseCliArgs(args: []const []const u8) CliConfig {
    var cfg = CliConfig{};
    var i: usize = 1;

    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--generate")) {
            cfg.generate = true;
        } else if (std.mem.startsWith(u8, arg, "--card=")) {
            cfg.card = arg["--card=".len..];
        } else if (std.mem.eql(u8, arg, "--card") and i + 1 < args.len) {
            i += 1;
            cfg.card = args[i];
        } else if (std.mem.eql(u8, arg, "--streak")) {
            cfg.card = "streak";
        } else if (std.mem.eql(u8, arg, "--stats")) {
            cfg.card = "stats";
        } else if (std.mem.startsWith(u8, arg, "--timeframe=")) {
            cfg.timeframe = arg["--timeframe=".len..];
        } else if (std.mem.eql(u8, arg, "--timeframe") and i + 1 < args.len) {
            i += 1;
            cfg.timeframe = args[i];
        } else if (std.mem.startsWith(u8, arg, "--username=")) {
            cfg.username = arg["--username=".len..];
        } else if (std.mem.eql(u8, arg, "--username") and i + 1 < args.len) {
            i += 1;
            cfg.username = args[i];
        } else if (std.mem.startsWith(u8, arg, "--output=")) {
            cfg.output = arg["--output=".len..];
        } else if (std.mem.eql(u8, arg, "--output") and i + 1 < args.len) {
            i += 1;
            cfg.output = args[i];
        } else if (std.mem.startsWith(u8, arg, "--langs-count=")) {
            cfg.langs_count = std.fmt.parseInt(usize, arg["--langs-count=".len..], 10) catch 8;
        } else if (std.mem.eql(u8, arg, "--langs-count") and i + 1 < args.len) {
            i += 1;
            cfg.langs_count = std.fmt.parseInt(usize, args[i], 10) catch 8;
        } else if (std.mem.startsWith(u8, arg, "--hide=")) {
            cfg.hide = arg["--hide=".len..];
        } else if (std.mem.eql(u8, arg, "--hide") and i + 1 < args.len) {
            i += 1;
            cfg.hide = args[i];
        } else if (std.mem.startsWith(u8, arg, "--theme=")) {
            cfg.theme = arg["--theme=".len..];
        } else if (std.mem.eql(u8, arg, "--theme") and i + 1 < args.len) {
            i += 1;
            cfg.theme = args[i];
        } else if (std.mem.startsWith(u8, arg, "--layout=")) {
            cfg.layout = arg["--layout=".len..];
        } else if (std.mem.eql(u8, arg, "--layout") and i + 1 < args.len) {
            i += 1;
            cfg.layout = args[i];
        } else if (std.mem.startsWith(u8, arg, "--columns=")) {
            cfg.columns = std.fmt.parseInt(usize, arg["--columns=".len..], 10) catch 2;
        } else if (std.mem.eql(u8, arg, "--columns") and i + 1 < args.len) {
            i += 1;
            cfg.columns = std.fmt.parseInt(usize, args[i], 10) catch 2;
        } else if (std.mem.startsWith(u8, arg, "--card-width=")) {
            cfg.card_width = std.fmt.parseInt(u32, arg["--card-width=".len..], 10) catch 400;
        } else if (std.mem.eql(u8, arg, "--card-width") and i + 1 < args.len) {
            i += 1;
            cfg.card_width = std.fmt.parseInt(u32, args[i], 10) catch 400;
        } else if (std.mem.startsWith(u8, arg, "--card-height=")) {
            cfg.card_height = std.fmt.parseInt(u32, arg["--card-height=".len..], 10) catch 364;
        } else if (std.mem.eql(u8, arg, "--card-height") and i + 1 < args.len) {
            i += 1;
            cfg.card_height = std.fmt.parseInt(u32, args[i], 10) catch 364;
        } else if (std.mem.startsWith(u8, arg, "--border-radius=")) {
            cfg.border_radius = std.fmt.parseFloat(f64, arg["--border-radius=".len..]) catch 4.5;
        } else if (std.mem.eql(u8, arg, "--border-radius") and i + 1 < args.len) {
            i += 1;
            cfg.border_radius = std.fmt.parseFloat(f64, args[i]) catch 4.5;
        } else if (std.mem.startsWith(u8, arg, "--token=")) {
            cfg.token = arg["--token=".len..];
        } else if (std.mem.eql(u8, arg, "--token") and i + 1 < args.len) {
            i += 1;
            cfg.token = args[i];
        } else if (std.mem.startsWith(u8, arg, "--exclude-repo=")) {
            cfg.exclude_repo = arg["--exclude-repo=".len..];
        } else if (std.mem.eql(u8, arg, "--exclude-repo") and i + 1 < args.len) {
            i += 1;
            cfg.exclude_repo = args[i];
        } else if (std.mem.startsWith(u8, arg, "--title=")) {
            cfg.title = arg["--title=".len..];
        } else if (std.mem.eql(u8, arg, "--title") and i + 1 < args.len) {
            i += 1;
            cfg.title = args[i];
        } else if (std.mem.eql(u8, arg, "--hide-title")) {
            cfg.hide_title = true;
        } else if (std.mem.eql(u8, arg, "--hide-border")) {
            cfg.hide_border = true;
        } else if (std.mem.eql(u8, arg, "--animate=false")) {
            cfg.animate = false;
        } else if (std.mem.eql(u8, arg, "--animate=true") or std.mem.eql(u8, arg, "--animate")) {
            cfg.animate = true;
        } else if (std.mem.startsWith(u8, arg, "--title-color=")) {
            cfg.title_color = arg["--title-color=".len..];
        } else if (std.mem.startsWith(u8, arg, "--text-color=")) {
            cfg.text_color = arg["--text-color=".len..];
        } else if (std.mem.startsWith(u8, arg, "--bg-color=")) {
            cfg.bg_color = arg["--bg-color=".len..];
        } else if (std.mem.startsWith(u8, arg, "--border-color=")) {
            cfg.border_color = arg["--border-color=".len..];
        } else if (std.mem.eql(u8, arg, "--hide-sparkline") or std.mem.eql(u8, arg, "--show-sparkline=false")) {
            cfg.show_sparkline = false;
        } else if (std.mem.eql(u8, arg, "--show-sparkline=true") or std.mem.eql(u8, arg, "--show-sparkline")) {
            cfg.show_sparkline = true;
        }
    }

    return cfg;
}

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;
    const cwd = std.Io.Dir.cwd();

    const args = try init.minimal.args.toSlice(arena);
    const cli = parseCliArgs(args);

    // Resolve .env map if present
    const env_map_opt = parseDotEnv(arena, io, cwd);

    // Resolve Auth Token: flag > env > .env
    var auth_token: []const u8 = "";
    if (cli.token) |t| {
        auth_token = github_client.cleanToken(t);
    }
    if (auth_token.len == 0) {
        if (init.environ_map.get("GH_TOKEN")) |t| {
            auth_token = github_client.cleanToken(t);
        }
    }
    if (auth_token.len == 0) {
        if (init.environ_map.get("GITHUB_TOKEN")) |t| {
            auth_token = github_client.cleanToken(t);
        }
    }
    if (auth_token.len == 0) {
        if (env_map_opt) |map| {
            if (map.get("GH_TOKEN")) |t| {
                auth_token = github_client.cleanToken(t);
            } else if (map.get("GITHUB_TOKEN")) |t| {
                auth_token = github_client.cleanToken(t);
            }
        }
    }

    // Resolve Username: flag > env GITHUB_REPOSITORY_OWNER > default
    var username: []const u8 = "adityapandeydev";
    if (cli.username) |u| {
        const trimmed = std.mem.trim(u8, u, " \t\r\n");
        if (trimmed.len > 0) username = trimmed;
    } else if (init.environ_map.get("GITHUB_REPOSITORY_OWNER")) |u| {
        const trimmed = std.mem.trim(u8, u, " \t\r\n");
        if (trimmed.len > 0) username = trimmed;
    }

    // Excluded Repos
    var excluded_repos: std.ArrayList([]const u8) = .empty;
    defer excluded_repos.deinit(arena);
    if (cli.exclude_repo) |ex_str| {
        var iter = std.mem.splitScalar(u8, ex_str, ',');
        while (iter.next()) |item| {
            const clean = std.mem.trim(u8, item, " \t\r\n");
            if (clean.len > 0) {
                try excluded_repos.append(arena, clean);
            }
        }
    }

    std.debug.print("⚡ Fetching GitHub stats for user '{s}'...\n", .{username});
    if (auth_token.len > 0) {
        const masked = try github_client.maskToken(arena, auth_token);
        std.debug.print("🔑 Authenticated using token: {s}\n", .{masked});
    } else {
        std.debug.print("ℹ️  Running in unauthenticated mode (public repos only)\n", .{});
    }

    var client = github_client.Client.init(arena, io, auth_token);

    // Apply theme
    const base_theme = themes.getTheme(cli.theme);
    const active_theme = themes.applyThemeOverrides(
        base_theme,
        cli.bg_color,
        cli.title_color,
        cli.text_color,
        cli.border_color,
        null,
        cli.border_radius,
    );

    // Check if generating streak card
    if (std.mem.eql(u8, cli.card, "streak")) {
        std.debug.print("⚡ Fetching GitHub streak data for user '{s}'...\n", .{username});
        const streak_stats = client.getStreakStats(username, auth_token) catch |err| {
            std.debug.print("❌ Error fetching streak stats: {}\n", .{err});
            return err;
        };

        std.debug.print("🔥 Current Streak: {d} days ({s} - {s})\n", .{
            streak_stats.current_streak,
            streak_stats.current_streak_start,
            streak_stats.current_streak_end,
        });
        std.debug.print("🏆 Longest Streak: {d} days ({s} - {s})\n", .{
            streak_stats.longest_streak,
            streak_stats.longest_streak_start,
            streak_stats.longest_streak_end,
        });
        std.debug.print("📊 Total Contributions: {d} ({s} - {s})\n", .{
            streak_stats.total_contributions,
            streak_stats.first_contribution_date,
            streak_stats.latest_contribution_date,
        });

        const streak_opts = streak_renderer.StreakRenderOptions{
            .theme = active_theme,
            .card_width = if (cli.card_width != 400) cli.card_width else 424,
            .card_height = if (cli.card_height != 364) cli.card_height else 180,
            .border_radius = cli.border_radius,
            .hide_border = cli.hide_border,
            .animate = cli.animate,
            .show_sparkline = cli.show_sparkline,
            .mode = cli.layout,
        };

        const svg_content = try streak_renderer.renderStreakSVG(arena, streak_stats, streak_opts);

        const out_file = if (std.mem.eql(u8, cli.output, "languages.svg")) "streak.svg" else cli.output;

        if (std.fs.path.dirname(out_file)) |dir| {
            if (dir.len > 0 and !std.mem.eql(u8, dir, ".")) {
                cwd.createDirPath(io, dir) catch {};
            }
        }

        try cwd.writeFile(io, .{ .sub_path = out_file, .data = svg_content });

        std.debug.print("✅ Successfully generated streak card '{s}' for '{s}' ({d}x{d} px)\n", .{
            out_file,
            username,
            streak_opts.card_width,
            streak_opts.card_height,
        });
        return;
    }

    // Check if generating developer stats card
    if (std.mem.eql(u8, cli.card, "stats")) {
        std.debug.print("⚡ Fetching GitHub developer stats ({s}) for user '{s}'...\n", .{ cli.timeframe, username });
        const overall_stats = client.getOverallStats(username, auth_token, cli.timeframe) catch |err| {
            std.debug.print("❌ Error fetching developer stats: {}\n", .{err});
            return err;
        };

        const rating = overall_stats.rating;
        std.debug.print("🏆 Developer Rating: {s} ({d}/1000) - {s} [{s}]\n", .{
            rating.tier,
            rating.score,
            rating.title,
            rating.percentile,
        });
        std.debug.print("📦 Commits: {d} | Merged PRs: {d}/{d} | Stars: {d} | Repos: {d}\n", .{
            overall_stats.total_commits,
            overall_stats.merged_prs,
            overall_stats.total_prs,
            overall_stats.total_stars,
            overall_stats.contributed_repos,
        });

        const stats_opts = stats_renderer.StatsRenderOptions{
            .theme = active_theme,
            .card_width = if (cli.card_width != 400) cli.card_width else 424,
            .card_height = if (cli.card_height != 364) cli.card_height else 180,
            .border_radius = cli.border_radius,
            .hide_border = cli.hide_border,
            .hide_title = cli.hide_title,
            .animate = cli.animate,
        };

        const svg_content = try stats_renderer.renderStatsSVG(arena, overall_stats, stats_opts);

        const out_file = if (std.mem.eql(u8, cli.output, "languages.svg")) "stats.svg" else cli.output;

        if (std.fs.path.dirname(out_file)) |dir| {
            if (dir.len > 0 and !std.mem.eql(u8, dir, ".")) {
                cwd.createDirPath(io, dir) catch {};
            }
        }

        try cwd.writeFile(io, .{ .sub_path = out_file, .data = svg_content });

        std.debug.print("✅ Successfully generated developer stats card '{s}' for '{s}' ({d}x{d} px)\n", .{
            out_file,
            username,
            stats_opts.card_width,
            stats_opts.card_height,
        });
        return;
    }

    const stats = client.getUserLanguages(username, auth_token, excluded_repos.items) catch |err| {
        std.debug.print("❌ Error fetching stats: {}\n", .{err});
        return err;
    };

    // Parse hidden languages lookup set
    var hidden_map = std.StringHashMap(void).init(arena);
    if (cli.hide) |hide_str| {
        var iter = std.mem.splitScalar(u8, hide_str, ',');
        while (iter.next()) |item| {
            var buf: [128]u8 = undefined;
            const len = @min(item.len, buf.len);
            for (item[0..len], 0..) |c, idx| {
                buf[idx] = std.ascii.toLower(c);
            }
            const clean = std.mem.trim(u8, buf[0..len], " \t\r\n");
            if (clean.len > 0) {
                const duped = try arena.dupe(u8, clean);
                try hidden_map.put(duped, {});
                if (std.mem.eql(u8, clean, "jyputer notebook") or std.mem.eql(u8, clean, "jupyter notebook")) {
                    try hidden_map.put("jupyter notebook", {});
                    try hidden_map.put("jyputer notebook", {});
                }
            }
        }
    }

    // Filter visible languages
    var visible_langs: std.ArrayList(models.LanguageStat) = .empty;
    defer visible_langs.deinit(arena);

    for (stats.languages) |l| {
        var buf: [128]u8 = undefined;
        const len = @min(l.name.len, buf.len);
        for (l.name[0..len], 0..) |c, idx| {
            buf[idx] = std.ascii.toLower(c);
        }
        const lower_name = buf[0..len];

        if (!hidden_map.contains(lower_name)) {
            try visible_langs.append(arena, l);
        }
    }

    var filtered_stats = models.UserStats{
        .username = stats.username,
        .total_bytes = stats.total_bytes,
        .languages = visible_langs.items,
    };

    const render_opts = svg_renderer.RenderOptions{
        .theme = active_theme,
        .card_width = cli.card_width,
        .card_height = cli.card_height,
        .langs_count = cli.langs_count,
        .columns = cli.columns,
        .layout = cli.layout,
        .hide_title = cli.hide_title,
        .custom_title = cli.title,
        .animate = cli.animate,
        .border_radius = cli.border_radius,
        .hide_border = cli.hide_border,
        .show_percent = true,
    };

    const svg_content = try svg_renderer.renderSVG(arena, &filtered_stats, render_opts);

    // If output path includes directory, ensure it exists
    if (std.fs.path.dirname(cli.output)) |dir| {
        if (dir.len > 0 and !std.mem.eql(u8, dir, ".")) {
            cwd.createDirPath(io, dir) catch {};
        }
    }

    try cwd.writeFile(io, .{ .sub_path = cli.output, .data = svg_content });

    std.debug.print("✅ Successfully generated '{s}' for '{s}' ({d} languages, {d}x{d} px)\n", .{
        cli.output,
        username,
        visible_langs.items.len,
        cli.card_width,
        cli.card_height,
    });
}
