import React from 'react'
import { getTheme } from '../../constants/themes'

export default function MilestonesCard({
  width = 840,
  height = 180,
  themeId = 'tokyonight',
}) {
  const theme = getTheme(themeId)
  const w = Number(width) || 424
  const h = Number(height) || 180

  const items = [
    { title: 'STREAK RUNNER', next: 'Next: 365d', icon: '🔥', val: '184 Days', tier: 'PLATINUM', color: '#70a5fd' },
    { title: 'POLYGLOT', next: 'Next: 18', icon: '🌐', val: '14 Stacks', tier: 'PLATINUM', color: '#70a5fd' },
    { title: 'CODE TITAN', next: 'Next: 5k', icon: '⚡', val: '2.5k Contribs', tier: 'PLATINUM', color: '#70a5fd' },
    { title: 'PR SPECIALIST', next: 'Next: 40', icon: '🔀', val: '28 Merged', tier: 'PLATINUM', color: '#70a5fd' },
    { title: 'REPO MASTER', next: 'Next: 30', icon: '📦', val: '22 Repos', tier: 'PLATINUM', color: '#70a5fd' },
    { title: 'STAR MAGNET', next: 'Next: 100', icon: '⭐', val: '65 Stars', tier: 'PLATINUM', color: '#70a5fd' },
  ]

  const availableW = w - 36.0
  const gapX = 9.5
  const tileW = (availableW - 2.0 * gapX) / 3.0
  const tileH = 58.0
  const row0Y = 38.0
  const row1Y = 105.0

  const badgeW = 142.0
  const badgeH = 18.0
  const badgeX = w - 18.0 - badgeW
  const badgeY = 12.0

  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox={`0 0 ${w} ${h}`}
      width={w}
      height={h}
      className="rounded-[4.5px] transition-all duration-300 select-none shadow-lg"
    >
      <defs>
        <linearGradient id="mil-glass-grad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#24283b" stopOpacity="0.6" />
          <stop offset="100%" stopColor="#1f2335" stopOpacity="0.3" />
        </linearGradient>
      </defs>

      <style>{`
        .mil-title { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 11px; letter-spacing: 0.6px; fill: ${theme.title}; }
        .mil-sub { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 7.5px; letter-spacing: 0.35px; fill: #787c99; }
        .mil-badge-txt { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 9px; letter-spacing: 0.4px; fill: #bb9af7; }
        .mil-lbl { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 7.2px; letter-spacing: 0.35px; fill: #7aa2f7; }
        .mil-val { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 11.5px; fill: #c0caf5; }
        .mil-tier-txt { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 6.5px; letter-spacing: 0.5px; }
        .mil-target-txt { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 6.8px; fill: #787c99; }
        @keyframes milFadeIn {
          from { opacity: 0; transform: translateY(4px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .mil-anim { animation: milFadeIn 0.5s ease-out forwards; }
      `}</style>

      {/* Card Background */}
      <rect width={w} height={h} rx="4.5" fill={theme.bg} stroke={theme.border} strokeWidth="1" />

      {/* Header */}
      <text x="18" y="24.0" className="mil-title">CAREER MILESTONES</text>
      <circle cx="145" cy="20.5" r="1.8" fill="#bb9af7" />
      <text x="153" y="23.5" className="mil-sub">ACHIEVEMENTS &amp; TROPHIES</text>

      {/* Master Achievement Badge */}
      <rect
        x={badgeX}
        y={badgeY}
        width={badgeW}
        height={badgeH}
        rx="3.5"
        fill="#bb9af7"
        fillOpacity="0.12"
        stroke="#bb9af7"
        strokeOpacity="0.45"
        strokeWidth="0.8"
      />
      <text x={badgeX + badgeW / 2} y={badgeY + 12.0} textAnchor="middle" className="mil-badge-txt">
        👑 Mythic Grandmaster
      </text>

      {/* 3x2 Grid of All 6 Milestone Tiles */}
      {items.map((item, idx) => {
        const col = idx % 3
        const row = Math.floor(idx / 3)
        const tX = 18.0 + col * (tileW + gapX)
        const tY = row === 0 ? row0Y : row1Y
        const animDelay = idx * 45

        return (
          <g key={idx} className="mil-anim" style={{ animationDelay: `${animDelay}ms` }}>
            <rect
              x={tX}
              y={tY}
              width={tileW}
              height={tileH}
              rx="4.5"
              fill="#1f2335"
              fillOpacity="0.45"
              stroke={item.color}
              strokeOpacity="0.30"
              strokeWidth="0.8"
            />
            {/* Top Heading Row */}
            <text x={tX + 9.5} y={tY + 13.5} className="mil-lbl">{item.title}</text>
            <text x={tX + tileW - 9.5} y={tY + 13.5} textAnchor="end" className="mil-target-txt">{item.next}</text>

            {/* Bottom Section: Icon + Value + Tier Pill */}
            <circle
              cx={tX + 19.5}
              cy={tY + 36.5}
              r="11.5"
              fill={item.color}
              fillOpacity="0.12"
              stroke={item.color}
              strokeOpacity="0.40"
              strokeWidth="0.8"
            />
            <text x={tX + 19.5} y={tY + 40.5} textAnchor="middle" fontSize="11.5px">{item.icon}</text>
            <text x={tX + 37.0} y={tY + 33.0} className="mil-val">{item.val}</text>

            {/* Tier Pill */}
            <rect
              x={tX + 37.0}
              y={tY + 39.0}
              width="44.0"
              height="11.5"
              rx="2.5"
              fill={item.color}
              fillOpacity="0.14"
              stroke={item.color}
              strokeOpacity="0.45"
              strokeWidth="0.6"
            />
            <text x={tX + 59.0} y={tY + 47.2} textAnchor="middle" className="mil-tier-txt" fill={item.color}>
              {item.tier}
            </text>
          </g>
        )
      })}
    </svg>
  )
}
