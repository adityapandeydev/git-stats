import React from 'react'
import { getTheme } from '../../constants/themes'

export default function StatsCard({
  width = 424,
  height = 180,
  themeId = 'tokyonight',
  userData,
}) {
  const theme = getTheme(themeId)
  const w = Number(width) || 424
  const h = Number(height) || 180
  const isHero = w >= 650

  const commits = userData?.totalCommits ?? 1450
  const prs = userData?.mergedPRs ?? 24
  const stars = userData?.totalStars ?? 65
  const repos = userData?.totalRepos ?? 14
  const rating = userData?.craftRating ?? 'S+'

  const tileW = isHero ? (w - 290) / 2 : 108.0
  const tileH = 56.0
  const dividerX = isHero ? w - 240.0 : 254.0
  const gaugeCenterX = isHero ? w - 120.0 : 335.0
  const pillStartX = gaugeCenterX - 57.0

  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox={`0 0 ${w} ${h}`}
      width={w}
      height={h}
      className="rounded-[4.5px] transition-all duration-300 select-none shadow-lg"
    >
      <defs>
        <filter id="stats-ring-glow" x="-50%" y="-50%" width="200%" height="200%">
          <feGaussianBlur in="SourceGraphic" stdDeviation="4" result="blur1" />
          <feGaussianBlur in="SourceGraphic" stdDeviation="10" result="blur2" />
          <feMerge>
            <feMergeNode in="blur2" />
            <feMergeNode in="blur1" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
        <linearGradient id="stats-tier-grad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#f7768e" />
          <stop offset="100%" stopColor="#ff9e64" />
        </linearGradient>
        <linearGradient id="stats-divider-grad" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor="#1a1b27" stopOpacity="0.0" />
          <stop offset="50%" stopColor="#3b4261" stopOpacity="0.7" />
          <stop offset="100%" stopColor="#1a1b27" stopOpacity="0.0" />
        </linearGradient>
        <radialGradient id="stats-ring-aura" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#f7768e" stopOpacity="0.28" />
          <stop offset="65%" stopColor="#ff9e64" stopOpacity="0.10" />
          <stop offset="100%" stopColor="#ff9e64" stopOpacity="0.0" />
        </radialGradient>
      </defs>

      <style>{`
        @keyframes ringFlow {
          from { stroke-dashoffset: 263.9; }
          to { stroke-dashoffset: 23.6; }
        }
        @keyframes auraBreathe {
          0%, 100% { transform: scale(1.0); opacity: 0.8; }
          50% { transform: scale(1.12); opacity: 1.0; }
        }
        .stat-heading { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; }
        .matrix-val { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 18.5px; fill: #c0caf5; }
        .matrix-lbl { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 8.5px; letter-spacing: 0.7px; }
        .matrix-sub { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; }
        .tier-badge-txt { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 900; }
        .tier-sub-txt { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; }
      `}</style>

      {/* Card Background */}
      <rect width={w} height={h} rx="4.5" fill={theme.bg} stroke={theme.border} strokeWidth="1" />

      {/* Header */}
      <text x="22" y="25.0" className="stat-heading" fontSize="12.5" letterSpacing="1.2" fill={theme.title}>
        DEVELOPER STATS
      </text>
      <circle cx="178" cy="21.5" r="2.5" fill="#f7768e" />
      <text x="186" y="24.5" className="matrix-sub" fontSize="9" letterSpacing="0.5" fill="#787c99">
        ALL-TIME
      </text>

      {/* Tile 1: Commits */}
      <g transform="translate(22.0, 38.0)">
        <rect width={tileW} height={tileH} rx="6" fill="#1f2335" fillOpacity="0.5" stroke="#292e42" strokeWidth="0.8" />
        <text x="13" y="21.0" className="matrix-lbl" fill="#7aa2f7">COMMITS</text>
        <circle cx={tileW - 16} cy="17.0" r="10" fill="#7aa2f7" fillOpacity="0.12" />
        <circle cx={tileW - 16} cy="17.0" r="4.2" fill="none" stroke="#70a5fd" strokeWidth="1.6" />
        <circle cx={tileW - 16} cy="17.0" r="1.8" fill="#70a5fd" />
        <text x="13" y="45.5" className="matrix-val">{commits.toLocaleString()}</text>
      </g>

      {/* Tile 2: Merged PRs */}
      <g transform={`translate(${(22.0 + tileW + (isHero ? 16 : 8)).toFixed(1)}, 38.0)`}>
        <rect width={tileW} height={tileH} rx="6" fill="#1f2335" fillOpacity="0.5" stroke="#292e42" strokeWidth="0.8" />
        <text x="13" y="21.0" className="matrix-lbl" fill="#bb9af7">MERGED PRS</text>
        <circle cx={tileW - 16} cy="17.0" r="10" fill="#bb9af7" fillOpacity="0.12" />
        <g transform={`translate(${tileW - 16}, 17.0)`}>
          <path d="M -3 -5 L -3 5 M 3 -5 L 3 -1 C 3 2 -3 2 -3 2" fill="none" stroke="#bb9af7" strokeWidth="1.4" strokeLinecap="round" />
          <circle cx="-3" cy="-5" r="1.6" fill="#bb9af7" />
          <circle cx="3" cy="-5" r="1.6" fill="#bb9af7" />
          <circle cx="-3" cy="5" r="1.6" fill="#bb9af7" />
        </g>
        <text x="13" y="45.5" className="matrix-val">{prs.toLocaleString()}</text>
      </g>

      {/* Tile 3: Total Stars */}
      <g transform="translate(22.0, 102.0)">
        <rect width={tileW} height={tileH} rx="6" fill="#1f2335" fillOpacity="0.5" stroke="#292e42" strokeWidth="0.8" />
        <text x="13" y="21.0" className="matrix-lbl" fill="#e0af68">TOTAL STARS</text>
        <circle cx={tileW - 16} cy="17.0" r="10" fill="#e0af68" fillOpacity="0.12" />
        <g transform={`translate(${tileW - 16}, 17.0)`}>
          <path d="M 0 -5 L 1.3 -1.5 L 5 -1.2 L 2.3 1.2 L 3 5 L 0 3.1 L -3 5 L -2.3 1.2 L -5 -1.2 L -1.3 -1.5 Z" fill="#e0af68" />
        </g>
        <text x="13" y="45.5" className="matrix-val">{stars.toLocaleString()}</text>
      </g>

      {/* Tile 4: Repositories */}
      <g transform={`translate(${(22.0 + tileW + (isHero ? 16 : 8)).toFixed(1)}, 102.0)`}>
        <rect width={tileW} height={tileH} rx="6" fill="#1f2335" fillOpacity="0.5" stroke="#292e42" strokeWidth="0.8" />
        <text x="13" y="21.0" className="matrix-lbl" letterSpacing="0.6" fill="#73daca">REPOSITORIES</text>
        <circle cx={tileW - 16} cy="17.0" r="10" fill="#73daca" fillOpacity="0.12" />
        <g transform={`translate(${tileW - 16}, 17.0)`}>
          <path d="M -4.5 -4.5 C -2.5 -5.5 0 -5.5 0 -3.5 L 0 4.5 C 0 2.5 -2.5 2.5 -4.5 3.5 Z M 4.5 -4.5 C 2.5 -5.5 0 -5.5 0 -3.5 L 0 4.5 C 0 2.5 2.5 2.5 4.5 3.5 Z" fill="none" stroke="#73daca" strokeWidth="1.3" strokeLinejoin="round" />
        </g>
        <text x="13" y="45.5" className="matrix-val">{repos.toLocaleString()}</text>
      </g>

      {/* Glass Divider */}
      <line x1={dividerX} y1="22" x2={dividerX} y2="158.0" stroke="url(#stats-divider-grad)" strokeWidth="1" />

      {/* Radial Rating Gauge */}
      <g transform={`translate(${gaugeCenterX.toFixed(1)}, 75.0)`}>
        <circle cx="0" cy="0" r="54" fill="url(#stats-ring-aura)" style={{ animation: 'auraBreathe 4s ease-in-out infinite', transformOrigin: '0px 0px' }} />
        <circle cx="0" cy="0" r="42.0" fill="none" stroke="#24283b" strokeWidth="6.5" strokeLinecap="round" />
        <circle
          cx="0"
          cy="0"
          r="42.0"
          fill="none"
          stroke="url(#stats-tier-grad)"
          strokeWidth="6.5"
          strokeLinecap="round"
          strokeDasharray="263.9"
          strokeDashoffset="23.6"
          transform="rotate(-90)"
          style={{ animation: 'ringFlow 1.6s cubic-bezier(0.16, 1, 0.3, 1) forwards' }}
        />
        <text x="0" y="5" textAnchor="middle" className="tier-badge-txt" fontSize="28" fill="url(#stats-tier-grad)" filter="url(#stats-ring-glow)">
          {rating}
        </text>
        <text x="0" y="22" textAnchor="middle" className="tier-sub-txt" fontSize="10.5" fill="#a9b1d6">
          910 / 1000
        </text>
      </g>

      {/* Rank Pill Badge */}
      <g transform={`translate(${pillStartX.toFixed(1)}, 138.0)`}>
        <rect width="114.0" height="19.0" rx="9.5" fill="#f7768e" fillOpacity="0.16" stroke="url(#stats-tier-grad)" strokeWidth="1" />
        <text x="57.0" y="12.5" textAnchor="middle" className="stat-heading" fontSize="8.8" letterSpacing="0.8" fill="#ffffff">
          Top 0.5%
        </text>
      </g>

      <text x={gaugeCenterX} y="169" textAnchor="middle" className="matrix-sub" fontSize="9.5" letterSpacing="0.5" fill="#787c99">
        Mythic Architect
      </text>
    </svg>
  )
}
