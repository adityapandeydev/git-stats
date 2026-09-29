const std = @import("std");
const models = @import("models.zig");
const colors = @import("colors.zig");

pub fn cleanToken(token: []const u8) []const u8 {
    var t = std.mem.trim(u8, token, " \t\r\n");
    t = std.mem.trim(u8, t, "\"'");
    if (std.ascii.eqlIgnoreCase(t, "true") or std.ascii.eqlIgnoreCase(t, "false")) {
        return "";
    }
    const prefixes = [_][]const u8{ "Bearer ", "bearer ", "token ", "Token " };
    for (prefixes) |p| {
        if (std.mem.startsWith(u8, t, p)) {
            t = t[p.len..];
            break;
        }
    }
    return std.mem.trim(u8, t, " \t\r\n");
}

pub fn maskToken(allocator: std.mem.Allocator, token: []const u8) ![]u8 {
    const t = cleanToken(token);
    if (t.len == 0) {
        return try allocator.dupe(u8, "none");
    }
    if (t.len <= 8) {
        return try std.fmt.allocPrint(allocator, "*** (len: {d})", .{t.len});
    }
    return try std.fmt.allocPrint(allocator, "{s}...{s} (len: {d})", .{ t[0..4], t[t.len - 4 ..], t.len });
}

pub const Client = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    global_token: []const u8,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, global_token: []const u8) Client {
        return .{
            .allocator = allocator,
            .io = io,
            .global_token = cleanToken(global_token),
        };
    }

    pub fn getUserLanguages(
        self: *Client,
        username: []const u8,
        token: []const u8,
        excluded_repos: []const []const u8,
    ) !*models.UserStats {
        const clean_user = std.mem.trim(u8, username, " \t\r\n");
        if (clean_user.len == 0 or std.ascii.eqlIgnoreCase(clean_user, "demo")) {
            return self.getDemoStats();
        }

        var auth_token = cleanToken(token);
        if (auth_token.len == 0) {
            auth_token = self.global_token;
        }

        return try self.fetchGraphQL(clean_user, auth_token, excluded_repos);
    }

    fn sortDescBySize(_: void, a: models.LanguageStat, b: models.LanguageStat) bool {
        return a.size > b.size;
    }

    pub fn fetchGraphQL(
        self: *Client,
        username: []const u8,
        token: []const u8,
        excluded_repos: []const []const u8,
    ) !*models.UserStats {
        var client = std.http.Client{ .allocator = self.allocator, .io = self.io };
        defer client.deinit();

        var response_allocating = std.Io.Writer.Allocating.init(self.allocator);
        defer response_allocating.deinit();

        const uri = try std.Uri.parse("https://api.github.com/graphql");

        // Construct JSON payload
        const query_str =
            \\query($login: String!) {
            \\    user(login: $login) {
            \\        repositories(affiliations: [OWNER, ORGANIZATION_MEMBER], isFork: false, first: 100, orderBy: {field: PUSHED_AT, direction: DESC}) {
            \\            pageInfo {
            \\                hasNextPage
            \\                endCursor
            \\            }
            \\            nodes {
            \\                name
            \\                isFork
            \\                languages(first: 20, orderBy: {field: SIZE, direction: DESC}) {
            \\                    edges {
            \\                        size
            \\                        node {
            \\                            name
            \\                            color
            \\                        }
            \\                    }
            \\                }
            \\            }
            \\        }
            \\    }
            \\}
        ;

        const Payload = struct {
            query: []const u8,
            variables: struct {
                login: []const u8,
            },
        };
        const payload_obj = Payload{
            .query = query_str,
            .variables = .{ .login = username },
        };
        const payload = try std.json.Stringify.valueAlloc(self.allocator, payload_obj, .{});
        defer self.allocator.free(payload);

        // Set up headers
        var auth_header_buf: [256]u8 = undefined;
        var extra_headers: [3]std.http.Header = undefined;
        var header_count: usize = 0;

        if (token.len > 0) {
            const auth_header = try std.fmt.bufPrint(&auth_header_buf, "Bearer {s}", .{token});
            extra_headers[header_count] = .{ .name = "Authorization", .value = auth_header };
            header_count += 1;
        }
        extra_headers[header_count] = .{ .name = "User-Agent", .value = "git-stats-card-generator" };
        header_count += 1;
        extra_headers[header_count] = .{ .name = "Content-Type", .value = "application/json" };
        header_count += 1;

        const res = client.fetch(.{
            .location = .{ .uri = uri },
            .method = .POST,
            .payload = payload,
            .extra_headers = extra_headers[0..header_count],
            .response_writer = &response_allocating.writer,
        }) catch |err| {
            std.debug.print("❌ Network error connecting to GitHub: {}\n", .{err});
            return err;
        };

        const body = response_allocating.written();

        if (res.status == .unauthorized) {
            const masked = try maskToken(self.allocator, token);
            defer self.allocator.free(masked);
            std.debug.print("❌ GitHub authentication failed (HTTP 401 Bad credentials) using token {s}.\nPlease update your GH_TOKEN repository secret in GitHub Settings -> Secrets and variables -> Actions\n", .{masked});
            return error.AuthenticationFailed;
        }

        if (res.status != .ok) {
            std.debug.print("❌ GitHub GraphQL error (HTTP {d}): {s}\n", .{ @intFromEnum(res.status), body });
            return error.GitHubApiError;
        }

        const GqlLanguageNode = struct {
            name: []const u8,
            color: ?[]const u8 = null,
        };
        const GqlEdge = struct {
            size: u64,
            node: GqlLanguageNode,
        };
        const GqlRepo = struct {
            name: []const u8,
            isFork: bool = false,
            languages: struct {
                edges: []const GqlEdge,
            },
        };
        const GqlData = struct {
            user: ?struct {
                repositories: struct {
                    nodes: []const GqlRepo,
                },
            } = null,
        };
        const GqlError = struct {
            message: []const u8,
        };
        const GqlResponse = struct {
            data: ?GqlData = null,
            errors: ?[]const GqlError = null,
        };

        const parsed = try std.json.parseFromSlice(GqlResponse, self.allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (parsed.value.errors) |errs| {
            if (errs.len > 0) {
                std.debug.print("❌ GraphQL error: {s}\n", .{errs[0].message});
                return error.GraphQLError;
            }
        }

        const user_data = parsed.value.data orelse return error.NoUserData;
        const repos = if (user_data.user) |u| u.repositories.nodes else return error.UserNotFound;

        var lang_totals: std.StringHashMap(u64) = std.StringHashMap(u64).init(self.allocator);
        defer lang_totals.deinit();

        var lang_colors: std.StringHashMap([]const u8) = std.StringHashMap([]const u8).init(self.allocator);
        defer lang_colors.deinit();

        var total_bytes: u64 = 0;

        for (repos) |repo| {
            if (repo.isFork) continue;

            // Check exclusion
            var excluded = false;
            for (excluded_repos) |ex| {
                if (std.ascii.eqlIgnoreCase(repo.name, std.mem.trim(u8, ex, " \t\r\n"))) {
                    excluded = true;
                    break;
                }
            }
            if (excluded) continue;

            for (repo.languages.edges) |edge| {
                const name = edge.node.name;
                const size = edge.size;
                const color = colors.getLanguageColor(name, edge.node.color);

                const prev_size = lang_totals.get(name) orelse 0;
                try lang_totals.put(name, prev_size + size);
                total_bytes += size;

                if (!lang_colors.contains(name)) {
                    try lang_colors.put(name, color);
                }
            }
        }

        var list: std.ArrayList(models.LanguageStat) = .empty;
        defer list.deinit(self.allocator);

        var iter = lang_totals.iterator();
        while (iter.next()) |entry| {
            const name = entry.key_ptr.*;
            const size = entry.value_ptr.*;
            const color = lang_colors.get(name) orelse colors.default_language_color;
            const pct = if (total_bytes > 0)
                (@as(f64, @floatFromInt(size)) / @as(f64, @floatFromInt(total_bytes))) * 100.0
            else
                0.0;

            try list.append(self.allocator, .{
                .name = try self.allocator.dupe(u8, name),
                .color = try self.allocator.dupe(u8, color),
                .size = size,
                .percentage = pct,
            });
        }

        std.mem.sort(models.LanguageStat, list.items, {}, sortDescBySize);

        const stats_ptr = try self.allocator.create(models.UserStats);
        stats_ptr.* = .{
            .username = try self.allocator.dupe(u8, username),
            .total_bytes = total_bytes,
            .languages = try list.toOwnedSlice(self.allocator),
        };
        return stats_ptr;
    }

    pub fn getDemoStats(self: *Client) !*models.UserStats {
        const raw = [_]struct { name: []const u8, size: u64 }{
            .{ .name = "TypeScript", .size = 387300 },
            .{ .name = "Rust", .size = 202900 },
            .{ .name = "Go", .size = 168200 },
            .{ .name = "Java", .size = 142400 },
            .{ .name = "Python", .size = 63500 },
            .{ .name = "Haskell", .size = 35700 },
            .{ .name = "C++", .size = 28000 },
            .{ .name = "Shell", .size = 19500 },
            .{ .name = "Docker", .size = 14200 },
            .{ .name = "HTML", .size = 12100 },
            .{ .name = "CSS", .size = 9800 },
            .{ .name = "SQL", .size = 7500 },
            .{ .name = "Lua", .size = 5200 },
            .{ .name = "Dart", .size = 3800 },
            .{ .name = "Kotlin", .size = 3200 },
            .{ .name = "Swift", .size = 2900 },
            .{ .name = "C#", .size = 2400 },
            .{ .name = "Ruby", .size = 2100 },
            .{ .name = "PHP", .size = 1800 },
            .{ .name = "Vue", .size = 1500 },
            .{ .name = "Svelte", .size = 1200 },
            .{ .name = "Zig", .size = 1000 },
            .{ .name = "Elixir", .size = 850 },
            .{ .name = "Scala", .size = 700 },
        };

        var total: u64 = 0;
        for (raw) |item| total += item.size;

        var list: std.ArrayList(models.LanguageStat) = .empty;
        defer list.deinit(self.allocator);

        for (raw) |item| {
            const pct = if (total > 0)
                (@as(f64, @floatFromInt(item.size)) / @as(f64, @floatFromInt(total))) * 100.0
            else
                0.0;
            const color = colors.getLanguageColor(item.name, null);
            try list.append(self.allocator, .{
                .name = try self.allocator.dupe(u8, item.name),
                .color = try self.allocator.dupe(u8, color),
                .size = item.size,
                .percentage = pct,
            });
        }

        const stats_ptr = try self.allocator.create(models.UserStats);
        stats_ptr.* = .{
            .username = try self.allocator.dupe(u8, "demo"),
            .total_bytes = total,
            .languages = try list.toOwnedSlice(self.allocator),
        };
        return stats_ptr;
    }
};
