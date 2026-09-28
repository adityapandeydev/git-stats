package renderer

import (
	"fmt"
	"html"
	"math"
	"strings"

	"git-stats/internal/github"
)

// RenderOptions defines configuration for the SVG generator.
type RenderOptions struct {
	Theme         Theme
	CardWidth     int
	LangsCount    int
	Columns       int
	Layout        string // "standard", "donut", "compact"
	HideTitle     bool
	CustomTitle   string
	Animate       bool
	BorderRadius  int
	HideBorder    bool
	ShowPercent   bool
}

// RenderSVG generates an SVG string representing the language stats.
func RenderSVG(stats *github.UserStats, opts RenderOptions) string {
	if opts.CardWidth <= 0 {
		opts.CardWidth = 450
	}
	if opts.LangsCount <= 0 {
		opts.LangsCount = 8
	}
	if opts.Layout == "" {
		opts.Layout = "standard"
	}
	if opts.BorderRadius <= 0 {
		opts.BorderRadius = opts.Theme.BorderRadius
		if opts.BorderRadius <= 0 {
			opts.BorderRadius = 10
		}
	}

	// Filter languages up to LangsCount
	langs := stats.Languages
	if len(langs) > opts.LangsCount {
		langs = langs[:opts.LangsCount]
	}

	// Recalculate percentages for the visible slice so the bar fills 100%
	var totalVisibleBytes int64
	for _, l := range langs {
		totalVisibleBytes += l.Size
	}

	for i := range langs {
		if totalVisibleBytes > 0 {
			langs[i].Percentage = (float64(langs[i].Size) / float64(totalVisibleBytes)) * 100.0
		} else {
			langs[i].Percentage = 0
		}
	}

	switch strings.ToLower(opts.Layout) {
	case "donut":
		return renderDonutLayout(langs, opts)
	case "compact":
		return renderCompactLayout(langs, opts)
	default:
		return renderStandardLayout(langs, opts)
	}
}

