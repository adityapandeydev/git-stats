package github

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"sort"
	"strings"
	"time"

	"git-stats/internal/cache"
)

// Client handles communication with GitHub's GraphQL and REST APIs.
type Client struct {
	httpClient  *http.Client
	globalToken string
	cache       *cache.MemoryCache[*UserStats]
}

// NewClient initializes a new GitHub client with in-memory caching.
func NewClient(globalToken string, cacheTTL time.Duration) *Client {
	return &Client{
		httpClient: &http.Client{
			Timeout: 15 * time.Second,
		},
		globalToken: globalToken,
		cache:       cache.New[*UserStats](cacheTTL, 10*time.Minute),
	}
}

// GetUserLanguages fetches repository language data for a user.
func (c *Client) GetUserLanguages(ctx context.Context, username string, token string, excludedRepos []string) (*UserStats, error) {
	username = strings.TrimSpace(username)
	if username == "" || strings.EqualFold(username, "demo") {
		return c.getDemoStats(), nil
	}

	// Use provided token or fallback to server global token
	authToken := token
	if authToken == "" {
		authToken = c.globalToken
	}

	// Generate cache key
	cacheKey := fmt.Sprintf("%s:%s", strings.ToLower(username), strings.ToLower(strings.Join(excludedRepos, ",")))
	if cached, ok := c.cache.Get(cacheKey); ok {
		return cached, nil
	}

	// Build exclusion lookup set
	excludedSet := make(map[string]bool)
	for _, r := range excludedRepos {
		clean := strings.ToLower(strings.TrimSpace(r))
		if clean != "" {
			excludedSet[clean] = true
		}
	}

	// Attempt GraphQL query if token is present
	var stats *UserStats
	var err error

	if authToken != "" {
		stats, err = c.fetchGraphQL(ctx, username, authToken, excludedSet)
	}

	// If GraphQL was skipped or failed, fallback to REST API
	if stats == nil || err != nil {
		restStats, restErr := c.fetchREST(ctx, username, authToken, excludedSet)
		if restErr == nil && restStats != nil && len(restStats.Languages) > 0 {
			stats = restStats
			err = nil
		} else if err == nil {
			err = restErr
		}
	}

	if err != nil {
		return nil, err
	}

	if stats == nil || len(stats.Languages) == 0 {
		return nil, fmt.Errorf("no language statistics found for user '%s'", username)
	}

	// Save in cache
	c.cache.Set(cacheKey, stats)
	return stats, nil
}

func (c *Client) fetchGraphQL(ctx context.Context, username string, token string, excludedSet map[string]bool) (*UserStats, error) {
	query := `query($login: String!) {
		user(login: $login) {
			repositories(ownerAffiliations: OWNER, isFork: false, first: 100, orderBy: {field: PUSHED_AT, direction: DESC}) {
				pageInfo {
					hasNextPage
					endCursor
				}
				nodes {
					name
					isFork
					languages(first: 20, orderBy: {field: SIZE, direction: DESC}) {
						edges {
							size
							node {
								name
								color
							}
						}
					}
				}
			}
		}
	}`

	reqBody := map[string]interface{}{
		"query": query,
		"variables": map[string]string{
			"login": username,
		},
	}

	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, "POST", "https://api.github.com/graphql", bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, err
	}

	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "git-stats-card-generator")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("github graphql error (HTTP %d): %s", resp.StatusCode, string(body))
	}

	var gqlResp GraphQLResponse
	if err := json.NewDecoder(resp.Body).Decode(&gqlResp); err != nil {
		return nil, err
	}

	if len(gqlResp.Errors) > 0 {
		return nil, fmt.Errorf("graphql error: %s", gqlResp.Errors[0].Message)
	}

	langTotals := make(map[string]int64)
	langColorsMap := make(map[string]string)
	var totalBytes int64

	repos := gqlResp.Data.User.Repositories.Nodes
	for _, repo := range repos {
		if repo.IsFork || excludedSet[strings.ToLower(repo.Name)] {
			continue
		}

		for _, edge := range repo.Languages.Edges {
			name := edge.Node.Name
			size := edge.Size
			color := edge.Node.Color

			langTotals[name] += size
			totalBytes += size

			if _, exists := langColorsMap[name]; !exists || langColorsMap[name] == "" {
				langColorsMap[name] = GetLanguageColor(name, color)
			}
		}
	}

	return buildUserStats(username, langTotals, langColorsMap, totalBytes), nil
}

