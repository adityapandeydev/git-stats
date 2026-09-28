package handlers

import (
	"encoding/json"
	"net/http"
	"strings"

	"git-stats/internal/github"
)

// LanguagesHandler returns detected languages for a user as JSON.
type LanguagesHandler struct {
	client *github.Client
}

// NewLanguagesHandler creates a new LanguagesHandler.
func NewLanguagesHandler(client *github.Client) *LanguagesHandler {
	return &LanguagesHandler{client: client}
}

func (h *LanguagesHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	username := strings.TrimSpace(q.Get("username"))
	token := q.Get("token")

	if username == "" {
		username = "demo"
	}

	var excludedRepos []string
	if ex := q.Get("exclude_repo"); ex != "" {
		for _, item := range strings.Split(ex, ",") {
			item = strings.TrimSpace(item)
			if item != "" {
				excludedRepos = append(excludedRepos, item)
			}
		}
	}

	stats, err := h.client.GetUserLanguages(r.Context(), username, token, excludedRepos)
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(stats)
}
