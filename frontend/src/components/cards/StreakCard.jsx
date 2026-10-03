import React from 'react'
import { getTheme } from '../../constants/themes'

export default function StreakCard({
  width = 424,
  height = 180,
  themeId = 'tokyonight',
  sparkline = true,
  userData,
}) {
  const theme = getTheme(themeId)
  const w = Number(width) || 424
  const h = Number(height) || 180

  const current = userData?.currentStreak ?? 84
  const longest = userData?.longestStreak ?? 128
  const total = userData?.totalCommits ?? 1420

  const col1X = w * 0.22
  const col2X = w * 0.50
  const col3X = w * 0.78
  const div1X = w * 0.355
  const div2X = w * 0.645

  // Generate smooth 14-day sparkline coordinates spanning from x=24 to x=w-24
  const sparkStart = 24.0
  const sparkEnd = w - 24.0
  const sparkW = sparkEnd - sparkStart
  const numPts = 14
  const rawYValues = [148, 142, 150, 138, 144, 132, 136, 126, 134, 122, 128, 116, 120, 112]
  const pts = rawYValues.map((y, i) => ({
    x: sparkStart + (i / (numPts - 1)) * sparkW,
    y,
  }))

  const sparkPathD = pts.reduce((acc, pt, i) => {
    if (i === 0) return `M ${pt.x.toFixed(1)} ${pt.y.toFixed(1)}`
    const prev = pts[i - 1]
    const cx1 = (prev.x + pt.x) / 2
    return `${acc} C ${cx1.toFixed(1)} ${prev.y.toFixed(1)}, ${cx1.toFixed(1)} ${pt.y.toFixed(1)}, ${pt.x.toFixed(1)} ${pt.y.toFixed(1)}`
  }, '')

  const sparkFillD = `${sparkPathD} L ${sparkEnd.toFixed(1)} ${h} L ${sparkStart.toFixed(1)} ${h} Z`

  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox={`0 0 ${w} ${h}`}
      width={w}
      height={h}
      className="rounded-[4.5px] transition-all duration-300 select-none shadow-lg"
    >
      <defs>
        <filter id="streak-core-glow" x="-50%" y="-50%" width="200%" height="200%">
          <feGaussianBlur in="SourceGraphic" stdDeviation="4" result="blur1" />
          <feGaussianBlur in="SourceGraphic" stdDeviation="8" result="blur2" />
          <feMerge>
            <feMergeNode in="blur2" />
            <feMergeNode in="blur1" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
        <linearGradient id="flame-grad" x1="0%" y1="100%" x2="0%" y2="0%">
          <stop offset="0%" stopColor="#ff9e64" />
          <stop offset="100%" stopColor="#f7768e" />
        </linearGradient>
        <radialGradient id="energy-aura" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#f7768e" stopOpacity="0.30" />
          <stop offset="60%" stopColor="#ff9e64" stopOpacity="0.08" />
          <stop offset="100%" stopColor="#1a1b27" stopOpacity="0.0" />
        </radialGradient>
        <linearGradient id="divider-grad" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor="#70a5fd" stopOpacity="0.0" />
          <stop offset="50%" stopColor="#70a5fd" stopOpacity="0.35" />
          <stop offset="100%" stopColor="#70a5fd" stopOpacity="0.0" />
        </linearGradient>
        <linearGradient id="sparkline-grad" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stopColor="#70a5fd" />
          <stop offset="50%" stopColor="#f7768e" />
          <stop offset="100%" stopColor="#ff9e64" />
        </linearGradient>
        <linearGradient id="sparkline-fill" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor="#f7768e" stopOpacity="0.22" />
          <stop offset="100%" stopColor="#1a1b27" stopOpacity="0.0" />
        </linearGradient>
      </defs>

      <style>{`
        @keyframes flamePulse {
          0%, 100% { transform: scale(1.0); }
          50% { transform: scale(1.08); }
        }
        @keyframes ringSpin {
          from { stroke-dashoffset: 0; }
          to { stroke-dashoffset: 48; }
        }
        .stat-val { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; }
        .stat-lbl { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 600; }
        .stat-sub { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 400; }
        .spark-lbl { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; }
      `}</style>

      {/* Card Background */}
      <rect width={w} height={h} rx="4.5" fill={theme.bg} stroke={theme.border} strokeWidth="1" />

      {/* Vertical Glass Dividers */}
      <line x1={div1X} y1="22.0" x2={div1X} y2="130.0" stroke="url(#divider-grad)" strokeWidth="1" />
      <line x1={div2X} y1="22.0" x2={div2X} y2="130.0" stroke="url(#divider-grad)" strokeWidth="1" />

      {/* Left Column: Total Contributions */}
      <g transform={`translate(${col1X.toFixed(1)}, 0.0)`}>
        <text x="0" y="60" textAnchor="middle" className="stat-val" fontSize="24" fill="#70a5fd">
          {total.toLocaleString()}
        </text>
        <text x="0" y="80" textAnchor="middle" className="stat-lbl" fontSize="11" fill="#c0caf5">
          Total Contributions
        </text>
        <text x="0" y="96" textAnchor="middle" className="stat-sub" fontSize="9" fill="#787c99">
          May 12, 2023 - Present
        </text>
      </g>

      {/* Center Column: Current Streak Hero */}
      <g transform={`translate(${col2X.toFixed(1)}, 0.0)`}>
        {/* Glow Aura & Spinning Ring */}
        <circle cx="0" cy="52" r="38" fill="url(#energy-aura)" />
        <circle
          cx="0"
          cy="52"
          r="28"
          fill="none"
          stroke="#ff9e64"
          strokeWidth="2.5"
          strokeDasharray="14 10"
          style={{ animation: 'ringSpin 8s linear infinite', transformOrigin: '0px 52px' }}
        />
        {/* Flame Path */}
        <g transform="translate(0, 48)">
          <path
            d="M 0 14 C -6 7 -11 2 -11 -5 C -11 -13 -4 -18 0 -22 C 4 -18 11 -13 11 -5 C 11 2 6 7 0 14 Z"
            fill="url(#flame-grad)"
            filter="url(#streak-core-glow)"
          />
        </g>
        <text x="0" y="60" textAnchor="middle" className="stat-val" fontSize="28" fill="url(#flame-grad)">
          {current}
        </text>
        <text x="0" y="78" textAnchor="middle" className="stat-lbl" fontSize="11" fill="#ff9e64">
          Current Streak
        </text>
        {/* Tier Pill */}
        <g transform="translate(0, 88)">
          <rect x="-44" y="0" width="88" height="17" rx="8.5" fill="#f7768e" fillOpacity="0.16" stroke="#ff9e64" strokeWidth="0.8" />
          <text x="0" y="11.5" textAnchor="middle" fontSize="7.8" fontWeight="800" fill="#ff9e64" letterSpacing="0.4px">
            🔥 ACTIVE STREAK
          </text>
        </g>
      </g>

      {/* Right Column: Longest Streak */}
      <g transform={`translate(${col3X.toFixed(1)}, 0.0)`}>
        <text x="0" y="60" textAnchor="middle" className="stat-val" fontSize="24" fill="#c0caf5">
          {longest}
        </text>
        <text x="0" y="80" textAnchor="middle" className="stat-lbl" fontSize="11" fill="#c0caf5">
          Longest Streak
        </text>
        <text x="0" y="96" textAnchor="middle" className="stat-sub" fontSize="9" fill="#787c99">
          Jan 2 - May 10, 2024
        </text>
      </g>

      {/* 14-Day Momentum Sparkline */}
      {sparkline && (
        <g>
          <path d={sparkFillD} fill="url(#sparkline-fill)" />
          <path d={sparkPathD} fill="none" stroke="url(#sparkline-grad)" strokeWidth="2.2" strokeLinecap="round" />
          {pts.map((pt, i) => (
            <circle
              key={i}
              cx={pt.x}
              cy={pt.y}
              r={i === pts.length - 1 ? 3.5 : 2}
              fill={i === pts.length - 1 ? '#ff9e64' : '#70a5fd'}
              stroke="#1a1b27"
              strokeWidth="1"
            />
          ))}
          <text x="24" y="172" className="spark-lbl" fontSize="8" fill="#787c99" letterSpacing="0.5px">
            14-DAY MOMENTUM
          </text>
        </g>
      )}
    </svg>
  )
}
