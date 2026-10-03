import React from 'react'
import { Activity, Sparkles, RefreshCw, GitFork, ShieldCheck } from 'lucide-react'
import { THEMES } from '../constants/themes'

export default function Navbar({
  username,
  setUsername,
  themeId,
  setThemeId,
  isLiveLoading,
  onRefreshData,
  onOpenDeploy,
}) {
  return (
    <header className="sticky top-0 z-40 border-b border-[#24283b] bg-[#090a0f]/85 backdrop-blur-xl px-4 lg:px-8 py-3.5">
      <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
        {/* Brand & Tagline */}
        <div className="flex items-center gap-3 w-full md:w-auto justify-between md:justify-start">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-[#70a5fd] to-[#bb9af7] flex items-center justify-center shadow-lg shadow-[#70a5fd]/20">
              <Activity className="w-4 h-4 text-[#090a0f]" strokeWidth={2.5} />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-extrabold text-base tracking-tight text-white font-mono">
                  GitStats
                </span>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#70a5fd]/15 text-[#70a5fd] border border-[#70a5fd]/30">
                  STUDIO
                </span>
              </div>
              <p className="text-[11px] text-[#7982a9] hidden sm:block">
                Interactive Profile Card Designer
              </p>
            </div>
          </div>

          {/* Mobile Deploy Trigger */}
          <button
            onClick={onOpenDeploy}
            className="md:hidden flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#7aa2f7] hover:bg-[#70a5fd] text-[#090a0f] text-xs font-bold transition-all shadow-md active:scale-95 cursor-pointer"
          >
            <GitFork className="w-3.5 h-3.5" />
            <span>Deploy</span>
          </button>
        </div>

        {/* Center: Live User Engine & Theme */}
        <div className="flex items-center gap-3 w-full md:w-auto">
          {/* Username Input with Refresh */}
          <div className="relative flex-1 md:w-60">
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="Enter GitHub username..."
              className="w-full glass-input text-xs text-white rounded-lg pl-3 pr-8 py-2 placeholder-[#565f89] focus:outline-none"
            />
            <button
              onClick={onRefreshData}
              title="Refresh live user data"
              disabled={isLiveLoading}
              className="absolute right-2 top-1/2 -translate-y-1/2 text-[#7982a9] hover:text-[#7aa2f7] transition-colors cursor-pointer"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isLiveLoading ? 'animate-spin text-[#7aa2f7]' : ''}`} />
            </button>
          </div>

          {/* Theme Selector */}
          <div className="relative">
            <select
              value={themeId}
              onChange={(e) => setThemeId(e.target.value)}
              className="glass-input text-xs text-[#c0caf5] rounded-lg px-3 py-2 pr-7 appearance-none cursor-pointer hover:border-[#7aa2f7]/50"
            >
              {THEMES.map((t) => (
                <option key={t.id} value={t.id} className="bg-[#1a1b27] text-white">
                  {t.name}
                </option>
              ))}
            </select>
            <div className="absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none w-2 h-2 rounded-full border border-white/20"
                 style={{ backgroundColor: THEMES.find(t => t.id === themeId)?.accent || '#7aa2f7' }}
            />
          </div>

          {/* Desktop Deploy Action */}
          <button
            onClick={onOpenDeploy}
            className="hidden md:flex items-center gap-2 px-4 py-2 rounded-lg bg-gradient-to-r from-[#70a5fd] to-[#7aa2f7] hover:brightness-110 text-[#090a0f] text-xs font-bold transition-all shadow-md shadow-[#70a5fd]/20 hover:shadow-lg active:scale-95 cursor-pointer"
          >
            <GitFork className="w-3.5 h-3.5 text-[#090a0f]" strokeWidth={2.2} />
            <span>Deploy to Fork</span>
          </button>
        </div>
      </div>
    </header>
  )
}
