package renderer_test

import (
	"strings"
	"testing"

	"git-stats/internal/github"
	"git-stats/internal/renderer"
)

func TestRenderSVG_Standard(t *testing.T) {
	stats := &github.UserStats{
		Username:   "testuser",
		TotalBytes: 100000,
		Languages: []github.LanguageStat{
			{Name: "TypeScript", Color: "#3178c6", Size: 38730},
			{Name: "Rust", Color: "#dea584", Size: 20290},
			{Name: "Go", Color: "#00add8", Size: 16820},
			{Name: "Java", Color: "#b07219", Size: 14240},
			{Name: "Python", Color: "#3572a5", Size: 6350},
			{Name: "Haskell", Color: "#5e5086", Size: 3570},
			{Name: "C++", Color: "#f34b7d", Size: 2800},
			{Name: "Shell", Color: "#89e051", Size: 1950},
			{Name: "Docker", Color: "#384d54", Size: 1420},
			{Name: "HTML", Color: "#e34c26", Size: 1210},
		},
	}

	opts := renderer.RenderOptions{
		Theme:      renderer.GetTheme("tokyonight"),
		CardWidth:  450,
		LangsCount: 8,
		Columns:    2,
		Layout:     "standard",
		Animate:    true,
	}

	svg := renderer.RenderSVG(stats, opts)

	if !strings.HasPrefix(svg, "<svg") || !strings.HasSuffix(strings.TrimSpace(svg), "</svg>") {
		t.Errorf("expected valid svg, got: %s", svg)
	}

	// Verify all 8 languages appear
	for _, l := range stats.Languages[:8] {
		if !strings.Contains(svg, l.Name) {
			t.Errorf("expected svg to contain language %s", l.Name)
		}
	}

	// Verify 9th language does NOT appear since LangsCount=8
	if strings.Contains(svg, "Docker") {
		t.Errorf("did not expect Docker to appear when LangsCount=8")
	}

	// Verify progress bar contains segments
	if !strings.Contains(svg, "bar-container") {
		t.Errorf("expected progress bar container")
	}
}

func TestRenderSVG_Donut(t *testing.T) {
	stats := &github.UserStats{
		Username:   "testuser",
		TotalBytes: 50000,
		Languages: []github.LanguageStat{
			{Name: "TypeScript", Color: "#3178c6", Size: 30000},
			{Name: "Go", Color: "#00add8", Size: 20000},
		},
	}

	opts := renderer.RenderOptions{
		Theme:      renderer.GetTheme("dracula"),
		CardWidth:  450,
		LangsCount: 5,
		Layout:     "donut",
	}

	svg := renderer.RenderSVG(stats, opts)

	if !strings.Contains(svg, "donut-segment") {
		t.Errorf("expected donut-segment class in donut layout")
	}
}

func TestRenderSVG_Compact(t *testing.T) {
	stats := &github.UserStats{
		Username:   "testuser",
		TotalBytes: 50000,
		Languages: []github.LanguageStat{
			{Name: "TypeScript", Color: "#3178c6", Size: 30000},
			{Name: "Go", Color: "#00add8", Size: 20000},
		},
	}

	opts := renderer.RenderOptions{
		Theme:      renderer.GetTheme("catppuccin"),
		CardWidth:  400,
		LangsCount: 5,
		Layout:     "compact",
	}

	svg := renderer.RenderSVG(stats, opts)

	if !strings.Contains(svg, "compact-bar-clip") {
		t.Errorf("expected compact-bar-clip in compact layout")
	}
}
