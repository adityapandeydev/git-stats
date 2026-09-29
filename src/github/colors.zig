const std = @import("std");

pub const default_language_color = "#586069";

const colors_map = std.StaticStringMap([]const u8).initComptime(.{
    .{ "typescript", "#3178c6" },
    .{ "javascript", "#f1e05a" },
    .{ "python", "#3572A5" },
    .{ "rust", "#dea584" },
    .{ "go", "#00ADD8" },
    .{ "java", "#b07219" },
    .{ "c++", "#f34b7d" },
    .{ "c", "#555555" },
    .{ "c#", "#178600" },
    .{ "csharp", "#178600" },
    .{ "html", "#e34c26" },
    .{ "css", "#563d7c" },
    .{ "scss", "#c6538c" },
    .{ "sass", "#a53b70" },
    .{ "less", "#1d365d" },
    .{ "php", "#4F5D95" },
    .{ "ruby", "#701516" },
    .{ "swift", "#F05138" },
    .{ "kotlin", "#A97BFF" },
    .{ "dart", "#00B4AB" },
    .{ "scala", "#c22d40" },
    .{ "shell", "#89e051" },
    .{ "bash", "#89e051" },
    .{ "zsh", "#89e051" },
    .{ "powershell", "#012456" },
    .{ "lua", "#000080" },
    .{ "haskell", "#5e5086" },
    .{ "elixir", "#6e4a7e" },
    .{ "erlang", "#B83998" },
    .{ "clojure", "#db5855" },
    .{ "zig", "#ec915c" },
    .{ "nim", "#ffc200" },
    .{ "ocaml", "#3be133" },
    .{ "julia", "#a270ba" },
    .{ "r", "#198CE7" },
    .{ "sql", "#e38c00" },
    .{ "plpgsql", "#336790" },
    .{ "vue", "#41b883" },
    .{ "svelte", "#ff3e00" },
    .{ "astro", "#ff5a03" },
    .{ "jupyter notebook", "#DA5B0B" },
    .{ "dockerfile", "#384d54" },
    .{ "makefile", "#427819" },
    .{ "vim script", "#199f4b" },
    .{ "graphql", "#e10098" },
    .{ "solidity", "#AA6746" },
    .{ "perl", "#0298c3" },
    .{ "assembly", "#6E4C13" },
    .{ "coq", "#d0b68c" },
    .{ "f#", "#b845fc" },
    .{ "groovy", "#4298b8" },
    .{ "objective-c", "#438eff" },
    .{ "objective-c++", "#6866fb" },
    .{ "common lisp", "#3fb68b" },
    .{ "scheme", "#1e4aec" },
    .{ "emacs lisp", "#c065db" },
    .{ "fortran", "#4d41b1" },
    .{ "matlab", "#e16737" },
    .{ "cuda", "#3A4E58" },
    .{ "verilog", "#b2b7f8" },
    .{ "systemverilog", "#DAE1C2" },
    .{ "vhdl", "#adb2cb" },
    .{ "tex", "#3D6117" },
    .{ "latex", "#3D6117" },
    .{ "coffeescript", "#244776" },
    .{ "actionscript", "#882B0F" },
    .{ "d", "#ba595e" },
    .{ "crystal", "#000100" },
    .{ "v", "#4f87c4" },
    .{ "glsl", "#5686a5" },
    .{ "hlsl", "#aace60" },
    .{ "wgsl", "#8a2be2" },
    .{ "haxe", "#df7900" },
    .{ "nix", "#7e7eff" },
    .{ "json", "#292929" },
    .{ "yaml", "#cb171e" },
    .{ "toml", "#9c4221" },
    .{ "markdown", "#083fa1" },
});

/// GetLanguageColor returns the official GitHub Linguist color for the given language.
/// If not found in the static map, it returns fallback (if valid hex) or default_language_color.
pub fn getLanguageColor(lang_name: []const u8, fallback: ?[]const u8) []const u8 {
    if (fallback) |fb| {
        if (fb.len > 0 and fb[0] == '#') {
            return fb;
        }
    }

    var buf: [128]u8 = undefined;
    const len = @min(lang_name.len, buf.len);
    for (lang_name[0..len], 0..) |c, i| {
        buf[i] = std.ascii.toLower(c);
    }
    const lower = buf[0..len];

    if (colors_map.get(lower)) |c| {
        return c;
    }

    if (fallback) |fb| {
        if (fb.len > 0) return fb;
    }

    return default_language_color;
}
