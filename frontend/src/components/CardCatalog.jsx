import React, { useState } from 'react'
import {
  Check,
  Trash2,
  ArrowUp,
  ArrowDown,
  Sliders,
  ChevronDown,
  ChevronUp,
  Maximize2,
  Minimize2,
} from 'lucide-react'
import { CARD_DEFINITIONS, computeLanguagesHeight } from '../constants/cards'

export default function CardCatalog({
  activeCards,
  onToggleCard,
  onUpdateCardProp,
  onMoveCard,
}) {
  const [expandedCard, setExpandedCard] = useState(null)

  return (
    <div className="glass-panel rounded-xl p-4 flex flex-col gap-3">
      <div className="flex items-center justify-between pb-2 border-b border-[#24283b]">
        <div className="flex items-center gap-2">
          <Sliders className="w-4 h-4 text-[#7aa2f7]" />
          <h2 className="text-xs font-bold uppercase tracking-wider text-white">
            Card Catalog & Controls
          </h2>
        </div>
        <span className="text-[11px] text-[#7982a9] font-mono">
          {activeCards.length} of {CARD_DEFINITIONS.length} active
        </span>
      </div>

      <div className="flex flex-col gap-2 max-h-[calc(100vh-280px)] overflow-y-auto pr-1">
        {CARD_DEFINITIONS.map((def) => {
          const activeIndex = activeCards.findIndex((c) => c.id === def.id)
          const isActive = activeIndex !== -1
          const activeCard = isActive ? activeCards[activeIndex] : null
          const isExpanded = expandedCard === def.id
          const currentWidth = activeCard?.width || def.defaultWidth
          const isHero = currentWidth >= 700

          return (
            <div
              key={def.id}
              className={`rounded-lg border transition-all ${
                isActive
                  ? 'border-[#7aa2f7]/40 bg-[#1f2335]/50 shadow-sm'
                  : 'border-[#24283b] bg-[#161826]/40 hover:border-[#3b4261]'
              }`}
            >
              {/* Card Header Row */}
              <div className="p-3 flex items-center justify-between gap-2">
                <div className="flex items-center gap-2.5 flex-1">
                  <button
                    type="button"
                    onClick={() => onToggleCard(def.id)}
                    className={`w-5 h-5 rounded flex items-center justify-center border transition-all cursor-pointer ${
                      isActive
                        ? 'bg-[#7aa2f7] border-[#7aa2f7] text-[#090a0f]'
                        : 'border-[#3b4261] hover:border-[#7aa2f7]/60'
                    }`}
                  >
                    {isActive && <Check className="w-3.5 h-3.5" strokeWidth={3} />}
                  </button>

                  <div className="cursor-pointer" onClick={() => onToggleCard(def.id)}>
                    <div className="text-xs font-semibold text-white tracking-tight flex items-center gap-1.5">
                      <span>{def.name}</span>
                      {def.isHeroCapable && isHero && (
                        <span className="text-[9px] font-bold px-1.5 py-0.2 rounded bg-[#7aa2f7]/20 text-[#7aa2f7] border border-[#7aa2f7]/40">
                          Hero
                        </span>
                      )}
                    </div>
                    <div className="text-[10px] text-[#7982a9] line-clamp-1">
                      {def.description}
                    </div>
                  </div>
                </div>

                {/* Actions */}
                {isActive && (
                  <div className="flex items-center gap-1">
                    {/* Reorder Buttons */}
                    <button
                      type="button"
                      disabled={activeIndex === 0}
                      onClick={() => onMoveCard(activeIndex, -1)}
                      className="p-1 text-[#7982a9] hover:text-white disabled:opacity-30 disabled:pointer-events-none transition-colors cursor-pointer"
                      title="Move up"
                    >
                      <ArrowUp className="w-3.5 h-3.5" />
                    </button>
                    <button
                      type="button"
                      disabled={activeIndex === activeCards.length - 1}
                      onClick={() => onMoveCard(activeIndex, 1)}
                      className="p-1 text-[#7982a9] hover:text-white disabled:opacity-30 disabled:pointer-events-none transition-colors cursor-pointer"
                      title="Move down"
                    >
                      <ArrowDown className="w-3.5 h-3.5" />
                    </button>

                    {/* Expand Controls */}
                    <button
                      type="button"
                      onClick={() => setExpandedCard(isExpanded ? null : def.id)}
                      className="p-1 text-[#7982a9] hover:text-[#7aa2f7] transition-colors cursor-pointer ml-1"
                      title="Configure dimensions & options"
                    >
                      {isExpanded ? (
                        <ChevronUp className="w-4 h-4" />
                      ) : (
                        <ChevronDown className="w-4 h-4" />
                      )}
                    </button>
                  </div>
                )}
              </div>

              {/* Expandable Dimension & Option Sliders */}
              {isActive && isExpanded && (
                <div className="px-3 pb-3 pt-1 border-t border-[#24283b] flex flex-col gap-2.5 bg-[#0e1017]/60 rounded-b-lg text-xs">
                  {/* Hero-Capable Card Sizing */}
                  {def.isHeroCapable ? (
                    <div>
                      <div className="flex items-center justify-between text-[11px] text-[#7982a9] mb-1.5">
                        <span>Card Layout Size</span>
                        <div className="flex items-center gap-1">
                          <button
                            type="button"
                            onClick={() => onUpdateCardProp(def.id, 'width', 424)}
                            className={`flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-semibold border transition-all cursor-pointer ${
                              !isHero
                                ? 'bg-[#7aa2f7] text-[#090a0f] border-[#7aa2f7]'
                                : 'bg-[#1f2335] text-[#7982a9] border-[#292e42] hover:text-white'
                            }`}
                          >
                            <Minimize2 className="w-2.5 h-2.5" />
                            <span>Standard (424px)</span>
                          </button>
                          <button
                            type="button"
                            onClick={() => onUpdateCardProp(def.id, 'width', 840)}
                            className={`flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-semibold border transition-all cursor-pointer ${
                              isHero
                                ? 'bg-[#7aa2f7] text-[#090a0f] border-[#7aa2f7]'
                                : 'bg-[#1f2335] text-[#7982a9] border-[#292e42] hover:text-white'
                            }`}
                          >
                            <Maximize2 className="w-2.5 h-2.5" />
                            <span>Hero (840px)</span>
                          </button>
                        </div>
                      </div>

                      {/* Width slider fine-tuning */}
                      <input
                        type="range"
                        min="424"
                        max="840"
                        step="8"
                        value={currentWidth}
                        onChange={(e) =>
                          onUpdateCardProp(def.id, 'width', parseInt(e.target.value))
                        }
                        className="w-full h-1.5 bg-[#24283b] rounded-lg appearance-none cursor-pointer accent-[#7aa2f7]"
                      />
                      <div className="flex justify-between text-[9px] text-[#565f89] mt-0.5 font-mono">
                        <span>424px (Standard)</span>
                        <span>840px (Hero Wide)</span>
                      </div>
                    </div>
                  ) : (
                    /* Fixed width indicator for radar / velocity / languages */
                    <div className="flex items-center justify-between text-[11px] text-[#7982a9]">
                      <span>Card Width</span>
                      <span className="font-mono text-[#c0caf5]">
                        {def.defaultWidth}px (Fixed Standard)
                      </span>
                    </div>
                  )}

                  {/* Languages-specific: Language count & dynamic height */}
                  {def.id === 'languages' && (
                    <div className="pt-1 border-t border-[#24283b]">
                      <div className="flex items-center justify-between text-[11px] text-[#7982a9] mb-1">
                        <span>Languages Count</span>
                        <span className="font-mono text-[#7aa2f7] font-bold">
                          {activeCard.langsCount || 12} rows ({computeLanguagesHeight(activeCard.langsCount || 12)}px tall)
                        </span>
                      </div>
                      <input
                        type="range"
                        min="6"
                        max="16"
                        step="1"
                        value={activeCard.langsCount || 12}
                        onChange={(e) => {
                          const count = parseInt(e.target.value)
                          onUpdateCardProp(def.id, 'langsCount', count)
                          onUpdateCardProp(def.id, 'height', computeLanguagesHeight(count))
                        }}
                        className="w-full h-1.5 bg-[#24283b] rounded-lg appearance-none cursor-pointer accent-[#7aa2f7]"
                      />
                      <div className="flex justify-between text-[9px] text-[#565f89] mt-0.5 font-mono">
                        <span>6 rows (192px)</span>
                        <span>16 rows (362px)</span>
                      </div>
                    </div>
                  )}

                  {/* Streak-specific: Sparkline toggle */}
                  {def.id === 'streak' && (
                    <div className="flex items-center justify-between pt-1 border-t border-[#24283b]">
                      <span className="text-[11px] text-[#7982a9]">14-Day Momentum Sparkline</span>
                      <button
                        type="button"
                        onClick={() =>
                          onUpdateCardProp(def.id, 'sparkline', activeCard.sparkline === false)
                        }
                        className={`px-2 py-0.5 rounded text-[10px] font-bold border transition-colors cursor-pointer ${
                          activeCard.sparkline !== false
                            ? 'bg-[#7aa2f7]/20 border-[#7aa2f7]/50 text-[#7aa2f7]'
                            : 'bg-[#24283b] border-transparent text-[#7982a9]'
                        }`}
                      >
                        {activeCard.sparkline !== false ? 'Enabled' : 'Disabled'}
                      </button>
                    </div>
                  )}
                </div>
              )}
            </div>
          )
        })}
      </div>
    </div>
  )
}
