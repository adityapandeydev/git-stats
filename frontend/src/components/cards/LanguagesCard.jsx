import React from 'react'
import { getTheme } from '../../constants/themes'
import { computeLanguagesHeight } from '../../constants/cards'

const FALLBACK_LANGUAGES = [
  { name: 'TypeScript', percent: 32.16, color: '#3178c6' },
  { name: 'Python', percent: 20.34, color: '#3572A5' },
  { name: 'Rust', percent: 16.19, color: '#dea584' },
  { name: 'Java', percent: 12.62, color: '#b07219' },
  { name: 'C++', percent: 8.14, color: '#f34b7d' },
  { name: 'JavaScript', percent: 5.31, color: '#f1e05a' },
  { name: 'Shell', percent: 3.16, color: '#89e051' },
  { name: 'C#', percent: 2.08, color: '#178600' },
  { name: 'Go', percent: 1.85, color: '#00add8' },
  { name: 'Zig', percent: 1.45, color: '#f7a41d' },
  { name: 'HTML', percent: 1.20, color: '#e34c26' },
  { name: 'CSS', percent: 0.95, color: '#563d7c' },
  { name: 'Lua', percent: 0.65, color: '#000080' },
  { name: 'Swift', percent: 0.45, color: '#F05138' },
  { name: 'Kotlin', percent: 0.35, color: '#A97BFF' },
  { name: 'Ruby', percent: 0.25, color: '#701516' },
]

export default function LanguagesCard({
  width = 400,
  height,
  themeId = 'tokyonight',
  langsCount = 12,
  userData,
}) {
  const theme = getTheme(themeId)
  const count = Math.min(16, Math.max(6, Number(langsCount) || 12))
  
  const rawList = userData?.topLanguages && userData.topLanguages.length >= 6
    ? userData.topLanguages
    : FALLBACK_LANGUAGES

  const selectedLangs = rawList.slice(0, count)
  const totalRaw = selectedLangs.reduce((sum, l) => sum + (l.percent || 1), 0)

  // Normalize percentages to sum to 100%
  const languages = selectedLangs.map((l) => ({
    ...l,
    normalizedPct: ((l.percent || 1) / totalRaw) * 100,
  }))

  const rows = Math.max(1, Math.ceil(languages.length / 2))
  const computedHeight = computeLanguagesHeight(languages.length)
  const actualHeight = height ? Math.max(height, computedHeight) : computedHeight
  const barWidth = width - 50 // 350 for 400 width

  // Compute segment positions along the bar
  let currentOffset = 25.0
  const barSegments = languages.map((lang) => {
    const segW = (lang.normalizedPct / 100) * barWidth
    const seg = { ...lang, x: currentOffset, w: segW }
    currentOffset += segW
    return seg
  })

  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      role="img"
      aria-label="Most Used Languages"
      viewBox={`0 0 ${width} ${actualHeight}`}
      width={width}
      height={actualHeight}
      className="rounded-[4.5px] transition-all duration-300 select-none shadow-lg"
    >
      <style>{`
        .card-title { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 16px; font-weight: 600; fill: ${theme.title}; }
        .lang-name { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 12.5px; font-weight: 500; fill: #c0caf5; }
        .lang-pct { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 12px; font-weight: 400; fill: #7982a9; }
        .bar-bg { fill: #212337; rx: 5px; }
        .bar-segment { transition: all 0.3s ease; }
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(4px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .animate-item { animation: fadeIn 0.4s ease-out forwards; }
      `}</style>

      <rect
        width={width}
        height={actualHeight}
        rx="4.5"
        fill={theme.bg}
        stroke={theme.border}
        strokeWidth="1"
      />

      <text x="25" y="28" className="card-title">Most Used Languages</text>

      <defs>
        <clipPath id="lang-bar-clip">
          <rect x="25" y="52" width={barWidth} height="10" rx="5" ry="5" />
        </clipPath>
      </defs>

      <rect className="bar-bg" x="25" y="52" width={barWidth} height="10" rx="5" />

      {/* Progress Bar Segments */}
      <g clipPath="url(#lang-bar-clip)" className="bar-container">
        {barSegments.map((seg, idx) => (
          <rect
            key={idx}
            x={seg.x.toFixed(2)}
            y="52"
            width={seg.w.toFixed(2)}
            height="10"
            fill={seg.color}
            className="bar-segment"
          >
            <title>{`${seg.name}: ${seg.normalizedPct.toFixed(2)}%`}</title>
          </rect>
        ))}
      </g>

      {/* 2-Column Languages List */}
      {languages.map((lang, idx) => {
        const isLeftCol = idx < rows
        const colIdx = isLeftCol ? 0 : 1
        const rowIdx = isLeftCol ? idx : idx - rows

        const dotX = colIdx === 0 ? 30.0 : 205.0
        const nameX = colIdx === 0 ? 41.0 : 216.0
        const pctX = colIdx === 0 ? 185.0 : 360.0
        const itemY = 91.5 + rowIdx * 34
        const textY = 96.0 + rowIdx * 34
        const delay = 100 + idx * 40

        return (
          <g key={idx} className="animate-item" style={{ animationDelay: `${delay}ms` }}>
            <circle cx={dotX} cy={itemY} r="4.5" fill={lang.color} />
            <text x={nameX} y={textY} className="lang-name">{lang.name}</text>
            <text x={pctX} y={textY} textAnchor="end" className="lang-pct">
              {lang.normalizedPct.toFixed(2)}%
            </text>
          </g>
        )
      })}
    </svg>
  )
}