// renderStandardLayout produces the segmented bar + multi-column grid layout (matching user's screenshot).
func renderStandardLayout(langs []github.LanguageStat, opts RenderOptions) string {
	width := opts.CardWidth
	paddingX := 25
	paddingY := 28

	title := "Most Used Languages"
	if opts.CustomTitle != "" {
		title = opts.CustomTitle
	}

	// Determine number of columns
	cols := opts.Columns
	if cols <= 0 {
		if len(langs) <= 4 {
			cols = 1
		} else if len(langs) > 10 && width >= 550 {
			cols = 3
		} else {
			cols = 2
		}
	}
	if cols < 1 {
		cols = 1
	}
	if cols > 3 {
		cols = 3
	}

	// Calculate rows
	rows := int(math.Ceil(float64(len(langs)) / float64(cols)))
	if rows < 1 {
		rows = 1
	}

	// Layout spacing constants
	barY := 52
	if opts.HideTitle {
		barY = 28
	}
	barHeight := 10
	barWidth := width - (paddingX * 2)

	rowHeight := 26
	listStartY := barY + barHeight + 22
	contentBottom := listStartY + (rows * rowHeight)
	height := contentBottom + 12

	var sb strings.Builder

	// SVG Header
	sb.WriteString(fmt.Sprintf(`<svg width="%d" height="%d" viewBox="0 0 %d %d" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="%s">`,
		width, height, width, height, html.EscapeString(title)))

	// Style Definitions
	sb.WriteString(`<style>`)
	sb.WriteString(fmt.Sprintf(`
		.card-bg { fill: %s; stroke: %s; stroke-width: 1px; rx: %dpx; }
		.card-title { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 16px; font-weight: 600; fill: %s; }
		.lang-name { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 12.5px; font-weight: 500; fill: %s; }
		.lang-pct { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 12px; font-weight: 400; fill: %s; }
		.bar-bg { fill: %s; rx: 5px; }
		.bar-segment { transition: all 0.3s ease; }
	`, opts.Theme.BgColor, opts.Theme.BorderColor, opts.BorderRadius, opts.Theme.TitleColor, opts.Theme.TextColor, opts.Theme.MutedColor, opts.Theme.BarBgColor))

	if opts.Animate {
		sb.WriteString(`
		@keyframes fadeIn {
			from { opacity: 0; transform: translateY(4px); }
			to { opacity: 1; transform: translateY(0); }
		}
		@keyframes scaleBar {
			from { transform: scaleX(0); }
			to { transform: scaleX(1); }
		}
		.animate-item { animation: fadeIn 0.4s ease-out forwards; }
		.bar-container { transform-origin: left; animation: scaleBar 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
		`)
	}
	sb.WriteString(`</style>`)

	// Card Background
	strokeAttr := fmt.Sprintf(`stroke="%s"`, opts.Theme.BorderColor)
	if opts.HideBorder {
		strokeAttr = `stroke="transparent"`
	}
	sb.WriteString(fmt.Sprintf(`<rect class="card-bg" x="0.5" y="0.5" width="%d" height="%d" rx="%d" fill="%s" %s/>`,
		width-1, height-1, opts.BorderRadius, opts.Theme.BgColor, strokeAttr))

	// Card Title
	if !opts.HideTitle {
		sb.WriteString(fmt.Sprintf(`<text x="%d" y="%d" class="card-title">%s</text>`,
			paddingX, paddingY, html.EscapeString(title)))
	}

	// Progress Bar Container & Clip Path
	clipID := "bar-clip"
	sb.WriteString(fmt.Sprintf(`
	<defs>
		<clipPath id="%s">
			<rect x="%d" y="%d" width="%d" height="%d" rx="5" ry="5"/>
		</clipPath>
	</defs>
	`, clipID, paddingX, barY, barWidth, barHeight))

	// Background track
	sb.WriteString(fmt.Sprintf(`<rect class="bar-bg" x="%d" y="%d" width="%d" height="%d" rx="5"/>`,
		paddingX, barY, barWidth, barHeight))

	// Progress Bar Segments
	sb.WriteString(fmt.Sprintf(`<g clip-path="url(#%s)" class="bar-container">`, clipID))
	currentX := float64(paddingX)
	for _, l := range langs {
		segWidth := (l.Percentage / 100.0) * float64(barWidth)
		if segWidth < 1.0 && l.Percentage > 0 {
			segWidth = 1.0 // Ensure visible sliver
		}
		sb.WriteString(fmt.Sprintf(`<rect x="%.2f" y="%d" width="%.2f" height="%d" fill="%s" class="bar-segment"><title>%s: %.2f%%</title></rect>`,
			currentX, barY, segWidth, barHeight, l.Color, html.EscapeString(l.Name), l.Percentage))
		currentX += segWidth
	}
	sb.WriteString(`</g>`)

	// Multi-column Language List
	colWidth := float64(barWidth) / float64(cols)
	for i, l := range langs {
		colIdx := i % cols
		rowIdx := i / cols

		itemX := float64(paddingX) + (float64(colIdx) * colWidth)
		itemY := listStartY + (rowIdx * rowHeight)

		delayStyle := ""
		if opts.Animate {
			delayStyle = fmt.Sprintf(` style="animation-delay: %dms;"`, 100+(i*40))
		}

		dotRadius := 4.5
		dotY := float64(itemY) - 4.5
		textY := float64(itemY)

		sb.WriteString(fmt.Sprintf(`<g class="animate-item"%s>`, delayStyle))
		// Color Dot
		sb.WriteString(fmt.Sprintf(`<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s"/>`,
			itemX+5, dotY, dotRadius, l.Color))

		// Language Name
		sb.WriteString(fmt.Sprintf(`<text x="%.1f" y="%.1f" class="lang-name">%s</text>`,
			itemX+16, textY, html.EscapeString(l.Name)))

		// Percentage
		pctX := itemX + colWidth - 15
		if cols == 1 {
			pctX = float64(width - paddingX)
		}
		sb.WriteString(fmt.Sprintf(`<text x="%.1f" y="%.1f" text-anchor="end" class="lang-pct">%.2f%%</text>`,
			pctX, textY, l.Percentage))

		sb.WriteString(`</g>`)
	}

	sb.WriteString(`</svg>`)
	return sb.String()
}

