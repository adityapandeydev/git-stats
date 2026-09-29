package handlers

import (
	"net/http"
	"strconv"
	"strings"

	"git-stats/internal/github"
	"git-stats/internal/renderer"
)

// StatsHandler serves the dynamic SVG language card.
type StatsHandler struct {
	client *github.Client
}

// NewStatsHandler creates a new handler instance.
func NewStatsHandler(client *github.Client) *StatsHandler {
	return &StatsHandler{client: client}
}

func (h *StatsHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	username := strings.TrimSpace(q.Get("username"))

	themeName := q.Get("theme")
	baseTheme := renderer.GetTheme(themeName)

	// Apply query overrides to theme
	radius := -1.0
	if rStr := q.Get("border_radius"); rStr != "" {
		if rVal, err := strconv.ParseFloat(rStr, 64); err == nil {
			radius = rVal
		}
	}
	activeTheme := renderer.ApplyThemeOverrides(
		baseTheme,
		q.Get("bg_color"),
		q.Get("title_color"),
		q.Get("text_color"),
		q.Get("border_color"),
		q.Get("bar_bg_color"),
		radius,
	)

	cardWidth := 450
	if wStr := q.Get("card_width"); wStr != "" {
		if val, err := strconv.Atoi(wStr); err == nil && val >= 300 && val <= 1000 {
			cardWidth = val
		}
	}

	cardHeight := 0
	if hStr := q.Get("card_height"); hStr != "" {
		if val, err := strconv.Atoi(hStr); err == nil && val >= 100 && val <= 1500 {
			cardHeight = val
		}
	}

	w.Header().Set("Content-Type", "image/svg+xml; charset=utf-8")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	if username == "" {
		// Provide demo stats if no username provided, or prompt to enter one
		username = "demo"
	}

	// Parsing excluded repos
	var excludedRepos []string
	if ex := q.Get("exclude_repo"); ex != "" {
		for _, item := range strings.Split(ex, ",") {
			item = strings.TrimSpace(item)
			if item != "" {
				excludedRepos = append(excludedRepos, item)
			}
		}
	}

	token := q.Get("token")
	stats, err := h.client.GetUserLanguages(r.Context(), username, token, excludedRepos)
	if err != nil {
		w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(RenderErrorSVG(err.Error(), activeTheme, cardWidth)))
		return
	}

	// Parsing hide parameter (languages to exclude)
	hiddenMap := make(map[string]bool)
	if hideStr := q.Get("hide"); hideStr != "" {
		for _, hName := range strings.Split(hideStr, ",") {
			clean := strings.ToLower(strings.TrimSpace(hName))
			if clean != "" {
				hiddenMap[clean] = true
			}
		}
	}

	// Filter out hidden languages
	var visibleLangs []github.LanguageStat
	for _, l := range stats.Languages {
		if !hiddenMap[strings.ToLower(l.Name)] {
			visibleLangs = append(visibleLangs, l)
		}
	}

	// Parse langs_count
	langsCount := 8
	if lcStr := q.Get("langs_count"); lcStr != "" {
		if val, err := strconv.Atoi(lcStr); err == nil && val > 0 && val <= 50 {
			langsCount = val
		}
	}

	// Parse columns
	cols := 0
	if colStr := q.Get("columns"); colStr != "" {
		if val, err := strconv.Atoi(colStr); err == nil && val >= 1 && val <= 3 {
			cols = val
		}
	}

	layout := q.Get("layout")
	if layout == "" {
		layout = "standard"
	}

	hideTitle := parseBool(q.Get("hide_title"), false)
	hideBorder := parseBool(q.Get("hide_border"), false)
	animate := parseBool(q.Get("animation"), true)
	showPercent := parseBool(q.Get("show_percent"), true)
	customTitle := q.Get("title")

	opts := renderer.RenderOptions{
		Theme:        activeTheme,
		CardWidth:    cardWidth,
		CardHeight:   cardHeight,
		LangsCount:   langsCount,
		Columns:      cols,
		Layout:       layout,
		HideTitle:    hideTitle,
		CustomTitle:  customTitle,
		Animate:      animate,
		BorderRadius: activeTheme.BorderRadius,
		HideBorder:   hideBorder,
		ShowPercent:  showPercent,
	}

	filteredStats := &github.UserStats{
		Username:   stats.Username,
		TotalBytes: stats.TotalBytes,
		Languages:  visibleLangs,
	}

	if len(visibleLangs) == 0 {
		w.Header().Set("Cache-Control", "public, max-age=60")
		w.Write([]byte(RenderErrorSVG("All languages are hidden or no languages found", activeTheme, cardWidth)))
		return
	}

	svgContent := renderer.RenderSVG(filteredStats, opts)

	w.Header().Set("Cache-Control", "public, max-age=7200, s-maxage=7200")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(svgContent))
}

func parseBool(val string, defaultVal bool) bool {
	if val == "" {
		return defaultVal
	}
	b, err := strconv.ParseBool(val)
	if err != nil {
		return defaultVal
	}
	return b
}
