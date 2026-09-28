package config

import (
	"bufio"
	"os"
	"strconv"
	"strings"
	"time"
)

// Config holds runtime configuration for the service.
type Config struct {
	Port        string
	GitHubToken string
	CacheTTL    time.Duration
}

// Load loads configuration from environment variables and an optional .env file.
func Load() *Config {
	loadDotEnv(".env")

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	githubToken := os.Getenv("GITHUB_TOKEN")

	ttlMinutes := 120
	if ttlStr := os.Getenv("CACHE_TTL_MINUTES"); ttlStr != "" {
		if val, err := strconv.Atoi(ttlStr); err == nil && val > 0 {
			ttlMinutes = val
		}
	}

	return &Config{
		Port:        port,
		GitHubToken: githubToken,
		CacheTTL:    time.Duration(ttlMinutes) * time.Minute,
	}
}

func loadDotEnv(filepath string) {
	file, err := os.Open(filepath)
	if err != nil {
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.SplitN(line, "=", 2)
		if len(parts) == 2 {
			k := strings.TrimSpace(parts[0])
			v := strings.TrimSpace(parts[1])
			// Only set if not already set in environment
			if os.Getenv(k) == "" {
				os.Setenv(k, v)
			}
		}
	}
}
