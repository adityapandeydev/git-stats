package handlers

import (
	"fmt"
	"html"

	"git-stats/internal/renderer"
)

// RenderErrorSVG returns a neat SVG displaying the error message gracefully.
func RenderErrorSVG(msg string, theme renderer.Theme, width int) string {
	if width <= 0 {
		width = 450
	}
	height := 130
	radius := theme.BorderRadius
	if radius <= 0 {
		radius = 4.5
	}

	return fmt.Sprintf(`<svg width="%d" height="%d" viewBox="0 0 %d %d" fill="none" xmlns="http://www.w3.org/2000/svg">
	<style>
		.card-bg { fill: %s; stroke: #ff5555; stroke-width: 1px; rx: %gpx; }
		.title { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 15px; font-weight: 600; fill: #ff5555; }
		.msg { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 12px; fill: %s; }
	</style>
	<rect class="card-bg" x="0.5" y="0.5" width="%d" height="%d" rx="%g"/>
	<circle cx="35" cy="40" r="10" fill="#ff5555" fill-opacity="0.2"/>
	<text x="31" y="44" fill="#ff5555" font-family="sans-serif" font-weight="bold" font-size="12">!</text>
	<text x="55" y="45" class="title">GitStats Error</text>
	<text x="35" y="80" class="msg">%s</text>
</svg>`,
		width, height, width, height,
		theme.BgColor, radius, theme.TextColor,
		width-1, height-1, radius,
		html.EscapeString(msg),
	)
}