// renderDonutLayout renders languages as a circular donut chart with legend.
func renderDonutLayout(langs []github.LanguageStat, opts RenderOptions) string {
	width := opts.CardWidth
	paddingX := 25
	paddingY := 28
	title := "Most Used Languages"
	if opts.CustomTitle != "" {
		title = opts.CustomTitle
	}

	chartRadius := 50.0
	chartStroke := 14.0
	chartCenterX := float64(paddingX) + chartRadius + 10
	chartCenterY := 95.0
	if opts.HideTitle {
		chartCenterY = 75.0
	}

	// Height calculation
	legendStartY := 55
	if opts.HideTitle {
		legendStartY = 30
	}
	legendRows := len(langs)
	legendHeight := legendRows * 22
	height := int(math.Max(float64(legendStartY+legendHeight+20), chartCenterY+chartRadius+30))

	var sb strings.Builder
	sb.WriteString(fmt.Sprintf(`<svg width="%d" height="%d" viewBox="0 0 %d %d" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="%s">`,
		width, height, width, height, html.EscapeString(title)))

	sb.WriteString(`<style>`)
	sb.WriteString(fmt.Sprintf(`
		.card-bg { fill: %s; stroke: %s; stroke-width: 1px; rx: %dpx; }
		.card-title { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 16px; font-weight: 600; fill: %s; }
		.lang-name { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 12.5px; font-weight: 500; fill: %s; }
		.lang-pct { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 12px; font-weight: 400; fill: %s; }
		.donut-track { fill: none; stroke: %s; stroke-width: %.1f; }
		.donut-segment { fill: none; stroke-width: %.1f; transition: stroke-dasharray 0.5s ease; }
	`, opts.Theme.BgColor, opts.Theme.BorderColor, opts.BorderRadius, opts.Theme.TitleColor, opts.Theme.TextColor, opts.Theme.MutedColor, opts.Theme.BarBgColor, chartStroke, chartStroke))
	sb.WriteString(`</style>`)

	// Background
	sb.WriteString(fmt.Sprintf(`<rect class="card-bg" x="0.5" y="0.5" width="%d" height="%d" rx="%d"/>`,
		width-1, height-1, opts.BorderRadius))

	if !opts.HideTitle {
		sb.WriteString(fmt.Sprintf(`<text x="%d" y="%d" class="card-title">%s</text>`,
			paddingX, paddingY, html.EscapeString(title)))
	}

	// Donut Chart
	circumference := 2 * math.Pi * chartRadius
	sb.WriteString(fmt.Sprintf(`<circle class="donut-track" cx="%.1f" cy="%.1f" r="%.1f"/>`,
		chartCenterX, chartCenterY, chartRadius))

	accumulatedOffset := 0.0
	for _, l := range langs {
		dashLength := (l.Percentage / 100.0) * circumference
		sb.WriteString(fmt.Sprintf(`
		<circle class="donut-segment" cx="%.1f" cy="%.1f" r="%.1f" stroke="%s"
			stroke-dasharray="%.2f %.2f" stroke-dashoffset="%.2f"
			transform="rotate(-90 %.1f %.1f)">
			<title>%s: %.2f%%</title>
		</circle>`,
			chartCenterX, chartCenterY, chartRadius, l.Color,
			dashLength, circumference-dashLength, -accumulatedOffset,
			chartCenterX, chartCenterY, html.EscapeString(l.Name), l.Percentage))
		accumulatedOffset += dashLength
	}

	// Donut Center Text
	sb.WriteString(fmt.Sprintf(`<text x="%.1f" y="%.1f" text-anchor="middle" font-family="sans-serif" font-size="12" font-weight="600" fill="%s">%d Langs</text>`,
		chartCenterX, chartCenterY+4, opts.Theme.TextColor, len(langs)))

	// Legend (right side)
	legendX := chartCenterX + chartRadius + 30
	for i, l := range langs {
		itemY := legendStartY + (i * 22)
		sb.WriteString(fmt.Sprintf(`<circle cx="%.1f" cy="%.1f" r="4.5" fill="%s"/>`,
			legendX, float64(itemY)-4.0, l.Color))
		sb.WriteString(fmt.Sprintf(`<text x="%.1f" y="%d" class="lang-name">%s</text>`,
			legendX+12, itemY, html.EscapeString(l.Name)))
		sb.WriteString(fmt.Sprintf(`<text x="%d" y="%d" text-anchor="end" class="lang-pct">%.2f%%</text>`,
			width-paddingX, itemY, l.Percentage))
	}

	sb.WriteString(`</svg>`)
	return sb.String()
}

