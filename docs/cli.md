# Native CLI reference

[Back to GitStats](../README.md)

The engine requires **Zig 0.16.0**. Build from the repository root:

```powershell
zig build -Doptimize=ReleaseFast
```

The executable is `zig-out/bin/git_stats.exe` on Windows and `zig-out/bin/git_stats` on Linux/macOS. Examples below use PowerShell and Windows paths. On other systems, use `./zig-out/bin/git_stats` with the same flags.

## Authentication

Copy [.env.example](../.env.example) to `.env` and set `GH_TOKEN` for local authenticated generation. The token is resolved from `--token`, environment `GH_TOKEN`, environment `GITHUB_TOKEN`, then `.env`. Prefer environment variables or `.env` over command-line secrets. The target username comes from `--username`, `GITHUB_REPOSITORY_OWNER`, or the existing default `adityapandeydev`.

GraphQL contribution metrics require authentication. Public language fetching can use REST without a token. Existing native fallback behavior is retained for compatibility; add `--strict-data` to propagate supported fetch failures and preserve empty activity instead of demonstration fallbacks.

## Generate a card

```powershell
.\zig-out\bin\git_stats.exe --generate --username=YOUR_USERNAME --theme=tokyonight --langs-count=12 --columns=2 --card-width=400 --card-height=294 --svg-icons --strict-data --animate=false --output=generated/languages.svg
.\zig-out\bin\git_stats.exe --streak --username=YOUR_USERNAME --svg-icons --strict-data --animate=false --output=generated/streak.svg
.\zig-out\bin\git_stats.exe --stats --username=YOUR_USERNAME --timeframe=all-time --svg-icons --strict-data --animate=false --output=generated/stats.svg
.\zig-out\bin\git_stats.exe --rhythm --username=YOUR_USERNAME --tz=5.5 --svg-icons --strict-data --animate=false --output=generated/rhythm.svg
.\zig-out\bin\git_stats.exe --radar --username=YOUR_USERNAME --svg-icons --strict-data --animate=false --output=generated/radar.svg
.\zig-out\bin\git_stats.exe --velocity --username=YOUR_USERNAME --svg-icons --strict-data --animate=false --output=generated/velocity.svg
.\zig-out\bin\git_stats.exe --milestones --username=YOUR_USERNAME --card-width=840 --svg-icons --strict-data --animate=false --output=generated/milestones.svg
```

Language layout choices are `standard`, `donut`, and `compact`. Use `--hide="HTML,CSS"` to exclude languages and `--exclude-repo="repo-one,repo-two"` to exclude repositories. Standard languages recalculate displayed percentages after filtering. The two-column minimum height grows with the actual displayed language count; additional height distributes space between rows. Studio's 6–16 language control uses the same renderer.

## Unified bento grids

Unlike Studio's exported individual images, bento mode composes the cards into one SVG:

```powershell
.\zig-out\bin\git_stats.exe --bento --username=YOUR_USERNAME --cards=streak,stats,languages --bento-layout=pillar-right-stack --svg-icons --strict-data --animate=false --output=generated/bento.svg
.\zig-out\bin\git_stats.exe --bento --username=YOUR_USERNAME --cards=streak,stats,rhythm,radar --bento-layout=matrix-2x2 --svg-icons --strict-data --animate=false --output=generated/matrix.svg
.\zig-out\bin\git_stats.exe --bento --username=YOUR_USERNAME --cards=all --bento-layout=master-dashboard --svg-icons --strict-data --animate=false --output=generated/master.svg
.\zig-out\bin\git_stats.exe --bento --username=YOUR_USERNAME --cards=streak,stats,languages --bento-layout=mobile-stack --svg-icons --strict-data --animate=false --output=generated/bento-mobile.svg
```

Embed the desktop/mobile pair only after generating **both** files:

```html
<picture>
  <source media="(max-width: 650px)" srcset="https://raw.githubusercontent.com/YOUR_USERNAME/git-stats/main/generated/bento-mobile.svg" />
  <img src="https://raw.githubusercontent.com/YOUR_USERNAME/git-stats/main/generated/bento.svg" width="100%" alt="GitHub profile statistics" />
</picture>
```

## Options

| Flag | Purpose |
| --- | --- |
| `--generate` | Languages card |
| `--streak`, `--stats`, `--rhythm`, `--radar`, `--velocity`, `--milestones` | Select another standalone card |
| `--bento`, `--grid` | Compose a unified grid |
| `--cards` | Comma-separated grid card IDs, or `all` |
| `--bento-layout` | `auto`, `pillar-right-stack`, `matrix-2x2`, `master-dashboard`, `mobile-stack`, and other native templates |
| `--username` | Target profile |
| `--theme` | Palette name; defaults to `tokyonight` |
| `--card-width`, `--card-height` | SVG dimensions; standard non-language cards use 424 × 180 |
| `--border-radius` | Outer corner radius, default 4.5; `0` gives square corners |
| `--layout`, `--columns` | Language layout and grid columns |
| `--langs-count` | Language limit, 6–16; default 8 |
| `--hide`, `--exclude-repo` | Comma-separated exclusions |
| `--hide-sparkline`, `--show-sparkline=false` | Omit streak momentum |
| `--timeframe` | `all-time` or `this-year`; the latter uses the rolling contribution collection |
| `--tz` | Commit-rhythm UTC offset in hours; default 5.5 |
| `--title` | Custom languages heading |
| `--hide-title`, `--hide-border` | Hide card decorations |
| `--title-color`, `--text-color`, `--bg-color`, `--border-color` | Theme overrides |
| `--animate=false` | Static rendering; animation is enabled by default |
| `--svg-icons` | Lucide SVG paths in place of legacy decorative emoji glyphs |
| `--strict-data` | Opt into explicit failure/empty-data behavior |
| `--output` | Output SVG path; use an explicit path for each card |
| `--token` | Explicit authentication override |

The CLI supports `tokyonight`, `github_dark`, `catppuccin`, `dracula`, `nord`, `synthwave`, `onedark`, `radical`, `midnight`, and `github_light`. Studio exposes eight dark presets.

The checked-in personal workflow is intentionally separate from Studio's generated workflow. Replacing it with an export adopts the flags and card settings from that export; it does not change the engine's legacy defaults.
