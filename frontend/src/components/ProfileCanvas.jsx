import React, { useState } from 'react'
import {
  LayoutGrid,
  Eye,
  Columns,
  Rows,
  GripVertical,
  Maximize2,
  Minimize2,
  Trash2,
  ArrowUp,
  ArrowDown,
} from 'lucide-react'
import CardRenderer from './cards/CardRenderer'
import { getCardDef } from '../constants/cards'

export default function ProfileCanvas({
  activeCards,
  layoutMode,
  setLayoutMode,
  themeId,
  userData,
  onReorderCards,
  onUpdateCardProp,
  onToggleCard,
}) {
  const [draggedIdx, setDraggedIdx] = useState(null)
  const [dragOverIdx, setDragOverIdx] = useState(null)

  const langCard = activeCards.find((c) => c.id === 'languages')
  const leftCards = activeCards.filter((c) => c.id !== 'languages')

  // Drag and Drop Event Handlers
  const handleDragStart = (e, index) => {
    setDraggedIdx(index)
    e.dataTransfer.effectAllowed = 'move'
    e.dataTransfer.setData('text/plain', index.toString())
  }

  const handleDragOver = (e, index) => {
    e.preventDefault()
    e.dataTransfer.dropEffect = 'move'
    if (dragOverIdx !== index) {
      setDragOverIdx(index)
    }
  }

  const handleDragLeave = (e) => {
    e.preventDefault()
  }

  const handleDrop = (e, targetIdx) => {
    e.preventDefault()
    if (draggedIdx === null || draggedIdx === targetIdx) {
      setDraggedIdx(null)
      setDragOverIdx(null)
      return
    }

    const updated = [...activeCards]
    const [moved] = updated.splice(draggedIdx, 1)
    updated.splice(targetIdx, 0, moved)

    if (onReorderCards) {
      onReorderCards(updated)
    }
    setDraggedIdx(null)
    setDragOverIdx(null)
  }

  const handleDragEnd = () => {
    setDraggedIdx(null)
    setDragOverIdx(null)
  }

  // Toggle between Hero (840px) and Standard (424px) for hero-capable cards
  const handleToggleHero = (cardId, currentWidth) => {
    const isCurrentlyHero = Number(currentWidth) >= 700
    const newWidth = isCurrentlyHero ? 424 : 840
    if (onUpdateCardProp) {
      onUpdateCardProp(cardId, 'width', newWidth)
    }
  }

  const renderCardWrapper = (card, globalIndex) => {
    const def = getCardDef(card.id)
    const isHero = (card.width || def?.defaultWidth || 424) >= 700
    const isDragging = draggedIdx === globalIndex
    const isDragTarget = dragOverIdx === globalIndex && draggedIdx !== globalIndex

    return (
      <div
        key={card.id}
        draggable
        onDragStart={(e) => handleDragStart(e, globalIndex)}
        onDragOver={(e) => handleDragOver(e, globalIndex)}
        onDragLeave={handleDragLeave}
        onDrop={(e) => handleDrop(e, globalIndex)}
        onDragEnd={handleDragEnd}
        className={`group relative flex flex-col rounded-lg transition-all duration-200 ${
          isDragging
            ? 'opacity-40 scale-[0.98] border border-dashed border-[#7aa2f7]'
            : isDragTarget
            ? 'ring-2 ring-[#7aa2f7] shadow-[0_0_20px_rgba(122,162,247,0.35)] scale-[1.01]'
            : 'hover:shadow-md'
        }`}
        style={{
          width: isHero ? '100%' : 'auto',
          maxWidth: isHero ? '840px' : `${card.width || 424}px`,
        }}
      >
        {/* Floating Card Controls Toolbar */}
        <div className="flex items-center justify-between px-2.5 py-1.5 bg-[#161826]/90 backdrop-blur-md rounded-t-lg border-t border-x border-[#24283b] text-xs transition-opacity opacity-75 group-hover:opacity-100">
          {/* Drag Handle & Card Label */}
          <div className="flex items-center gap-1.5 cursor-grab active:cursor-grabbing text-[#7982a9] group-hover:text-white select-none">
            <GripVertical className="w-3.5 h-3.5 text-[#7aa2f7]" />
            <span className="text-[11px] font-bold tracking-tight text-white uppercase">
              {def?.name || card.id}
            </span>
            <span className="text-[10px] font-mono px-1.5 py-0.2 rounded bg-[#1f2335] text-[#7982a9] border border-[#292e42]">
              {card.width || def?.defaultWidth || 424}px
            </span>
          </div>

          {/* Quick Toolbar Actions */}
          <div className="flex items-center gap-1">
            {/* Hero Width Toggle (for hero-capable cards) */}
            {def?.isHeroCapable && (
              <button
                type="button"
                onClick={() => handleToggleHero(card.id, card.width || def.defaultWidth)}
                className={`flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-semibold border transition-all cursor-pointer ${
                  isHero
                    ? 'bg-[#7aa2f7]/20 border-[#7aa2f7]/50 text-[#7aa2f7] hover:bg-[#7aa2f7]/30'
                    : 'bg-[#1f2335] border-[#292e42] text-[#7982a9] hover:text-white'
                }`}
                title={isHero ? 'Switch to Standard (424px)' : 'Expand to Full Hero (840px)'}
              >
                {isHero ? (
                  <>
                    <Minimize2 className="w-3 h-3" />
                    <span>Standard</span>
                  </>
                ) : (
                  <>
                    <Maximize2 className="w-3 h-3" />
                    <span>Full Hero</span>
                  </>
                )}
              </button>
            )}

            {/* Remove Card */}
            {onToggleCard && (
              <button
                type="button"
                onClick={() => onToggleCard(card.id)}
                className="p-1 text-[#7982a9] hover:text-[#f7768e] transition-colors cursor-pointer"
                title="Remove Card from Canvas"
              >
                <Trash2 className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        </div>

        {/* Card SVG Render Container */}
        <div className="overflow-hidden rounded-b-lg border-b border-x border-[#24283b] bg-[#1a1b27]">
          <CardRenderer card={card} themeId={themeId} userData={userData} />
        </div>
      </div>
    )
  }

  return (
    <div className="flex-1 flex flex-col gap-3">
      {/* Canvas Top Bar */}
      <div className="flex items-center justify-between px-1">
        <div className="flex items-center gap-2">
          <Eye className="w-4 h-4 text-[#7aa2f7]" />
          <span className="text-xs font-bold text-white uppercase tracking-wider">
            Live GitHub Profile Canvas
          </span>
          <span className="text-[11px] text-[#7982a9] hidden sm:inline">
            (Drag cards to reorder • Max 864px container)
          </span>
        </div>

        {/* Layout Mode Switcher */}
        <div className="flex items-center gap-1 bg-[#161826] p-0.5 rounded-lg border border-[#24283b]">
          <button
            type="button"
            onClick={() => setLayoutMode('flow')}
            className={`flex items-center gap-1.5 px-2.5 py-1 rounded text-xs font-semibold transition-all cursor-pointer ${
              layoutMode === 'flow'
                ? 'bg-[#7aa2f7] text-[#090a0f] shadow-sm'
                : 'text-[#7982a9] hover:text-white'
            }`}
            title="Sequential Flow Layout (Grid & Row wrapping)"
          >
            <Rows className="w-3.5 h-3.5" />
            <span>Sequential Flow</span>
          </button>

          <button
            type="button"
            onClick={() => setLayoutMode('pillar-right')}
            className={`flex items-center gap-1.5 px-2.5 py-1 rounded text-xs font-semibold transition-all cursor-pointer ${
              layoutMode === 'pillar-right'
                ? 'bg-[#7aa2f7] text-[#090a0f] shadow-sm'
                : 'text-[#7982a9] hover:text-white'
            }`}
            title="Pillar Right Layout (Languages pillar on right)"
          >
            <Columns className="w-3.5 h-3.5" />
            <span>Pillar Right</span>
          </button>
        </div>
      </div>

      {/* The Simulated GitHub Profile Viewport */}
      <div className="glass-panel rounded-xl p-4 sm:p-6 overflow-x-auto min-h-[480px] flex justify-center items-start">
        <div className="w-full max-w-[864px] transition-all">
          {activeCards.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 text-[#565f89] text-center">
              <LayoutGrid className="w-12 h-12 stroke-[1.5] mb-2 opacity-50" />
              <p className="text-sm font-medium">No cards active in this layout.</p>
              <p className="text-xs text-[#7982a9] mt-1">
                Enable cards from the catalog on the left to build your profile.
              </p>
            </div>
          ) : layoutMode === 'pillar-right' && langCard && leftCards.length > 0 ? (
            /* Pillar Right: Left stacked cards, Right languages pillar */
            <div className="flex flex-col md:flex-row gap-4 items-start justify-between">
              {/* Left Column */}
              <div className="flex flex-col gap-4 flex-1 w-full md:w-auto">
                {leftCards.map((card) => {
                  const globalIdx = activeCards.findIndex((c) => c.id === card.id)
                  return renderCardWrapper(card, globalIdx)
                })}
              </div>

              {/* Right Column: Languages Pillar */}
              <div className="w-full md:w-auto flex justify-center md:justify-end">
                {renderCardWrapper(langCard, activeCards.findIndex((c) => c.id === 'languages'))}
              </div>
            </div>
          ) : (
            /* Flow Mode: Naturally wraps cards (Hero cards span full width, half cards share rows) */
            <div className="flex flex-wrap gap-4 justify-center items-start">
              {activeCards.map((card, idx) => renderCardWrapper(card, idx))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