// renderCompactLayout renders a sleek compact badge bar.
func renderCompactLayout(langs []github.LanguageStat, opts RenderOptions) string {
	width := opts.CardWidth
	paddingX := 20
	barHeight := 8
	barY := 42
	if opts.HideTitle {
		barY = 20
	}
	barWidth := width - (paddingX * 2)

	title := "Most Used Languages"
	if opts.CustomTitle != "" {
		title = opts.CustomTitle
	}

	// Badges layout below bar
	tagY := barY + barHeight + 18
	height := tagY + 24

	var sb strings.Builder
	sb.WriteString(fmt.Sprintf(`<svg width="%d" height="%d" viewBox="0 0 %d %d" fill="none" xmlns="http://www.w3.org/2000/svg">`,
		width, height, width, height))

	sb.WriteString(`<style>`)
	sb.WriteString(fmt.Sprintf(`
		.card-bg { fill: %s; stroke: %s; stroke-width: 1px; rx: %dpx; }
		.card-title { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 14px; font-weight: 600; fill: %s; }
		.lang-name { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 11px; font-weight: 500; fill: %s; }
		.bar-bg { fill: %s; rx: 4px; }
	`, opts.Theme.BgColor, opts.Theme.BorderColor, opts.BorderRadius, opts.Theme.TitleColor, opts.Theme.TextColor, opts.Theme.BarBgColor))
	sb.WriteString(`</style>`)

	sb.WriteString(fmt.Sprintf(`<rect class="card-bg" x="0.5" y="0.5" width="%d" height="%d" rx="%d"/>`,
		width-1, height-1, opts.BorderRadius))

	if !opts.HideTitle {
		sb.WriteString(fmt.Sprintf(`<text x="%d" y="24" class="card-title">%s</text>`,
			paddingX, html.EscapeString(title)))
	}

	// Bar
	sb.WriteString(fmt.Sprintf(`<rect class="bar-bg" x="%d" y="%d" width="%d" height="%d" rx="4"/>`,
		paddingX, barY, barWidth, barHeight))

	clipID := "compact-bar-clip"
	sb.WriteString(fmt.Sprintf(`
	<defs>
		<clipPath id="%s">
			<rect x="%d" y="%d" width="%d" height="%d" rx="4"/>
		</clipPath>
	</defs>
	<g clip-path="url(#%s)">`, clipID, paddingX, barY, barWidth, barHeight, clipID))

	currentX := float64(paddingX)
	for _, l := range langs {
		segWidth := (l.Percentage / 100.0) * float64(barWidth)
		if segWidth < 1.0 && l.Percentage > 0 {
			segWidth = 1.0
		}
		sb.WriteString(fmt.Sprintf(`<rect x="%.2f" y="%d" width="%.2f" height="%d" fill="%s"><title>%s: %.2f%%</title></rect>`,
			currentX, barY, segWidth, barHeight, l.Color, html.EscapeString(l.Name), l.Percentage))
		currentX += segWidth
	}
	sb.WriteString(`</g>`)

	// Tags below
	curTagX := float64(paddingX)
	for _, l := range langs {
		if curTagX+60 > float64(width-paddingX) {
			break
		}
		sb.WriteString(fmt.Sprintf(`<circle cx="%.1f" cy="%.1f" r="3.5" fill="%s"/>`,
			curTagX+4, float64(tagY)-3.5, l.Color))
		sb.WriteString(fmt.Sprintf(`<text x="%.1f" y="%d" class="lang-name">%s %.0f%%</text>`,
			curTagX+12, tagY, html.EscapeString(l.Name), l.Percentage))
		curTagX += float64(len(l.Name)*7 + 45)
	}

	sb.WriteString(`</svg>`)
	return sb.String()
}
