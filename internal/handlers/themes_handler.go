package handlers

import (
	"encoding/json"
	"net/http"
	"sort"

	"git-stats/internal/renderer"
)

// ThemesHandler lists all available preset themes.
type ThemesHandler struct{}

// NewThemesHandler creates a new ThemesHandler.
func NewThemesHandler() *ThemesHandler {
	return &ThemesHandler{}
}

func (h *ThemesHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	var list []renderer.Theme
	for _, t := range renderer.Themes {
		list = append(list, t)
	}

	sort.Slice(list, func(i, j int) bool {
		return list[i].Name < list[j].Name
	})

	json.NewEncoder(w).Encode(list)
}
