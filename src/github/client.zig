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

    pub fn executeGraphQL(
        self: *Client,
        payload_json: []const u8,
        token: []const u8,
    ) ![]u8 {
        var client = std.http.Client{ .allocator = self.allocator, .io = self.io };
        defer client.deinit();

        var response_allocating = std.Io.Writer.Allocating.init(self.allocator);
        defer response_allocating.deinit();

        const uri = try std.Uri.parse("https://api.github.com/graphql");

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
            .payload = payload_json,
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

        return try self.allocator.dupe(u8, body);
    }

    pub fn fetchGraphQL(
        self: *Client,
        username: []const u8,
        token: []const u8,
        excluded_repos: []const []const u8,
    ) !*models.UserStats {
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

        const body = try self.executeGraphQL(payload, token);
        defer self.allocator.free(body);

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

    pub fn getStreakStats(
        self: *Client,
        username: []const u8,
        token: []const u8,
    ) !*models.StreakStats {
        const clean_user = std.mem.trim(u8, username, " \t\r\n");
        if (clean_user.len == 0 or std.ascii.eqlIgnoreCase(clean_user, "demo")) {
            return self.getDemoStreakStats();
        }

        var auth_token = cleanToken(token);
        if (auth_token.len == 0) {
            auth_token = self.global_token;
        }

        return try self.fetchStreakGraphQL(clean_user, auth_token);
    }

    pub fn fetchStreakGraphQL(
        self: *Client,
        username: []const u8,
        token: []const u8,
    ) !*models.StreakStats {
        // Step 1: Query contributionYears and user createdAt
        const query_years =
            \\query($login: String!) {
            \\    user(login: $login) {
            \\        createdAt
            \\        contributionsCollection {
            \\            contributionYears
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
            .query = query_years,
            .variables = .{ .login = username },
        };
        const payload = try std.json.Stringify.valueAlloc(self.allocator, payload_obj, .{});
        defer self.allocator.free(payload);

        const body = try self.executeGraphQL(payload, token);
        defer self.allocator.free(body);

        const YearsGql = struct {
            data: ?struct {
                user: ?struct {
                    createdAt: []const u8,
                    contributionsCollection: struct {
                        contributionYears: []const i64,
                    },
                } = null,
            } = null,
            errors: ?[]const struct { message: []const u8 } = null,
        };

        const parsed_years = try std.json.parseFromSlice(YearsGql, self.allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed_years.deinit();

        if (parsed_years.value.errors) |errs| {
            if (errs.len > 0) {
                std.debug.print("❌ GraphQL error: {s}\n", .{errs[0].message});
                return error.GraphQLError;
            }
        }

        const user_data = parsed_years.value.data orelse return error.NoUserData;
        const u = user_data.user orelse return error.UserNotFound;
        const years_raw = u.contributionsCollection.contributionYears;

        if (years_raw.len == 0) {
            return try self.getDemoStreakStats();
        }

        const years = try self.allocator.alloc(i64, years_raw.len);
        defer self.allocator.free(years);
        @memcpy(years, years_raw);
        std.mem.sort(i64, years, {}, std.sort.asc(i64));

        // Step 2: Query multi-year contribution calendars with aliases
        var q_buf = std.Io.Writer.Allocating.init(self.allocator);
        defer q_buf.deinit();

        try q_buf.writer.print("query {{\n  user(login: \"{s}\") {{\n", .{username});
        for (years) |yr| {
            if (yr == years[years.len - 1]) {
                // Current year: omit 'to' so GitHub only returns calendar days up to today!
                try q_buf.writer.print(
                    \\    y{d}: contributionsCollection(from: "{d}-01-01T00:00:00Z") {{
                    \\      contributionCalendar {{
                    \\        totalContributions
                    \\        weeks {{
                    \\          contributionDays {{
                    \\            date
                    \\            contributionCount
                    \\          }}
                    \\        }}
                    \\      }}
                    \\    }}
                    \\
                , .{ yr, yr });
            } else {
                // Past years: query full calendar year
                try q_buf.writer.print(
                    \\    y{d}: contributionsCollection(from: "{d}-01-01T00:00:00Z", to: "{d}-12-31T23:59:59Z") {{
                    \\      contributionCalendar {{
                    \\        totalContributions
                    \\        weeks {{
                    \\          contributionDays {{
                    \\            date
                    \\            contributionCount
                    \\          }}
                    \\        }}
                    \\      }}
                    \\    }}
                    \\
                , .{ yr, yr, yr });
            }
        }
        try q_buf.writer.print("  }}\n}}\n", .{});

        const CalPayload = struct {
            query: []const u8,
        };
        const cal_payload_obj = CalPayload{ .query = q_buf.written() };
        const cal_payload = try std.json.Stringify.valueAlloc(self.allocator, cal_payload_obj, .{});
        defer self.allocator.free(cal_payload);

        const cal_body = try self.executeGraphQL(cal_payload, token);
        defer self.allocator.free(cal_body);

        const parsed_cal = try std.json.parseFromSlice(std.json.Value, self.allocator, cal_body, .{});
        defer parsed_cal.deinit();

        const data_val = parsed_cal.value.object.get("data") orelse return error.NoData;
        const user_val = data_val.object.get("user") orelse return error.UserNotFound;

        var all_days: std.ArrayList(models.ContributionDay) = .empty;
        defer all_days.deinit(self.allocator);

        for (years) |yr| {
            var key_buf: [16]u8 = undefined;
            const key = try std.fmt.bufPrint(&key_buf, "y{d}", .{yr});
            const yr_val = user_val.object.get(key) orelse continue;
            const cal_val = yr_val.object.get("contributionCalendar") orelse continue;
            const weeks_val = cal_val.object.get("weeks") orelse continue;

            for (weeks_val.array.items) |week_val| {
                const days_val = week_val.object.get("contributionDays") orelse continue;
                for (days_val.array.items) |day_val| {
                    const date_val = day_val.object.get("date") orelse continue;
                    const count_val = day_val.object.get("contributionCount") orelse continue;

                    const d_str = date_val.string;
                    const cnt: u32 = switch (count_val) {
                        .integer => |iv| if (iv > 0) @intCast(iv) else 0,
                        else => 0,
                    };

                    // Deduplicate
                    if (all_days.items.len > 0 and std.mem.eql(u8, all_days.items[all_days.items.len - 1].date, d_str)) {
                        if (cnt > all_days.items[all_days.items.len - 1].count) {
                            all_days.items[all_days.items.len - 1].count = cnt;
                        }
                        continue;
                    }

                    try all_days.append(self.allocator, .{
                        .date = try self.allocator.dupe(u8, d_str),
                        .count = cnt,
                    });
                }
            }
        }

        var total_contributions: u64 = 0;
        var first_contrib_idx: ?usize = null;
        var latest_contrib_idx: ?usize = null;

        for (all_days.items, 0..) |day, i| {
            total_contributions += day.count;
            if (day.count > 0) {
                if (first_contrib_idx == null) first_contrib_idx = i;
                latest_contrib_idx = i;
            }
        }

        // Compute today's date from system clock
        const now_ts = std.Io.Timestamp.now(self.io, .real);
        const now_sec: i64 = @intCast(@divFloor(now_ts.nanoseconds, std.time.ns_per_s));
        const epoch_sec = std.time.epoch.EpochSeconds{ .secs = @intCast(@max(0, now_sec)) };
        const epoch_day = epoch_sec.getEpochDay();
        const year_day = epoch_day.calculateYearDay();
        const month_day = year_day.calculateMonthDay();

        var today_buf: [16]u8 = undefined;
        const today_date = try std.fmt.bufPrint(&today_buf, "{d:0>4}-{d:0>2}-{d:0>2}", .{
            year_day.year,
            month_day.month.numeric(),
            month_day.day_index + 1,
        });

        // Filter all_days to only include days up to today (or latest contribution day)
        var valid_len: usize = 0;
        for (all_days.items) |d| {
            const allow_latest = if (latest_contrib_idx) |l_idx|
                std.mem.order(u8, d.date, all_days.items[l_idx].date) != .gt
            else
                false;

            if (std.mem.order(u8, d.date, today_date) != .gt or allow_latest) {
                valid_len += 1;
            } else {
                break;
            }
        }
        const active_days = all_days.items[0..valid_len];
        const n = active_days.len;

        // Current streak calculation
        var current_streak: u32 = 0;
        var current_start_idx: usize = 0;
        var current_end_idx: usize = 0;
        var is_active: bool = false;

        if (n > 0) {
            if (active_days[n - 1].count > 0) {
                is_active = true;
                current_end_idx = n - 1;
                var idx: isize = @intCast(n - 1);
                while (idx >= 0 and active_days[@intCast(idx)].count > 0) : (idx -= 1) {
                    current_streak += 1;
                }
                current_start_idx = @intCast(idx + 1);
            } else if (n >= 2 and active_days[n - 2].count > 0) {
                is_active = true;
                current_end_idx = n - 2;
                var idx: isize = @intCast(n - 2);
                while (idx >= 0 and active_days[@intCast(idx)].count > 0) : (idx -= 1) {
                    current_streak += 1;
                }
                current_start_idx = @intCast(idx + 1);
            }
        }

        // Longest streak calculation
        var longest_streak: u32 = 0;
        var longest_start_idx: usize = 0;
        var longest_end_idx: usize = 0;

        var run_streak: u32 = 0;
        var run_start_idx: usize = 0;

        for (active_days, 0..) |day, i| {
            if (day.count > 0) {
                if (run_streak == 0) {
                    run_start_idx = i;
                }
                run_streak += 1;
                if (run_streak > longest_streak) {
                    longest_streak = run_streak;
                    longest_start_idx = run_start_idx;
                    longest_end_idx = i;
                }
            } else {
                run_streak = 0;
            }
        }

        // 14-day momentum sparkline (last 14 days ending today)
        var recent_14: [14]u32 = [_]u32{0} ** 14;
        var max_14: u32 = 0;
        var total_14: u32 = 0;

        if (n >= 14) {
            const start_14 = n - 14;
            for (0..14) |j| {
                const c = active_days[start_14 + j].count;
                recent_14[j] = c;
                if (c > max_14) max_14 = c;
                total_14 += c;
            }
        } else {
            for (active_days, 0..) |d, j| {
                if (j >= 14) break;
                recent_14[j] = d.count;
                if (d.count > max_14) max_14 = d.count;
                total_14 += d.count;
            }
        }

        const first_date = if (first_contrib_idx) |idx|
            try formatHumanDate(self.allocator, all_days.items[idx].date)
        else
            try self.allocator.dupe(u8, "Oct 7, 2022");

        const latest_date = try self.allocator.dupe(u8, "Present");

        const cur_start_date = if (current_streak > 0)
            try formatHumanDate(self.allocator, active_days[current_start_idx].date)
        else
            try self.allocator.dupe(u8, "None");

        const cur_end_date = if (current_streak > 0)
            try formatHumanDateShort(self.allocator, active_days[current_end_idx].date)
        else
            try self.allocator.dupe(u8, "None");

        const long_start_date = if (longest_streak > 0)
            try formatHumanDate(self.allocator, active_days[longest_start_idx].date)
        else
            try self.allocator.dupe(u8, "None");

        const long_end_date = if (longest_streak > 0)
            try formatHumanDateShort(self.allocator, active_days[longest_end_idx].date)
        else
            try self.allocator.dupe(u8, "None");

        const streak_ptr = try self.allocator.create(models.StreakStats);
        streak_ptr.* = .{
            .username = try self.allocator.dupe(u8, username),
            .total_contributions = total_contributions,
            .first_contribution_date = first_date,
            .latest_contribution_date = latest_date,
            .current_streak = current_streak,
            .current_streak_start = cur_start_date,
            .current_streak_end = cur_end_date,
            .is_streak_active = is_active,
            .longest_streak = longest_streak,
            .longest_streak_start = long_start_date,
            .longest_streak_end = long_end_date,
            .recent_14_days = recent_14,
            .max_14_day_count = max_14,
            .total_14_day_count = total_14,
        };
        return streak_ptr;
    }

    pub fn getDemoStreakStats(self: *Client) !*models.StreakStats {
        const streak_ptr = try self.allocator.create(models.StreakStats);
        streak_ptr.* = .{
            .username = try self.allocator.dupe(u8, "adityapandeydev"),
            .total_contributions = 2026,
            .first_contribution_date = try self.allocator.dupe(u8, "Oct 7, 2022"),
            .latest_contribution_date = try self.allocator.dupe(u8, "Present"),
            .current_streak = 551,
            .current_streak_start = try self.allocator.dupe(u8, "Mar 28, 2025"),
            .current_streak_end = try self.allocator.dupe(u8, "Sep 29"),
            .is_streak_active = true,
            .longest_streak = 551,
            .longest_streak_start = try self.allocator.dupe(u8, "Mar 28, 2025"),
            .longest_streak_end = try self.allocator.dupe(u8, "Sep 29"),
            .recent_14_days = [_]u32{ 4, 7, 2, 8, 12, 5, 9, 3, 6, 11, 8, 4, 7, 10 },
            .max_14_day_count = 12,
            .total_14_day_count = 96,
        };
        return streak_ptr;
    }

    pub fn getOverallStats(
        self: *Client,
        username: []const u8,
        token: []const u8,
        timeframe: []const u8,
    ) !*models.OverallStats {
        const clean_user = std.mem.trim(u8, username, " \t\r\n");
        if (clean_user.len == 0 or std.ascii.eqlIgnoreCase(clean_user, "demo")) {
            return self.getDemoOverallStats();
        }

        var auth_token = cleanToken(token);
        if (auth_token.len == 0) {
            auth_token = self.global_token;
        }

        return try self.fetchOverallStatsGraphQL(clean_user, auth_token, timeframe);
    }

    pub fn getDemoOverallStats(self: *Client) !*models.OverallStats {
        const rating = models.calculateDeveloperRating(2030, 32, 28, 16, 48, 18);
        const stats_ptr = try self.allocator.create(models.OverallStats);
        stats_ptr.* = .{
            .username = try self.allocator.dupe(u8, "adityapandeydev"),
            .name = try self.allocator.dupe(u8, "Aditya Pandey"),
            .timeframe = try self.allocator.dupe(u8, "all-time"),
            .total_commits = 2030,
            .total_prs = 32,
            .merged_prs = 28,
            .total_issues = 22,
            .closed_issues = 16,
            .total_stars = 48,
            .contributed_repos = 18,
            .rating = rating,
        };
        return stats_ptr;
    }

    pub fn fetchOverallStatsGraphQL(
        self: *Client,
        username: []const u8,
        token: []const u8,
        timeframe: []const u8,
    ) !*models.OverallStats {
        const query_main =
            \\query($login: String!) {
            \\  user(login: $login) {
            \\    name
            \\    login
            \\    repositories(first: 100, ownerAffiliations: OWNER, isFork: false) {
            \\      totalCount
            \\      nodes {
            \\        stargazerCount
            \\      }
            \\    }
            \\    contributionsCollection {
            \\      contributionYears
            \\      totalCommitContributions
            \\      restrictedContributionsCount
            \\      totalPullRequestContributions
            \\      totalIssueContributions
            \\      totalRepositoriesWithContributedCommits
            \\    }
            \\    mergedPRs: pullRequests(states: MERGED) {
            \\      totalCount
            \\    }
            \\    allPRs: pullRequests {
            \\      totalCount
            \\    }
            \\    closedIssues: issues(states: CLOSED) {
            \\      totalCount
            \\    }
            \\    allIssues: issues {
            \\      totalCount
            \\    }
            \\  }
            \\}
        ;

        const Payload = struct {
            query: []const u8,
            variables: struct { login: []const u8 },
        };
        const payload_obj = Payload{
            .query = query_main,
            .variables = .{ .login = username },
        };
        const payload = try std.json.Stringify.valueAlloc(self.allocator, payload_obj, .{});
        defer self.allocator.free(payload);

        const body = try self.executeGraphQL(payload, token);
        defer self.allocator.free(body);

        const parsed = try std.json.parseFromSlice(std.json.Value, self.allocator, body, .{});
        defer parsed.deinit();

        const data_val = parsed.value.object.get("data") orelse return error.NoData;
        const user_val = data_val.object.get("user") orelse return error.UserNotFound;

        const name_val = user_val.object.get("name");
        const resolved_name = if (name_val != null and name_val.? == .string and name_val.?.string.len > 0)
            name_val.?.string
        else
            username;

        // Repositories & Stars
        var total_stars: u64 = 0;
        var owned_repos_count: u64 = 0;
        if (user_val.object.get("repositories")) |repos_val| {
            if (repos_val.object.get("totalCount")) |tc| {
                owned_repos_count = @as(u64, @intCast(@max(0, tc.integer)));
            }
            if (repos_val.object.get("nodes")) |nodes_val| {
                for (nodes_val.array.items) |node| {
                    if (node.object.get("stargazerCount")) |sc| {
                        total_stars += @as(u64, @intCast(@max(0, sc.integer)));
                    }
                }
            }
        }

        // PRs & Issues
        var merged_prs: u64 = 0;
        if (user_val.object.get("mergedPRs")) |pr_val| {
            if (pr_val.object.get("totalCount")) |tc| {
                merged_prs = @as(u64, @intCast(@max(0, tc.integer)));
            }
        }

        var all_prs: u64 = 0;
        if (user_val.object.get("allPRs")) |pr_val| {
            if (pr_val.object.get("totalCount")) |tc| {
                all_prs = @as(u64, @intCast(@max(0, tc.integer)));
            }
        }

        var closed_issues: u64 = 0;
        if (user_val.object.get("closedIssues")) |iss_val| {
            if (iss_val.object.get("totalCount")) |tc| {
                closed_issues = @as(u64, @intCast(@max(0, tc.integer)));
            }
        }

        var all_issues: u64 = 0;
        if (user_val.object.get("allIssues")) |iss_val| {
            if (iss_val.object.get("totalCount")) |tc| {
                all_issues = @as(u64, @intCast(@max(0, tc.integer)));
            }
        }

        // Collection contributions
        var collection_commits: u64 = 0;
        var collection_pr_contribs: u64 = 0;
        var collection_issue_contribs: u64 = 0;
        var collection_contributed_repos: u64 = 0;
        var years_list: std.ArrayList(i64) = .empty;
        defer years_list.deinit(self.allocator);

        if (user_val.object.get("contributionsCollection")) |col_val| {
            if (col_val.object.get("totalCommitContributions")) |cc| {
                collection_commits += @as(u64, @intCast(@max(0, cc.integer)));
            }
            if (col_val.object.get("restrictedContributionsCount")) |rc| {
                collection_commits += @as(u64, @intCast(@max(0, rc.integer)));
            }
            if (col_val.object.get("totalPullRequestContributions")) |prc| {
                collection_pr_contribs = @as(u64, @intCast(@max(0, prc.integer)));
            }
            if (col_val.object.get("totalIssueContributions")) |ic| {
                collection_issue_contribs = @as(u64, @intCast(@max(0, ic.integer)));
            }
            if (col_val.object.get("totalRepositoriesWithContributedCommits")) |trc| {
                collection_contributed_repos = @as(u64, @intCast(@max(0, trc.integer)));
            }
            if (col_val.object.get("contributionYears")) |cy| {
                for (cy.array.items) |y_item| {
                    try years_list.append(self.allocator, y_item.integer);
                }
            }
        }

        merged_prs = @max(merged_prs, collection_pr_contribs);
        all_prs = @max(all_prs, merged_prs);
        closed_issues = @max(closed_issues, collection_issue_contribs);
        all_issues = @max(all_issues, closed_issues);
        const contributed_repos = @max(collection_contributed_repos, owned_repos_count);

        var total_commits = collection_commits;

        // If all-time requested and user has multiple active contribution years, batch all years
        const is_all_time = !std.mem.eql(u8, timeframe, "this-year");
        if (is_all_time and years_list.items.len > 1) {
            var q_buf = std.Io.Writer.Allocating.init(self.allocator);
            defer q_buf.deinit();

            try q_buf.writer.print("query {{\n  user(login: \"{s}\") {{\n", .{username});
            for (years_list.items) |yr| {
                try q_buf.writer.print(
                    \\    y{d}: contributionsCollection(from: "{d}-01-01T00:00:00Z", to: "{d}-12-31T23:59:59Z") {{
                    \\      totalCommitContributions
                    \\      restrictedContributionsCount
                    \\    }}
                    \\
                , .{ yr, yr, yr });
            }
            try q_buf.writer.print("  }}\n}}\n", .{});

            const MultiPayload = struct { query: []const u8 };
            const multi_payload_obj = MultiPayload{ .query = q_buf.written() };
            const multi_payload = std.json.Stringify.valueAlloc(self.allocator, multi_payload_obj, .{}) catch null;
            if (multi_payload) |mp| {
                defer self.allocator.free(mp);
                const multi_body = self.executeGraphQL(mp, token) catch null;
                if (multi_body) |mb| {
                    defer self.allocator.free(mb);
                    const parsed_multi = std.json.parseFromSlice(std.json.Value, self.allocator, mb, .{}) catch null;
                    if (parsed_multi) |pm| {
                        defer pm.deinit();
                        if (pm.value.object.get("data")) |m_data| {
                            if (m_data.object.get("user")) |m_user| {
                                var sum_multi: u64 = 0;
                                for (years_list.items) |yr| {
                                    var k_buf: [16]u8 = undefined;
                                    const k = std.fmt.bufPrint(&k_buf, "y{d}", .{yr}) catch continue;
                                    if (m_user.object.get(k)) |y_obj| {
                                        if (y_obj.object.get("totalCommitContributions")) |tc| {
                                            sum_multi += @as(u64, @intCast(@max(0, tc.integer)));
                                        }
                                        if (y_obj.object.get("restrictedContributionsCount")) |rc| {
                                            sum_multi += @as(u64, @intCast(@max(0, rc.integer)));
                                        }
                                    }
                                }
                                if (sum_multi > 0) {
                                    total_commits = sum_multi;
                                }
                            }
                        }
                    }
                }
            }
        }

        const rating = models.calculateDeveloperRating(
            total_commits,
            all_prs,
            merged_prs,
            closed_issues,
            total_stars,
            contributed_repos,
        );

        const stats_ptr = try self.allocator.create(models.OverallStats);
        stats_ptr.* = .{
            .username = try self.allocator.dupe(u8, username),
            .name = try self.allocator.dupe(u8, resolved_name),
            .timeframe = try self.allocator.dupe(u8, if (is_all_time) "all-time" else "this-year"),
            .total_commits = total_commits,
            .total_prs = all_prs,
            .merged_prs = merged_prs,
            .total_issues = all_issues,
            .closed_issues = closed_issues,
            .total_stars = total_stars,
            .contributed_repos = contributed_repos,
            .rating = rating,
        };

        return stats_ptr;
    }
};

pub fn parseYmdToDays(ymd: []const u8) ?i64 {
    if (ymd.len < 10) return null;
    const y = std.fmt.parseInt(i64, ymd[0..4], 10) catch return null;
    const m = std.fmt.parseInt(i64, ymd[5..7], 10) catch return null;
    const d = std.fmt.parseInt(i64, ymd[8..10], 10) catch return null;

    const y_adj = if (m <= 2) y - 1 else y;
    const era = @divFloor(y_adj, 400);
    const yoe = y_adj - era * 400;
    const m_adj = if (m > 2) m - 3 else m + 9;
    const doy = @divFloor(153 * m_adj + 2, 5) + d - 1;
    const doe = yoe * 365 + @divFloor(yoe, 4) - @divFloor(yoe, 100) + doy;
    return era * 146097 + doe - 719468;
}

pub fn formatHumanDate(allocator: std.mem.Allocator, ymd: []const u8) ![]u8 {
    if (ymd.len < 10) return try allocator.dupe(u8, ymd);
    const months = [_][]const u8{
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    };
    const month_num = std.fmt.parseInt(usize, ymd[5..7], 10) catch return try allocator.dupe(u8, ymd);
    if (month_num < 1 or month_num > 12) return try allocator.dupe(u8, ymd);
    const month_name = months[month_num - 1];
    const day_num = std.fmt.parseInt(u32, ymd[8..10], 10) catch return try allocator.dupe(u8, ymd);
    const year_str = ymd[0..4];
    return try std.fmt.allocPrint(allocator, "{s} {d}, {s}", .{ month_name, day_num, year_str });
}

pub fn formatHumanDateShort(allocator: std.mem.Allocator, ymd: []const u8) ![]u8 {
    if (ymd.len < 10) return try allocator.dupe(u8, ymd);
    const months = [_][]const u8{
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    };
    const month_num = std.fmt.parseInt(usize, ymd[5..7], 10) catch return try allocator.dupe(u8, ymd);
    if (month_num < 1 or month_num > 12) return try allocator.dupe(u8, ymd);
    const month_name = months[month_num - 1];
    const day_num = std.fmt.parseInt(u32, ymd[8..10], 10) catch return try allocator.dupe(u8, ymd);
    return try std.fmt.allocPrint(allocator, "{s} {d}", .{ month_name, day_num });
}

