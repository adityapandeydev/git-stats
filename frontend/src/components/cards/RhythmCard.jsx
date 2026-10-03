import React from 'react'
import { getTheme } from '../../constants/themes'

export default function RhythmCard({
  width = 424,
  height = 180,
  themeId = 'tokyonight',
}) {
  const theme = getTheme(themeId)
  const w = Number(width) || 424
  const h = Number(height) || 180
  const isHero = w >= 650

  const dividerX = isHero ? w - 180.0 : 290.0
  const rightColX = isHero ? w - 170.0 : 298.0

  // Standard 24h x 7d commit density matrix matching Zig preview
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

  // Pre-calculated cell color matrix for realistic developer activity pattern
  const cellRows = [
    // Mon
    ['#2e3c64','#2e3c64','#3d59a1','none','none','none','none','none','none','none','none','none','none','none','none','none','none','none','#bb9af7','#bb9af7','#bb9af7','#3d59a1','#3d59a1','#3d59a1'],
    // Tue
    ['#3d59a1','#3d59a1','#7aa2f7','none','none','none','none','none','none','none','none','none','none','none','none','none','none','none','#7aa2f7','#bb9af7','#bb9af7','#3d59a1','#3d59a1','#3d59a1'],
    // Wed
    ['#3d59a1','#7aa2f7','#7aa2f7','none','none','none','none','none','none','none','none','none','none','none','none','none','none','none','#bb9af7','#bb9af7','#7aa2f7','#3d59a1','#2e3c64','#2e3c64'],
    // Thu
    ['#2e3c64','#3d59a1','#3d59a1','none','none','none','none','none','none','none','none','none','none','none','none','none','none','none','#bb9af7','#bb9af7','#bb9af7','#7aa2f7','#3d59a1','#2e3c64'],
    // Fri
    ['#2e3c64','#2e3c64','#3d59a1','none','none','none','none','none','none','none','none','none','none','none','none','none','none','none','#7aa2f7','#bb9af7','#bb9af7','#3d59a1','#2e3c64','#2e3c64'],
    // Sat
    ['#3d59a1','#bb9af7','#bb9af7','none','none','none','none','none','none','none','none','none','none','none','none','none','none','none','#bb9af7','#bb9af7','#bb9af7','#7aa2f7','#3d59a1','#3d59a1'],
    // Sun
    ['#3d59a1','#3d59a1','#7aa2f7','none','none','none','none','none','none','none','none','none','none','none','none','none','none','none','#3d59a1','#3d59a1','#7aa2f7','#3d59a1','#2e3c64','#2e3c64'],
  ]

  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox={`0 0 ${w} ${h}`}
      width={w}
      height={h}
      className="rounded-[4.5px] transition-all duration-300 select-none shadow-lg"
    >
      <defs>
        <linearGradient id="rhythm-divider-grad" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor="#1a1b27" stopOpacity="0.0" />
          <stop offset="50%" stopColor="#3b4261" stopOpacity="0.7" />
          <stop offset="100%" stopColor="#1a1b27" stopOpacity="0.0" />
        </linearGradient>
        <linearGradient id="rhythm-day-grad" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stopColor="#70a5fd" />
          <stop offset="100%" stopColor="#7aa2f7" />
        </linearGradient>
        <linearGradient id="rhythm-night-grad" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stopColor="#bb9af7" />
          <stop offset="100%" stopColor="#9d7cd8" />
        </linearGradient>
      </defs>

      <style>{`
        .rhythm-title { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 12.5px; letter-spacing: 1.2px; fill: ${theme.title}; }
        .rhythm-sub { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 9px; letter-spacing: 0.5px; fill: #787c99; }
        .rhythm-lbl { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 600; font-size: 8px; fill: #565f89; }
        .rhythm-persona-txt { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 10px; letter-spacing: 0.6px; fill: #bb9af7; }
        .rhythm-kpi-lbl { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 8px; letter-spacing: 0.8px; fill: #7aa2f7; }
        .rhythm-kpi-val { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 13px; fill: #c0caf5; }
        .rhythm-stat-txt { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 600; font-size: 7.8px; letter-spacing: 0.2px; fill: #7982a9; }
        .rhythm-count-txt { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 8px; fill: #565f89; }
      `}</style>

      {/* Background */}
      <rect width={w} height={h} rx="4.5" fill={theme.bg} stroke={theme.border} strokeWidth="1" />

      {/* Header */}
      <text x="22" y="25.0" className="rhythm-title">COMMIT RHYTHM</text>
      <circle cx="152" cy="21.5" r="2.5" fill="#bb9af7" />
      <text x="160" y="24.5" className="rhythm-sub">24H × 7D MATRIX</text>

      {/* Day Labels */}
      {days.map((day, idx) => (
        <text key={idx} x="34" y={58.0 + idx * 12.0} className="rhythm-lbl" textAnchor="end">
          {day}
        </text>
      ))}

      {/* Heatmap Grid */}
      <g transform="translate(42.0, 50.0)">
        {cellRows.map((row, r) =>
          row.map((fill, c) => (
            <rect
              key={`${r}-${c}`}
              x={c * 10.0}
              y={r * 12.0}
              width="8.0"
              height="8.5"
              rx="2"
              fill={fill === 'none' ? '#1f2335' : fill}
              fillOpacity={fill === 'none' ? 0.35 : 1}
            />
          ))
        )}

        {/* Hour Labels */}
        <text x="0" y="94.0" className="rhythm-lbl" textAnchor="middle">12a</text>
        <text x="40" y="94.0" className="rhythm-lbl" textAnchor="middle">4a</text>
        <text x="80" y="94.0" className="rhythm-lbl" textAnchor="middle">8a</text>
        <text x="120" y="94.0" className="rhythm-lbl" textAnchor="middle">12p</text>
        <text x="160" y="94.0" className="rhythm-lbl" textAnchor="middle">4p</text>
        <text x="200" y="94.0" className="rhythm-lbl" textAnchor="middle">8p</text>
        <text x="230" y="94.0" className="rhythm-lbl" textAnchor="middle">11p</text>
      </g>

      {/* Divider */}
      <line x1={dividerX} y1="22" x2={dividerX} y2="158.0" stroke="url(#rhythm-divider-grad)" strokeWidth="1" />

      {/* Right Column: Persona & Analytics */}
      <g transform={`translate(${rightColX.toFixed(1)}, 0)`}>
        {/* Persona Badge Pill */}
        <g transform="translate(59, 38)">
          <rect x="-48" y="-12" width="96" height="24" rx="12" fill="#1f2335" stroke="#bb9af7" strokeOpacity="0.4" strokeWidth="1" />
          <text x="0" y="4" textAnchor="middle" className="rhythm-persona-txt">🌙 Night Owl</text>
        </g>

        {/* Peak Window KPI */}
        <g transform="translate(5, 72)">
          <text x="0" y="0" className="rhythm-kpi-lbl">PEAK WINDOW</text>
          <text x="0" y="15" className="rhythm-kpi-val">20:00 – 01:00</text>
        </g>

        {/* Circadian Split Bar */}
        <g transform="translate(5, 108)">
          <text x="0" y="0" className="rhythm-kpi-lbl">CIRCADIAN SPLIT</text>
          <rect x="0" y="6" width="108" height="6" rx="3" fill="#24283b" />
          <rect x="0" y="6" width="34.6" height="6" rx="3" fill="url(#rhythm-day-grad)" />
          <rect x="34.6" y="6" width="73.4" height="6" rx="3" fill="url(#rhythm-night-grad)" />
          <text x="0" y="23" className="rhythm-stat-txt">☀️ 32% Day</text>
          <text x="108" y="23" className="rhythm-stat-txt" textAnchor="end">🌙 68% Night</text>
        </g>

        {/* Analyzed Commits Footnote */}
        <text x="59" y="156" textAnchor="middle" className="rhythm-count-txt">640 Commits Mapped</text>
      </g>
    </svg>
  )
}
