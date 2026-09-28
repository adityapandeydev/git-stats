package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"git-stats/internal/config"
	"git-stats/internal/github"
	"git-stats/internal/handlers"
	"git-stats/internal/renderer"
)

func main() {
	// CLI Flags
	generateFlag := flag.Bool("generate", false, "Generate SVG card directly to disk and exit (CLI mode)")
	usernameFlag := flag.String("username", "", "GitHub username (or reads GITHUB_REPOSITORY_OWNER)")
	outputFlag := flag.String("output", "languages.svg", "Output SVG file path")
	langsCountFlag := flag.Int("langs-count", 12, "Number of languages to display")
	hideFlag := flag.String("hide", "", "Comma-separated languages to hide (e.g. html,css)")
	themeFlag := flag.String("theme", "tokyonight", "Card theme preset")
	layoutFlag := flag.String("layout", "standard", "Layout style: standard, donut, compact")
	columnsFlag := flag.Int("columns", 2, "Grid columns count (0 for auto, 1, 2, 3)")
	cardWidthFlag := flag.Int("card-width", 495, "Card width in pixels")
	cardHeightFlag := flag.Int("card-height", 405, "Card height in pixels (matches 2 left cards combined)")
	tokenFlag := flag.String("token", "", "GitHub Personal Access Token (or reads GH_TOKEN / GITHUB_TOKEN)")
	excludeRepoFlag := flag.String("exclude-repo", "", "Comma-separated repository names to ignore")
	titleFlag := flag.String("title", "", "Custom card title")
	hideTitleFlag := flag.Bool("hide-title", false, "Hide card title")
	hideBorderFlag := flag.Bool("hide-border", false, "Hide card border")
	animateFlag := flag.Bool("animate", true, "Enable SVG animations")
	titleColorFlag := flag.String("title-color", "", "Custom title hex color")
	textColorFlag := flag.String("text-color", "", "Custom text hex color")
	bgColorFlag := flag.String("bg-color", "", "Custom background hex color")
	borderColorFlag := flag.String("border-color", "", "Custom border hex color")

	flag.Parse()

	cfg := config.Load()

	// Resolve token: flag > GH_TOKEN > GITHUB_TOKEN > cfg
	authToken := *tokenFlag
	if authToken == "" {
		authToken = os.Getenv("GH_TOKEN")
	}
	if authToken == "" {
		authToken = cfg.GitHubToken
	}

	ghClient := github.NewClient(authToken, cfg.CacheTTL)

	// Mode 1: CLI Direct Generation Mode (for GitHub Actions and scripts)
	if *generateFlag {
		username := strings.TrimSpace(*usernameFlag)
		if username == "" {
			username = strings.TrimSpace(os.Getenv("GITHUB_REPOSITORY_OWNER"))
		}
		if username == "" {
			username = "adityapandeydev"
		}

		var excludedRepos []string
		if *excludeRepoFlag != "" {
			for _, item := range strings.Split(*excludeRepoFlag, ",") {
				if clean := strings.TrimSpace(item); clean != "" {
					excludedRepos = append(excludedRepos, clean)
				}
			}
		}

		ctx := context.Background()
		fmt.Printf("⚡ Fetching GitHub stats for user '%s'...\n", username)
		stats, err := ghClient.GetUserLanguages(ctx, username, authToken, excludedRepos)
		if err != nil {
			log.Fatalf("❌ Error fetching stats: %v", err)
		}

		// Filter hidden languages
		hiddenMap := make(map[string]bool)
		if *hideFlag != "" {
			for _, h := range strings.Split(*hideFlag, ",") {
				if clean := strings.ToLower(strings.TrimSpace(h)); clean != "" {
					hiddenMap[clean] = true
				}
			}
		}

		var visibleLangs []github.LanguageStat
		for _, l := range stats.Languages {
			if !hiddenMap[strings.ToLower(l.Name)] {
				visibleLangs = append(visibleLangs, l)
			}
		}

		filteredStats := &github.UserStats{
			Username:   stats.Username,
			TotalBytes: stats.TotalBytes,
			Languages:  visibleLangs,
		}

		// Theme overrides
		baseTheme := renderer.GetTheme(*themeFlag)
		activeTheme := renderer.ApplyThemeOverrides(
			baseTheme,
			*bgColorFlag,
			*titleColorFlag,
			*textColorFlag,
			*borderColorFlag,
			"",
			-1,
		)

		opts := renderer.RenderOptions{
			Theme:        activeTheme,
			CardWidth:    *cardWidthFlag,
			CardHeight:   *cardHeightFlag,
			LangsCount:   *langsCountFlag,
			Columns:      *columnsFlag,
			Layout:       *layoutFlag,
			HideTitle:    *hideTitleFlag,
			CustomTitle:  *titleFlag,
			Animate:      *animateFlag,
			BorderRadius: activeTheme.BorderRadius,
			HideBorder:   *hideBorderFlag,
			ShowPercent:  true,
		}

		svgContent := renderer.RenderSVG(filteredStats, opts)

		// Ensure output directory exists
		outDir := filepath.Dir(*outputFlag)
		if outDir != "" && outDir != "." {
			if err := os.MkdirAll(outDir, 0755); err != nil {
				log.Fatalf("❌ Error creating output directory: %v", err)
			}
		}

		if err := os.WriteFile(*outputFlag, []byte(svgContent), 0644); err != nil {
			log.Fatalf("❌ Error writing output SVG file: %v", err)
		}

		fmt.Printf("✅ Successfully generated '%s' for '%s' (%d languages, %dx%d px)\n",
			*outputFlag, username, len(visibleLangs), *cardWidthFlag, *cardHeightFlag)
		os.Exit(0)
	}

	// Mode 2: HTTP Server & Web Customizer Studio
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
	if authToken != "" {
		fmt.Println("  🔑 GitHub Token:       Configured (5,000 req/hr)")
	} else {
		fmt.Println("  ℹ️  GitHub Token:       None (Demo mode ready / Set GITHUB_TOKEN in .env)")
	}
	fmt.Println("==================================================")

	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}
