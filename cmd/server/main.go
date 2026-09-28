package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"

	"git-stats/internal/config"
	"git-stats/internal/github"
	"git-stats/internal/handlers"
)

func main() {
	cfg := config.Load()

	// Initialize GitHub client with caching
	ghClient := github.NewClient(cfg.GitHubToken, cfg.CacheTTL)

	// Handlers
	statsHandler := handlers.NewStatsHandler(ghClient)
	languagesHandler := handlers.NewLanguagesHandler(ghClient)
	themesHandler := handlers.NewThemesHandler()

	mux := http.NewServeMux()

	// API Routes
	mux.Handle("/api/top-langs", statsHandler)
	mux.Handle("/api/stats/languages", statsHandler)
	mux.Handle("/api/languages", languagesHandler)
	mux.Handle("/api/themes", themesHandler)

	mux.HandleFunc("/api/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{
			"status":  "healthy",
			"service": "git-stats",
			"version": "1.0.0",
		})
	})

	// Static Files & Web Customizer UI
	staticDir := filepath.Join("web", "static")
	if _, err := os.Stat(staticDir); err == nil {
		mux.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir(staticDir))))
	}

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}
		indexPath := filepath.Join("web", "index.html")
		http.ServeFile(w, r, indexPath)
	})

	addr := ":" + cfg.Port
	fmt.Println("==================================================")
	fmt.Println("  ⚡ GitStats - Dynamic Language Card Service")
	fmt.Println("==================================================")
	fmt.Printf("  🌐 Web Customizer UI:  http://localhost%s/\n", addr)
	fmt.Printf("  📊 SVG Endpoint:       http://localhost%s/api/top-langs?username=demo\n", addr)
	fmt.Printf("  🎨 Themes API:         http://localhost%s/api/themes\n", addr)
	if cfg.GitHubToken != "" {
		fmt.Println("  🔑 GitHub Token:       Configured (5,000 req/hr)")
	} else {
		fmt.Println("  ℹ️  GitHub Token:       None (Demo mode ready / Set GITHUB_TOKEN in .env)")
	}
	fmt.Println("==================================================")

	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}
