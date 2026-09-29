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
	CardHeight    int
	LangsCount    int
	Columns       int
	Layout        string // "standard", "donut", "compact"
	HideTitle     bool
	CustomTitle   string
	Animate       bool
	BorderRadius  float64
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
			opts.BorderRadius = 4.5
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
	if width < 300 {
		width = 300
	} else if width > 1200 {
		width = 1200
	}
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
	minRequiredHeight := listStartY + (rows * rowHeight) + 16
	height := minRequiredHeight

	if opts.CardHeight > 0 {
		height = opts.CardHeight
		if height < minRequiredHeight {
			height = minRequiredHeight
		}
		if height > 1500 {
			height = 1500
		}

		// Maintain clean top (28px) and bottom (~30-35px) margins
		targetBottomMargin := paddingY + 7
		lastRowY := height - targetBottomMargin

		intervals := rows - 1
		if intervals < 1 {
			intervals = 1
		}

		barBottom := barY + barHeight
		availMiddle := lastRowY - barBottom

		// Proportionally distribute between barToList and row intervals
		// Total slots = intervals + 1 (the slot from bar to row 0, plus slots between rows)
		totalSlots := intervals + 1
		unitSpacing := availMiddle / totalSlots
		if unitSpacing > 80 {
			unitSpacing = 80
		} else if unitSpacing < 26 {
			unitSpacing = 26
		}

		rowHeight = unitSpacing
		barToList := availMiddle - (intervals * rowHeight)
		if barToList < 35 {
			barToList = 35
			if intervals > 0 {
				rowHeight = (availMiddle - barToList) / intervals
			}
		}
		listStartY = barBottom + barToList
	}

	var sb strings.Builder

	// SVG Header
	sb.WriteString(fmt.Sprintf(`<svg width="%d" height="%d" viewBox="0 0 %d %d" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="%s">`,
		width, height, width, height, html.EscapeString(title)))

	// Style Definitions
	sb.WriteString(`<style>`)
	sb.WriteString(fmt.Sprintf(`
		.card-bg { fill: %s; stroke: %s; stroke-width: 1px; rx: %gpx; }
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
	sb.WriteString(fmt.Sprintf(`<rect class="card-bg" x="0.5" y="0.5" width="%d" height="%d" rx="%g" fill="%s" %s/>`,
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

	// Multi-column Language List (Column-major: fills left column first; odd counts have 1 less on right)
	colWidth := float64(barWidth) / float64(cols)
	for i, l := range langs {
		colIdx, rowIdx := getColumnMajorPos(i, len(langs), cols)

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

// getColumnMajorPos computes column and row position filling left columns first.
// When total is odd, the left column gets (total+1)/2 and the right column gets 1 less.
func getColumnMajorPos(i int, total int, cols int) (int, int) {
	if cols <= 1 {
		return 0, i
	}
	base := total / cols
	rem := total % cols

	curIndex := 0
	for c := 0; c < cols; c++ {
		count := base
		if c < rem {
			count++
		}
		if i < curIndex+count {
			return c, i - curIndex
		}
		curIndex += count
	}
	return cols - 1, 0
}

// renderDonutLayout renders languages as a centered circular donut chart with a bottom 3-column grid.
func renderDonutLayout(langs []github.LanguageStat, opts RenderOptions) string {
	width := opts.CardWidth
	paddingX := 25
	paddingY := 28
	title := "Most Used Languages"
	if opts.CustomTitle != "" {
		title = opts.CustomTitle
	}

	// Donut centered horizontally
	chartCenterX := float64(width) / 2.0
	chartRadius := 44.0
	chartStroke := 12.0
	chartCenterY := 92.0
	if opts.HideTitle {
		chartCenterY = 66.0
	}

	// Bottom languages grid in 3 columns (or 2 if small)
	cols := opts.Columns
	if cols <= 0 {
		if len(langs) <= 4 {
			cols = 2
		} else if width < 420 {
			cols = 2
		} else {
			cols = 3
		}
	}
	if cols < 1 {
		cols = 1
	}
	if cols > 4 {
		cols = 4
	}

	rowHeight := 24
	gridStartY := int(chartCenterY + chartRadius + 26)
	rows := int(math.Ceil(float64(len(langs)) / float64(cols)))
	if rows < 1 {
		rows = 1
	}
	height := gridStartY + (rows * rowHeight) + 16

	var sb strings.Builder
	sb.WriteString(fmt.Sprintf(`<svg width="%d" height="%d" viewBox="0 0 %d %d" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="%s">`,
		width, height, width, height, html.EscapeString(title)))

	sb.WriteString(`<style>`)
	sb.WriteString(fmt.Sprintf(`
		.card-bg { fill: %s; stroke: %s; stroke-width: 1px; rx: %gpx; }
		.card-title { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 16px; font-weight: 600; fill: %s; }
		.lang-name { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 12px; font-weight: 500; fill: %s; }
		.lang-pct { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 11.5px; font-weight: 400; fill: %s; }
		.donut-track { fill: none; stroke: %s; stroke-width: %.1f; }
		.donut-segment { fill: none; stroke-width: %.1f; transition: stroke-dasharray 0.5s ease; }
	`, opts.Theme.BgColor, opts.Theme.BorderColor, opts.BorderRadius, opts.Theme.TitleColor, opts.Theme.TextColor, opts.Theme.MutedColor, opts.Theme.BarBgColor, chartStroke, chartStroke))

	if opts.Animate {
		sb.WriteString(`
		@keyframes fadeIn {
			from { opacity: 0; transform: translateY(4px); }
			to { opacity: 1; transform: translateY(0); }
		}
		.animate-item { animation: fadeIn 0.4s ease-out forwards; }
		`)
	}
	sb.WriteString(`</style>`)

	// Background
	strokeAttr := fmt.Sprintf(`stroke="%s"`, opts.Theme.BorderColor)
	if opts.HideBorder {
		strokeAttr = `stroke="transparent"`
	}
	sb.WriteString(fmt.Sprintf(`<rect class="card-bg" x="0.5" y="0.5" width="%d" height="%d" rx="%g" fill="%s" %s/>`,
		width-1, height-1, opts.BorderRadius, opts.Theme.BgColor, strokeAttr))

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
	sb.WriteString(fmt.Sprintf(`<text x="%.1f" y="%.1f" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="13" font-weight="700" fill="%s">%d</text>`,
		chartCenterX, chartCenterY-1, opts.Theme.TitleColor, len(langs)))
	sb.WriteString(fmt.Sprintf(`<text x="%.1f" y="%.1f" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="9.5" font-weight="500" fill="%s">LANGS</text>`,
		chartCenterX, chartCenterY+12, opts.Theme.MutedColor))

	// Bottom Languages Grid (filled across the bottom in 3 columns)
	gridWidth := float64(width - (paddingX * 2))
	colWidth := gridWidth / float64(cols)

	for i, l := range langs {
		colIdx, rowIdx := getColumnMajorPos(i, len(langs), cols)
		itemX := float64(paddingX) + (float64(colIdx) * colWidth)
		itemY := gridStartY + (rowIdx * rowHeight)

		delayStyle := ""
		if opts.Animate {
			delayStyle = fmt.Sprintf(` style="animation-delay: %dms;"`, 80+(i*35))
		}

		dotRadius := 4.0
		dotY := float64(itemY) - 4.0
		textY := float64(itemY)

		sb.WriteString(fmt.Sprintf(`<g class="animate-item"%s>`, delayStyle))
		// Color Dot
		sb.WriteString(fmt.Sprintf(`<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s"/>`,
			itemX+4, dotY, dotRadius, l.Color))

		// Language Name
		sb.WriteString(fmt.Sprintf(`<text x="%.1f" y="%.1f" class="lang-name">%s</text>`,
			itemX+14, textY, html.EscapeString(l.Name)))

		// Percentage
		pctX := itemX + colWidth - 10
		sb.WriteString(fmt.Sprintf(`<text x="%.1f" y="%.1f" text-anchor="end" class="lang-pct">%.1f%%</text>`,
			pctX, textY, l.Percentage))

		sb.WriteString(`</g>`)
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
		.card-bg { fill: %s; stroke: %s; stroke-width: 1px; rx: %gpx; }
		.card-title { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 14px; font-weight: 600; fill: %s; }
		.lang-name { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 11px; font-weight: 500; fill: %s; }
		.bar-bg { fill: %s; rx: 4px; }
	`, opts.Theme.BgColor, opts.Theme.BorderColor, opts.BorderRadius, opts.Theme.TitleColor, opts.Theme.TextColor, opts.Theme.BarBgColor))
	sb.WriteString(`</style>`)

	sb.WriteString(fmt.Sprintf(`<rect class="card-bg" x="0.5" y="0.5" width="%d" height="%d" rx="%g"/>`,
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
