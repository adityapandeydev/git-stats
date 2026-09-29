package renderer

import "strings"

// Theme defines the visual styling of the SVG card.
type Theme struct {
	Name         string `json:"name"`
	Label        string `json:"label"`
	BgColor      string `json:"bg_color"`
	TitleColor   string `json:"title_color"`
	TextColor    string `json:"text_color"`
	MutedColor   string `json:"muted_color"`
	BorderColor  string `json:"border_color"`
	BarBgColor   string `json:"bar_bg_color"`
	AccentColor  string  `json:"accent_color"`
	BorderRadius float64 `json:"border_radius"`
}

// Themes holds all pre-configured card themes.
var Themes = map[string]Theme{
	"tokyonight": {
		Name:         "tokyonight",
		Label:        "Tokyo Night",
		BgColor:      "#151520",
		TitleColor:   "#388bfd",
		TextColor:    "#c0caf5",
		MutedColor:   "#7982a9",
		BorderColor:  "#2a2a3c",
		BarBgColor:   "#212337",
		AccentColor:  "#7aa2f7",
		BorderRadius: 4.5,
	},
	"github_dark": {
		Name:         "github_dark",
		Label:        "GitHub Dark",
		BgColor:      "#0d1117",
		TitleColor:   "#58a6ff",
		TextColor:    "#c9d1d9",
		MutedColor:   "#8b949e",
		BorderColor:  "#30363d",
		BarBgColor:   "#161b22",
		AccentColor:  "#1f6feb",
		BorderRadius: 4.5,
	},
	"dracula": {
		Name:         "dracula",
		Label:        "Dracula",
		BgColor:      "#282a36",
		TitleColor:   "#8be9fd",
		TextColor:    "#f8f8f2",
		MutedColor:   "#6272a4",
		BorderColor:  "#44475a",
		BarBgColor:   "#1e1f29",
		AccentColor:  "#bd93f9",
		BorderRadius: 4.5,
	},
	"catppuccin": {
		Name:         "catppuccin",
		Label:        "Catppuccin Mocha",
		BgColor:      "#1e1e2e",
		TitleColor:   "#89b4fa",
		TextColor:    "#cdd6f4",
		MutedColor:   "#a6adc8",
		BorderColor:  "#313244",
		BarBgColor:   "#181825",
		AccentColor:  "#cba6f7",
		BorderRadius: 4.5,
	},
	"nord": {
		Name:         "nord",
		Label:        "Nord",
		BgColor:      "#2e3440",
		TitleColor:   "#88c0d0",
		TextColor:    "#eceff4",
		MutedColor:   "#4c566a",
		BorderColor:  "#3b4252",
		BarBgColor:   "#242933",
		AccentColor:  "#81a1c1",
		BorderRadius: 4.5,
	},
	"synthwave": {
		Name:         "synthwave",
		Label:        "Synthwave",
		BgColor:      "#1a102f",
		TitleColor:   "#f92aad",
		TextColor:    "#2de2e6",
		MutedColor:   "#725ac1",
		BorderColor:  "#ff007f",
		BarBgColor:   "#120924",
		AccentColor:  "#05d9e8",
		BorderRadius: 4.5,
	},
	"onedark": {
		Name:         "onedark",
		Label:        "One Dark",
		BgColor:      "#282c34",
		TitleColor:   "#61afef",
		TextColor:    "#abb2bf",
		MutedColor:   "#5c6370",
		BorderColor:  "#3e4451",
		BarBgColor:   "#21252b",
		AccentColor:  "#98c379",
		BorderRadius: 4.5,
	},
	"radical": {
		Name:         "radical",
		Label:        "Radical",
		BgColor:      "#141321",
		TitleColor:   "#fe428e",
		TextColor:    "#a9fef7",
		MutedColor:   "#726e97",
		BorderColor:  "#2a2b3d",
		BarBgColor:   "#0f0e1a",
		AccentColor:  "#f8d847",
		BorderRadius: 4.5,
	},
	"midnight": {
		Name:         "midnight",
		Label:        "OLED Midnight",
		BgColor:      "#050508",
		TitleColor:   "#6366f1",
		TextColor:    "#f1f5f9",
		MutedColor:   "#64748b",
		BorderColor:  "#1e1e2f",
		BarBgColor:   "#0f0f17",
		AccentColor:  "#818cf8",
		BorderRadius: 4.5,
	},
	"github_light": {
		Name:         "github_light",
		Label:        "GitHub Light",
		BgColor:      "#ffffff",
		TitleColor:   "#0969da",
		TextColor:    "#24292f",
		MutedColor:   "#57606a",
		BorderColor:  "#d0d7de",
		BarBgColor:   "#eaeef2",
		AccentColor:  "#0969da",
		BorderRadius: 4.5,
	},
}

// GetTheme resolves the theme by name, with fallback to "tokyonight".
func GetTheme(name string) Theme {
	clean := strings.ToLower(strings.TrimSpace(name))
	if t, exists := Themes[clean]; exists {
		return t
	}
	return Themes["tokyonight"]
}

// ApplyThemeOverrides applies optional custom color and style parameters.
func ApplyThemeOverrides(base Theme, bg, title, text, border, barBg string, radius float64) Theme {
	t := base
	if bg != "" {
		t.BgColor = formatHex(bg)
	}
	if title != "" {
		t.TitleColor = formatHex(title)
	}
	if text != "" {
		t.TextColor = formatHex(text)
	}
	if border != "" {
		t.BorderColor = formatHex(border)
	}
	if barBg != "" {
		t.BarBgColor = formatHex(barBg)
	}
	if radius >= 0 {
		t.BorderRadius = radius
	}
	return t
}

func formatHex(c string) string {
	c = strings.TrimSpace(c)
	if !strings.HasPrefix(c, "#") {
		return "#" + c
	}
	return c
}
