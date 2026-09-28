# ⚡ GitStats - Dynamic GitHub Stats & Language Card System

A fast, lightweight standalone Go service that generates customizable SVG language statistics cards for your GitHub Profile README.

Designed to overcome the limitations of existing cards (such as the default 6-language cap) with complete customization, language hiding, interactive web studio, and support for themes.

![GitStats Tokyo Night](http://localhost:8080/api/top-langs?username=demo&langs_count=8&theme=tokyonight)

---

## ✨ Features

- **Break the 6-Language Limit**: Display **8, 10, 12, 16+** languages cleanly in responsive multi-column layouts.
- **Language Hiding & Filtering**: Hide specific languages (e.g. `hide=html,css,jupyter notebook`) with automatic percentage recalculation.
- **Interactive Web Customizer**: Live browser playground at `http://localhost:8080/` with real-time SVG preview, sliders, detected language chips, theme picker, and 1-click Markdown/HTML copy.
- **Zero Heavy Dependencies**: Pure Go with standard library + vanilla modern CSS/JS. Compiles into a single portable binary.
- **Multiple Layouts**:
  - `standard` (Segmented progress bar + multi-column language grid)
  - `donut` (Radial donut chart with legend)
  - `compact` (Minimal horizontal bar for tight spaces)
- **Preset Themes**: Tokyo Night, GitHub Dark, Dracula, Catppuccin Mocha, Nord, Synthwave, One Dark, Radical, OLED Midnight, GitHub Light.
- **Full Styling Overrides**: Custom hex colors for title, text, background, border, custom card width, border radius, and animations.
- **In-Memory Cache**: Built-in thread-safe TTL cache protects your GitHub API rate limits.
- **GraphQL & REST Support**: Efficient GraphQL aggregation with fallback to REST API.

---

## 🚀 Quick Start

### 1. Run with Go

```bash
# Clone the repository
git clone https://github.com/your-username/git-stats.git
cd git-stats

# Run the server
go run ./cmd/server
```

Or run the pre-built binary:
```bash
./git-stats.exe
```

Open your browser at: **`http://localhost:8080/`** to use the interactive customizer.

---

## 📋 Markdown Embedding

Add the card to your GitHub profile `README.md`:

### Standard Card (8 Languages, Tokyo Night):
```markdown
[![Most Used Languages](https://YOUR_DOMAIN/api/top-langs?username=yourusername&langs_count=8&theme=tokyonight)](https://github.com/yourusername)
```

### 10 Languages with HTML/CSS hidden:
```markdown
[![Most Used Languages](https://YOUR_DOMAIN/api/top-langs?username=yourusername&langs_count=10&hide=html,css&theme=tokyonight)](https://github.com/yourusername)
```

### Donut Chart Layout:
```markdown
[![Most Used Languages](https://YOUR_DOMAIN/api/top-langs?username=yourusername&layout=donut&theme=catppuccin)](https://github.com/yourusername)
```

---

## ⚙️ URL Query Parameters

| Parameter | Type | Default | Description |
|:---|:---:|:---:|:---|
| `username` | string | `demo` | GitHub username (required) |
| `langs_count` | integer | `8` | Number of languages to display (1 to 20+) |
| `hide` | string | `""` | Comma-separated languages to hide (e.g. `html,css,jupyter notebook`) |
| `layout` | string | `standard` | Card layout: `standard`, `donut`, `compact` |
| `columns` | integer | `0` | Grid columns for standard layout (`0` = auto, `1`, `2`, `3`) |
| `theme` | string | `tokyonight` | Color preset (see themes below) |
| `card_width` | integer | `450` | Card width in pixels (320px - 1000px) |
| `title` | string | `""` | Custom card header title |
| `hide_title` | boolean | `false` | Set to `true` to remove the header |
| `hide_border` | boolean | `false` | Set to `true` to remove card border |
| `border_radius` | integer | `10` | Corner radius in pixels |
| `animation` | boolean | `true` | Enable/disable SVG load animations |
| `exclude_repo` | string | `""` | Comma-separated repository names to ignore |
| `title_color` | string | - | Custom title hex code (without `#`) |
| `text_color` | string | - | Custom text hex code (without `#`) |
| `bg_color` | string | - | Custom background hex code (without `#`) |
| `border_color` | string | - | Custom border hex code (without `#`) |
| `token` | string | - | Personal access token for private repos or testing |

---

## 🎨 Built-in Themes

| Theme Name | Description |
|:---|:---|
| `tokyonight` | Sleek dark navy matching modern developer portfolios (default) |
| `github_dark` | GitHub's native dark mode palette (`#0d1117`) |
| `dracula` | Classic Dracula vampire theme |
| `catppuccin` | Catppuccin Mocha cozy pastel dark palette |
| `nord` | Arctic, north-bluish palette |
| `synthwave` | Vibrant 80s neon synthwave with glowing magenta |
| `onedark` | Atom One Dark theme |
| `radical` | High-contrast neon retro theme |
| `midnight` | Deep OLED black (`#050508`) with electric indigo |
| `github_light` | Clean GitHub light mode theme |

---

## 🔑 GitHub Token Configuration

By default, without a token GitHub limits unauthenticated requests to 60/hr. To unlock **5,000 requests/hour** and access private repositories:

1. Create a Personal Access Token (classic) on GitHub with `repo` scope.
2. Create a `.env` file in the root directory:
   ```env
   PORT=8080
   GITHUB_TOKEN=ghp_yourPersonalAccessTokenHere
   CACHE_TTL_MINUTES=120
   ```
3. Restart the server.

---

## 📁 Project Architecture

```
git-stats/
├── cmd/
│   └── server/
│       └── main.go          # HTTP server entrypoint and route definitions
├── internal/
│   ├── cache/
│   │   └── cache.go         # Thread-safe in-memory generic TTL cache
│   ├── config/
│   │   └── config.go        # Environment and .env configuration parser
│   ├── github/
│   │   ├── client.go        # GraphQL and REST GitHub API client
│   │   ├── colors.go        # Official GitHub Linguist language colors map
│   │   └── models.go        # Data structures for repos and language stats
│   ├── handlers/
│   │   ├── stats.go         # /api/top-langs dynamic SVG generator handler
│   │   ├── languages.go     # /api/languages JSON inspection endpoint
│   │   ├── themes_handler.go# /api/themes JSON endpoint
│   │   └── error_svg.go     # Graceful error SVG renderer
│   └── renderer/
│       ├── svg.go           # Scalable SVG generator (standard, donut, compact)
│       ├── themes.go        # Preset themes and custom color overrides
│       └── svg_test.go      # Layout & SVG rendering unit tests
├── web/
│   ├── index.html           # Interactive customizer studio
│   └── static/
│       ├── css/style.css    # Modern dark mode glassmorphism UI
│       └── js/app.js        # Live preview, state, and embed generation
├── .env.example
├── go.mod
└── README.md
```
