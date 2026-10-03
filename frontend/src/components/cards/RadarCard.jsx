import React from 'react'
import { getTheme } from '../../constants/themes'

export default function RadarCard({
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
        <linearGradient id="radar-divider-grad" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor="#1a1b27" stopOpacity="0.0" />
          <stop offset="50%" stopColor="#3b4261" stopOpacity="0.7" />
          <stop offset="100%" stopColor="#1a1b27" stopOpacity="0.0" />
        </linearGradient>
        <linearGradient id="radar-poly-grad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#70a5fd" stopOpacity="0.55" />
          <stop offset="100%" stopColor="#7aa2f7" stopOpacity="0.2" />
        </linearGradient>
        <filter id="radar-glow" x="-20%" y="-20%" width="140%" height="140%">
          <feGaussianBlur stdDeviation="2.2" result="blur" />
          <feMerge>
            <feMergeNode in="blur" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
      </defs>

      <style>{`
        .radar-title { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 11px; letter-spacing: 0.5px; fill: ${theme.title}; }
        .radar-sub { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 7.5px; letter-spacing: 0.35px; fill: #787c99; }
        .radar-axis-lbl { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 8px; }
        .radar-archetype-txt { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 800; font-size: 10px; letter-spacing: 0.5px; fill: #c0caf5; }
        .radar-domain-lbl { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 600; font-size: 8px; fill: #7982a9; }
        .radar-domain-val { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 700; font-size: 8px; fill: #c0caf5; }
        .radar-footnote { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-weight: 500; font-size: 8px; fill: #565f89; }
      `}</style>

      {/* Card Background */}
      <rect width={w} height={h} rx="4.5" fill={theme.bg} stroke={theme.border} strokeWidth="1" />

      {/* Header */}
      <text x="14" y="24.0" className="radar-title">DEVELOPER DNA</text>
      <circle cx="125" cy="20.5" r="1.8" fill="#70a5fd" />
      <text x="135" y="23.5" className="radar-sub">5-AXIS POLYGLOT RADAR</text>

      {/* Concentric Web Polygons */}
      <polygon points="120.0,91.0 132.4,100.0 127.6,114.5 112.4,114.5 107.6,100.0" fill="none" stroke="#24283b" strokeWidth="0.8" />
      <polygon points="120.0,78.0 144.7,96.0 135.3,125.0 104.7,125.0 95.3,96.0" fill="rgba(31, 35, 53, 0.15)" stroke="#24283b" strokeWidth="0.8" />
      <polygon points="120.0,65.0 157.1,91.9 142.9,135.6 97.1,135.6 82.9,91.9" fill="none" stroke="#24283b" strokeWidth="0.8" />
      <polygon points="120.0,52.0 169.5,87.9 150.6,146.1 89.4,146.1 70.5,87.9" fill="rgba(31, 35, 53, 0.25)" stroke="#2e3c64" strokeWidth="0.8" />

      {/* Radial Spokes */}
      <line x1="120.0" y1="104.0" x2="120.0" y2="52.0" stroke="#2e3c64" strokeWidth="0.8" strokeDasharray="2,2" />
      <line x1="120.0" y1="104.0" x2="169.5" y2="87.9" stroke="#2e3c64" strokeWidth="0.8" strokeDasharray="2,2" />
      <line x1="120.0" y1="104.0" x2="150.6" y2="146.1" stroke="#2e3c64" strokeWidth="0.8" strokeDasharray="2,2" />
      <line x1="120.0" y1="104.0" x2="89.4" y2="146.1" stroke="#2e3c64" strokeWidth="0.8" strokeDasharray="2,2" />
      <line x1="120.0" y1="104.0" x2="70.5" y2="87.9" stroke="#2e3c64" strokeWidth="0.8" strokeDasharray="2,2" />

      {/* Data Polygon with Glow */}
      <polygon
        points="120.0,84.9 141.6,97.0 128.5,115.7 113.1,113.5 111.5,101.2"
        fill="url(#radar-poly-grad)"
        stroke="#70a5fd"
        strokeWidth="1.8"
        filter="url(#radar-glow)"
      />
      <circle cx="120.0" cy="84.9" r="2.8" fill="#70a5fd" stroke="#1a1b27" strokeWidth="1" />
      <circle cx="141.6" cy="97.0" r="2.8" fill="#70a5fd" stroke="#1a1b27" strokeWidth="1" />
      <circle cx="128.5" cy="115.7" r="2.8" fill="#70a5fd" stroke="#1a1b27" strokeWidth="1" />
      <circle cx="113.1" cy="113.5" r="2.8" fill="#70a5fd" stroke="#1a1b27" strokeWidth="1" />
      <circle cx="111.5" cy="101.2" r="2.8" fill="#70a5fd" stroke="#1a1b27" strokeWidth="1" />

      {/* Spoke Labels */}
      <text x="120.0" y="43.0" className="radar-axis-lbl" textAnchor="middle" fill="#ec915c">Systems</text>
      <text x="175.5" y="89.9" className="radar-axis-lbl" textAnchor="start" fill="#70a5fd">Backend</text>
      <text x="154.6" y="158.1" className="radar-axis-lbl" textAnchor="start" fill="#7aa2f7">Frontend</text>
      <text x="85.4" y="158.1" className="radar-axis-lbl" textAnchor="end" fill="#bb9af7">DevOps</text>
      <text x="64.5" y="89.9" className="radar-axis-lbl" textAnchor="end" fill="#73daca">Data &amp; AI</text>

      {/* Glass Divider */}
      <line x1="246.0" y1="22" x2="246.0" y2="158.0" stroke="url(#radar-divider-grad)" strokeWidth="1" />

      {/* Right Column: DNA Breakdown */}
      <g transform="translate(254, 0)">
        {/* Archetype Badge Pill */}
        <g transform="translate(75, 34)">
          <rect x="-70" y="-12" width="140" height="24" rx="12" fill="#1f2335" stroke="#70a5fd" strokeOpacity="0.45" strokeWidth="1" />
          <text x="0" y="4" textAnchor="middle" className="radar-archetype-txt">🧬 Polyglot Architect</text>
        </g>

        {/* Systems */}
        <text x="4" y="56.0" className="radar-domain-lbl">Systems</text>
        <text x="146" y="56.0" className="radar-domain-val" textAnchor="end">28%</text>
        <rect x="4" y="60.0" width="142.0" height="3.5" rx="1.75" fill="#24283b" />
        <rect x="4" y="60.0" width="39.8" height="3.5" rx="1.75" fill="#ec915c" />

        {/* Backend */}
        <text x="4" y="74.0" className="radar-domain-lbl">Backend</text>
        <text x="146" y="74.0" className="radar-domain-val" textAnchor="end">36%</text>
        <rect x="4" y="78.0" width="142.0" height="3.5" rx="1.75" fill="#24283b" />
        <rect x="4" y="78.0" width="51.1" height="3.5" rx="1.75" fill="#70a5fd" />

        {/* Frontend */}
        <text x="4" y="92.0" className="radar-domain-lbl">Frontend</text>
        <text x="146" y="92.0" className="radar-domain-val" textAnchor="end">18%</text>
        <rect x="4" y="96.0" width="142.0" height="3.5" rx="1.75" fill="#24283b" />
        <rect x="4" y="96.0" width="25.6" height="3.5" rx="1.75" fill="#7aa2f7" />

        {/* DevOps */}
        <text x="4" y="110.0" className="radar-domain-lbl">DevOps</text>
        <text x="146" y="110.0" className="radar-domain-val" textAnchor="end">12%</text>
        <rect x="4" y="114.0" width="142.0" height="3.5" rx="1.75" fill="#24283b" />
        <rect x="4" y="114.0" width="17.0" height="3.5" rx="1.75" fill="#bb9af7" />

        {/* Data & AI */}
        <text x="4" y="128.0" className="radar-domain-lbl">Data &amp; AI</text>
        <text x="146" y="128.0" className="radar-domain-val" textAnchor="end">6%</text>
        <rect x="4" y="132.0" width="142.0" height="3.5" rx="1.75" fill="#24283b" />
        <rect x="4" y="132.0" width="8.5" height="3.5" rx="1.75" fill="#73daca" />

        {/* Analyzed Languages Footnote */}
        <text x="75" y="156" textAnchor="middle" className="radar-footnote">14 Languages Mapped</text>
      </g>
    </svg>
  )
}
