const std = @import("std");
const git_stats = @import("git_stats");
const models = git_stats.models;
const colors = git_stats.colors;
const github_client = git_stats.client;
const themes = git_stats.themes;
const svg_renderer = git_stats.svg;

const CliConfig = struct {
    generate: bool = false,
    username: ?[]const u8 = null,
    output: []const u8 = "languages.svg",
    langs_count: usize = 8,
    hide: ?[]const u8 = null,
    theme: []const u8 = "tokyonight",
    layout: []const u8 = "standard",
    columns: usize = 2,
    card_width: u32 = 400,
    card_height: u32 = 368,
    border_radius: f64 = 4.5,
    token: ?[]const u8 = null,
    exclude_repo: ?[]const u8 = null,
    title: ?[]const u8 = null,
    hide_title: bool = false,
    hide_border: bool = false,
    animate: bool = true,
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
            cfg.card_height = std.fmt.parseInt(u32, arg["--card-height=".len..], 10) catch 368;
        } else if (std.mem.eql(u8, arg, "--card-height") and i + 1 < args.len) {
            i += 1;
            cfg.card_height = std.fmt.parseInt(u32, args[i], 10) catch 368;
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
