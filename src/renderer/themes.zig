const std = @import("std");

/// Theme defines the visual styling of the SVG card.
pub const Theme = struct {
    name: []const u8,
    label: []const u8,
    bg_color: []const u8,
    title_color: []const u8,
    text_color: []const u8,
    muted_color: []const u8,
    border_color: []const u8,
    bar_bg_color: []const u8,
    accent_color: []const u8,
    border_radius: f64,
};

pub const tokyonight: Theme = .{
    .name = "tokyonight",
    .label = "Tokyo Night",
    .bg_color = "#1a1b27",
    .title_color = "#70a5fd",
    .text_color = "#c0caf5",
    .muted_color = "#7982a9",
    .border_color = "#1f2335",
    .bar_bg_color = "#212337",
    .accent_color = "#70a5fd",
    .border_radius = 4.5,
};

pub const github_dark: Theme = .{
    .name = "github_dark",
    .label = "GitHub Dark",
    .bg_color = "#0d1117",
    .title_color = "#58a6ff",
    .text_color = "#c9d1d9",
    .muted_color = "#8b949e",
    .border_color = "#30363d",
    .bar_bg_color = "#161b22",
    .accent_color = "#1f6feb",
    .border_radius = 4.5,
};

pub const dracula: Theme = .{
    .name = "dracula",
    .label = "Dracula",
    .bg_color = "#282a36",
    .title_color = "#8be9fd",
    .text_color = "#f8f8f2",
    .muted_color = "#6272a4",
    .border_color = "#44475a",
    .bar_bg_color = "#1e1f29",
    .accent_color = "#bd93f9",
    .border_radius = 4.5,
};

pub const catppuccin: Theme = .{
    .name = "catppuccin",
    .label = "Catppuccin Mocha",
    .bg_color = "#1e1e2e",
    .title_color = "#89b4fa",
    .text_color = "#cdd6f4",
    .muted_color = "#a6adc8",
    .border_color = "#313244",
    .bar_bg_color = "#181825",
    .accent_color = "#cba6f7",
    .border_radius = 4.5,
};

pub const nord: Theme = .{
    .name = "nord",
    .label = "Nord",
    .bg_color = "#2e3440",
    .title_color = "#88c0d0",
    .text_color = "#eceff4",
    .muted_color = "#4c566a",
    .border_color = "#3b4252",
    .bar_bg_color = "#242933",
    .accent_color = "#81a1c1",
    .border_radius = 4.5,
};

pub const synthwave: Theme = .{
    .name = "synthwave",
    .label = "Synthwave",
    .bg_color = "#1a102f",
    .title_color = "#f92aad",
    .text_color = "#2de2e6",
    .muted_color = "#725ac1",
    .border_color = "#ff007f",
    .bar_bg_color = "#120924",
    .accent_color = "#05d9e8",
    .border_radius = 4.5,
};

pub const onedark: Theme = .{
    .name = "onedark",
    .label = "One Dark",
    .bg_color = "#282c34",
    .title_color = "#61afef",
    .text_color = "#abb2bf",
    .muted_color = "#5c6370",
    .border_color = "#3e4451",
    .bar_bg_color = "#21252b",
    .accent_color = "#98c379",
    .border_radius = 4.5,
};

pub const radical: Theme = .{
    .name = "radical",
    .label = "Radical",
    .bg_color = "#141321",
    .title_color = "#fe428e",
    .text_color = "#a9fef7",
    .muted_color = "#726e97",
    .border_color = "#2a2b3d",
    .bar_bg_color = "#0f0e1a",
    .accent_color = "#f8d847",
    .border_radius = 4.5,
};

pub const midnight: Theme = .{
    .name = "midnight",
    .label = "OLED Midnight",
    .bg_color = "#050508",
    .title_color = "#6366f1",
    .text_color = "#f1f5f9",
    .muted_color = "#64748b",
    .border_color = "#1e1e2f",
    .bar_bg_color = "#0f0f17",
    .accent_color = "#818cf8",
    .border_radius = 4.5,
};

pub const github_light: Theme = .{
    .name = "github_light",
    .label = "GitHub Light",
    .bg_color = "#ffffff",
    .title_color = "#0969da",
    .text_color = "#24292f",
    .muted_color = "#57606a",
    .border_color = "#d0d7de",
    .bar_bg_color = "#eaeef2",
    .accent_color = "#0969da",
    .border_radius = 4.5,
};

pub fn getTheme(name: []const u8) Theme {
    var buf: [64]u8 = undefined;
    const len = @min(name.len, buf.len);
    for (name[0..len], 0..) |c, i| {
        buf[i] = std.ascii.toLower(c);
    }
    const clean = std.mem.trim(u8, buf[0..len], " \t\r\n");

    if (std.mem.eql(u8, clean, "github_dark")) return github_dark;
    if (std.mem.eql(u8, clean, "dracula")) return dracula;
    if (std.mem.eql(u8, clean, "catppuccin")) return catppuccin;
    if (std.mem.eql(u8, clean, "nord")) return nord;
    if (std.mem.eql(u8, clean, "synthwave")) return synthwave;
    if (std.mem.eql(u8, clean, "onedark")) return onedark;
    if (std.mem.eql(u8, clean, "radical")) return radical;
    if (std.mem.eql(u8, clean, "midnight")) return midnight;
    if (std.mem.eql(u8, clean, "github_light")) return github_light;

    return tokyonight;
}

pub fn applyThemeOverrides(
    base: Theme,
    bg: ?[]const u8,
    title: ?[]const u8,
    text: ?[]const u8,
    border: ?[]const u8,
    bar_bg: ?[]const u8,
    radius: ?f64,
) Theme {
    var t = base;
    if (bg) |val| {
        if (val.len > 0) t.bg_color = val;
    }
    if (title) |val| {
        if (val.len > 0) t.title_color = val;
    }
    if (text) |val| {
        if (val.len > 0) t.text_color = val;
    }
    if (border) |val| {
        if (val.len > 0) t.border_color = val;
    }
    if (bar_bg) |val| {
        if (val.len > 0) t.bar_bg_color = val;
    }
    if (radius) |val| {
        if (val >= 0) t.border_radius = val;
    }
    return t;
}
