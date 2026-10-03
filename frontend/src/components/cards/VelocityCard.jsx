import React from 'react'
import { getTheme } from '../../constants/themes'

export default function VelocityCard({
  width = 424,
  height = 180,
  themeId = 'tokyonight',
}) {
  const theme = getTheme(themeId)
  const w = 424
  const h = 180

  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox={`0 0 ${w} ${h}`}
      width={w}
      height={h}
      className="rounded-[4.5px] transition-all duration-300 select-none shadow-lg"
    >
      <defs>
        <linearGradient id="vel-divider-grad" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor="#3b4261" stopOpacity="0.0" />
          <stop offset="25%" stopColor="#3b4261" stopOpacity="0.7" />
          <stop offset="75%" stopColor="#3b4261" stopOpacity="0.7" />
          <stop offset="100%" stopColor="#3b4261" stopOpacity="0.0" />
        </linearGradient>
        <linearGradient id="vel-gauge-grad" x1="0%" y1="100%" x2="100%" y2="0%">
          <stop offset="0%" stopColor="#70a5fd" />
          <stop offset="100%" stopColor="#bb9af7" />
        </linearGradient>
        <filter id="vel-glow" x="-20%" y="-20%" width="140%" height="140%">
          <feGaussianBlur stdDeviation="2.5" result="blur" />
          <feMerge>
            <feMergeNode in="blur" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
        <clipPath id="vel-dist-clip">
          <rect x="22" y="140" width="134" height="5.5" rx="2.75" />
        </clipPath>
      </defs>

      <style>{`
        .vel-title { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 11px; letter-spacing: 0.6px; fill: ${theme.title}; }
        .vel-sub { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 7.5px; letter-spacing: 0.35px; fill: #787c99; }
        .vel-badge-txt { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 9px; letter-spacing: 0.4px; fill: #bb9af7; }
        .vel-gauge-val { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 17px; fill: #c0caf5; }
        .vel-gauge-sub { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 7.5px; letter-spacing: 0.7px; fill: #7982a9; }
        .vel-kpi-lbl { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 7.5px; letter-spacing: 0.5px; fill: #7aa2f7; }
        .vel-kpi-val { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 13.5px; fill: #c0caf5; }
        .vel-kpi-sub { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 7.5px; fill: #7982a9; }
        .vel-rate-txt { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 10px; fill: #73daca; }
        .vel-legend-txt { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 7px; fill: #565f89; }
        @keyframes velFadeIn {
          from { opacity: 0; transform: translateY(4px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .vel-anim { animation: velFadeIn 0.5s ease-out forwards; }
      `}</style>

      {/* Card Background */}
      <rect width={w} height={h} rx="4.5" fill={theme.bg} stroke={theme.border} strokeWidth="1" />

      {/* Header */}
      <text x="18" y="24.0" className="vel-title">PULL REQUEST VELOCITY</text>
      <circle cx="169" cy="20.5" r="1.8" fill="#bb9af7" />
      <text x="177" y="23.5" className="vel-sub">CADENCE &amp; IMPACT</text>
      <rect x="284.0" y="12.0" width="122.0" height="18.0" rx="3.5" fill="#bb9af7" fillOpacity="0.12" stroke="#bb9af7" strokeOpacity="0.45" strokeWidth="0.8" />
      <text x="345.0" y="24.0" textAnchor="middle" className="vel-badge-txt">⚡ Hypersonic Shipper</text>

      {/* Left Section: Turnaround Speedometer Gauge */}
      <circle
        cx="89.0"
        cy="86.0"
        r="37.0"
        fill="none"
        stroke="#212337"
        strokeWidth="5.5"
        strokeLinecap="round"
        strokeDasharray="142.07 232.48"
        transform="rotate(160 89.0 86.0)"
      />
      <circle
        cx="89.0"
        cy="86.0"
        r="37.0"
        fill="none"
        stroke="url(#vel-gauge-grad)"
        strokeWidth="5.5"
        strokeLinecap="round"
        strokeDasharray="130.70 232.48"
        transform="rotate(160 89.0 86.0)"
        filter="url(#vel-glow)"
      />
      <text x="89.0" y="85.0" textAnchor="middle" className="vel-gauge-val">18.5h</text>
      <text x="89.0" y="97.5" textAnchor="middle" className="vel-gauge-sub">AVG MERGE</text>

      {/* Merge Rate & Distribution Bar */}
      <text x="22.0" y="136.0" className="vel-kpi-lbl">MERGE RATE</text>
      <text x="156.0" y="136.0" textAnchor="end" className="vel-rate-txt">87.5%</text>
      <rect x="22.0" y="140.0" width="134.0" height="5.5" rx="2.75" fill="#212337" />
      <g clipPath="url(#vel-dist-clip)">
        <rect x="22.00" y="140.0" width="117.25" height="5.5" fill="#73daca" />
        <rect x="139.25" y="140.0" width="8.38" height="5.5" fill="#70a5fd" />
        <rect x="147.63" y="140.0" width="8.38" height="5.5" fill="#565f89" />
      </g>
      <text x="89.0" y="159.0" textAnchor="middle" className="vel-legend-txt">28 merged · 2 open · 2 closed</text>

      {/* Center Divider */}
      <line x1="172.0" y1="36" x2="172.0" y2="164" stroke="url(#vel-divider-grad)" strokeWidth="1" />

      {/* Right Column: 4 Metric Tiles */}
      {/* Tile 1: Merged PRs */}
      <g className="vel-anim">
        <rect x="182.0" y="38.0" width="107.0" height="58.0" rx="4" fill="#1f2335" fillOpacity="0.45" stroke="#292e42" strokeWidth="0.8" />
        <text x="191.0" y="52.0" className="vel-kpi-lbl">🔀 MERGED PRS</text>
        <text x="191.0" y="71.0" className="vel-kpi-val">28</text>
        <text x="191.0" y="85.0" className="vel-kpi-sub">of 32 authored (88%)</text>
      </g>

      {/* Tile 2: Code Shipped */}
      <g className="vel-anim" style={{ animationDelay: '60ms' }}>
        <rect x="299.0" y="38.0" width="107.0" height="58.0" rx="4" fill="#1f2335" fillOpacity="0.45" stroke="#292e42" strokeWidth="0.8" />
        <text x="308.0" y="52.0" className="vel-kpi-lbl">📦 CODE SHIPPED</text>
        <text x="308.0" y="71.0" className="vel-kpi-val">
          <tspan fill="#73daca">+42.8k</tspan> <tspan fontSize="10px" fill="#787c99">/</tspan> <tspan fontSize="11.5px" fill="#f7768e">-14.3k</tspan>
        </text>
        <text x="308.0" y="85.0" className="vel-kpi-sub">186 files modified</text>
      </g>

      {/* Tile 3: Peer Reviews */}
      <g className="vel-anim" style={{ animationDelay: '120ms' }}>
        <rect x="182.0" y="104.0" width="107.0" height="58.0" rx="4" fill="#1f2335" fillOpacity="0.45" stroke="#292e42" strokeWidth="0.8" />
        <text x="191.0" y="118.0" className="vel-kpi-lbl">👁️ PEER REVIEWS</text>
        <text x="191.0" y="137.0" className="vel-kpi-val">24</text>
        <text x="191.0" y="151.0" className="vel-kpi-sub">PR Reviews Completed</text>
      </g>

      {/* Tile 4: Velocity Index */}
      <g className="vel-anim" style={{ animationDelay: '180ms' }}>
        <rect x="299.0" y="104.0" width="107.0" height="58.0" rx="4" fill="#1f2335" fillOpacity="0.45" stroke="#292e42" strokeWidth="0.8" />
        <text x="308.0" y="118.0" className="vel-kpi-lbl">⚡ VELOCITY INDEX</text>
        <text x="308.0" y="137.0" className="vel-kpi-val" fill="#bb9af7">
          92 <tspan fontSize="10px" fill="#787c99">/ 100</tspan>
        </text>
        <text x="308.0" y="151.0" className="vel-kpi-sub">Top 2% Velocity</text>
      </g>
    </svg>
  )
}