func (c *Client) fetchREST(ctx context.Context, username string, token string, excludedSet map[string]bool) (*UserStats, error) {
	url := fmt.Sprintf("https://api.github.com/users/%s/repos?per_page=100&type=owner&sort=pushed", username)
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, err
	}

	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	req.Header.Set("User-Agent", "git-stats-card-generator")
	req.Header.Set("Accept", "application/vnd.github.v3+json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusForbidden || resp.StatusCode == http.StatusTooManyRequests {
		return nil, fmt.Errorf("GitHub API rate limit exceeded. Please configure a GitHub Token")
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("github rest error (HTTP %d)", resp.StatusCode)
	}

	var repos []RestRepo
	if err := json.NewDecoder(resp.Body).Decode(&repos); err != nil {
		return nil, err
	}

	langTotals := make(map[string]int64)
	langColorsMap := make(map[string]string)
	var totalBytes int64

	// Fetch languages for top repos (cap at 20 repos to avoid excessive API calls if unauthenticated)
	limit := len(repos)
	if token == "" && limit > 15 {
		limit = 15
	}

	for i := 0; i < limit; i++ {
		repo := repos[i]
		if repo.Fork || excludedSet[strings.ToLower(repo.Name)] {
			continue
		}

		langUrl := fmt.Sprintf("https://api.github.com/repos/%s/%s/languages", username, repo.Name)
		langReq, err := http.NewRequestWithContext(ctx, "GET", langUrl, nil)
		if err != nil {
			continue
		}
		if token != "" {
			langReq.Header.Set("Authorization", "Bearer "+token)
		}
		langReq.Header.Set("User-Agent", "git-stats-card-generator")

		langResp, err := c.httpClient.Do(langReq)
		if err != nil {
			continue
		}

		var repoLangs map[string]int64
		if langResp.StatusCode == http.StatusOK {
			json.NewDecoder(langResp.Body).Decode(&repoLangs)
		}
		langResp.Body.Close()

		for name, size := range repoLangs {
			langTotals[name] += size
			totalBytes += size
			if _, exists := langColorsMap[name]; !exists {
				langColorsMap[name] = GetLanguageColor(name, "")
			}
		}
	}

	return buildUserStats(username, langTotals, langColorsMap, totalBytes), nil
}

func buildUserStats(username string, totals map[string]int64, colors map[string]string, totalBytes int64) *UserStats {
	var list []LanguageStat
	for name, size := range totals {
		pct := 0.0
		if totalBytes > 0 {
			pct = (float64(size) / float64(totalBytes)) * 100.0
		}
		list = append(list, LanguageStat{
			Name:       name,
			Color:      colors[name],
			Size:       size,
			Percentage: pct,
		})
	}

	// Sort descending by size
	sort.Slice(list, func(i, j int) bool {
		return list[i].Size > list[j].Size
	})

	return &UserStats{
		Username:   username,
		TotalBytes: totalBytes,
		Languages:  list,
	}
}

// getDemoStats returns a realistic set of languages matching the user's screenshot,
// plus extra languages so users can test 8, 10, 12, etc. languages immediately.
func (c *Client) getDemoStats() *UserStats {
	raw := []struct {
		name string
		size int64
	}{
		{"TypeScript", 387300},
		{"Rust", 202900},
		{"Go", 168200},
		{"Java", 142400},
		{"Python", 63500},
		{"Haskell", 35700},
		{"C++", 28000},
		{"Shell", 19500},
		{"Docker", 14200},
		{"HTML", 12100},
		{"CSS", 9800},
		{"SQL", 7500},
		{"Lua", 5200},
		{"Dart", 3800},
		{"Kotlin", 3200},
		{"Swift", 2900},
		{"C#", 2400},
		{"Ruby", 2100},
		{"PHP", 1800},
		{"Vue", 1500},
		{"Svelte", 1200},
		{"Zig", 1000},
		{"Elixir", 850},
		{"Scala", 700},
	}

	var total int64
	totals := make(map[string]int64)
	colors := make(map[string]string)

	for _, item := range raw {
		total += item.size
		totals[item.name] = item.size
		colors[item.name] = GetLanguageColor(item.name, "")
	}

	return buildUserStats("demo", totals, colors, total)
}
