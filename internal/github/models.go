package github

// LanguageStat represents a single language's statistics.
type LanguageStat struct {
	Name       string  `json:"name"`
	Color      string  `json:"color"`
	Size       int64   `json:"size"`
	Percentage float64 `json:"percentage"`
}

// UserStats represents aggregated language stats for a GitHub user.
type UserStats struct {
	Username   string         `json:"username"`
	TotalBytes int64          `json:"total_bytes"`
	Languages  []LanguageStat `json:"languages"`
}

// GraphQLResponse models GitHub's GraphQL API response for repository languages.
type GraphQLResponse struct {
	Data struct {
		User struct {
			Repositories struct {
				PageInfo struct {
					HasNextPage bool   `json:"hasNextPage"`
					EndCursor   string `json:"endCursor"`
				} `json:"pageInfo"`
				Nodes []struct {
					Name      string `json:"name"`
					IsFork    bool   `json:"isFork"`
					Languages struct {
						Edges []struct {
							Size int64 `json:"size"`
							Node struct {
								Name  string `json:"name"`
								Color string `json:"color"`
							} `json:"node"`
						} `json:"edges"`
					} `json:"languages"`
				} `json:"nodes"`
			} `json:"repositories"`
		} `json:"user"`
	} `json:"data"`
	Errors []struct {
		Message string `json:"message"`
	} `json:"errors"`
}

// RestRepo models the GitHub REST API repository response.
type RestRepo struct {
	Name   string `json:"name"`
	Fork   bool   `json:"fork"`
	Owner  struct {
		Login string `json:"login"`
	} `json:"owner"`
}
