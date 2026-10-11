import { useLayoutEffect, useRef, useState } from 'react'
import { ArrowDown, ArrowUp, Columns2, Expand, Eye, Layers3, LayoutGrid, Maximize2, Minimize2, Monitor, Smartphone, Trash2 } from 'lucide-react'
import CardRenderer from './cards/CardRenderer'
import { getCardDef } from '../constants/cards'
import { layoutCards } from '../services/compiler'
import { DragHandle } from './CardCatalog'

export default function ProfileCanvas({ activeCards, selected, onSelect, layoutMode, onLayout, themeId, userData, onReorder, onMove, onToggle, onWidth }) {
  const [device, setDevice] = useState('desktop')
  const [clean, setClean] = useState(false)
  const [dragging, setDragging] = useState(null)
  const [over, setOver] = useState(null)
  const [viewport, setViewport] = useState(900)
  const container = useRef(null)
  useLayoutEffect(() => {
    const observer = new ResizeObserver(([entry]) => setViewport(entry.contentRect.width))
    if (container.current) observer.observe(container.current)
    return () => observer.disconnect()
  }, [])
  const layout = layoutCards(activeCards, layoutMode)
  const logicalWidth = device === 'mobile' ? 424 : 860
  const scale = Math.min(1, Math.max(0.15, (viewport - 48) / logicalWidth))
  const gap = clean ? 12 : 38
  const height = c => c.height
  const heroHeight = layout.heroes.reduce((sum, c) => sum + height(c) + gap, 0)
  const bodyHeight = device === 'mobile' ? activeCards.reduce((sum, c) => sum + height(c) * Math.min(1, 424 / c.width) + gap, 0) : Math.max(layout.rows.reduce((sum, row) => sum + Math.max(...row.map(height)) + gap, 0), layout.pillar?.height || 0) + heroHeight

  const wrapper = card => {
    const def = getCardDef(card.id), index = activeCards.findIndex(c => c.id === card.id)
    const cardScale = device === 'mobile' ? Math.min(1, 424 / card.width) : 1
    return <div key={card.id} data-canvas-card={card.id} className={`canvas-card ${selected === card.id && !clean ? 'is-selected' : ''} ${over === card.id && dragging !== card.id ? 'drop-target' : ''} ${dragging === card.id ? 'is-dragging' : ''}`} style={{ width: card.width * cardScale, height: card.height * cardScale }} onClick={() => onSelect(card.id)} onDragOver={e => { if (e.dataTransfer.types.includes('application/x-gitstats-card')) { e.preventDefault(); e.dataTransfer.dropEffect = 'move'; setOver(card.id) } }} onDrop={e => { e.preventDefault(); onReorder(e.dataTransfer.getData('application/x-gitstats-card'), card.id); setDragging(null); setOver(null) }}>
      {!clean && <div className="canvas-card-tools" onClick={e => e.stopPropagation()}><div><DragHandle id={card.id} onStart={setDragging} onEnd={() => { setDragging(null); setOver(null) }} /><button className="canvas-card-title" onClick={() => onSelect(card.id)}>{def.name}</button></div><div><button aria-label={`Move ${def.name} up on canvas`} disabled={!index} onClick={() => onMove(card.id, -1)}><ArrowUp size={12} /></button><button aria-label={`Move ${def.name} down on canvas`} disabled={index === activeCards.length - 1} onClick={() => onMove(card.id, 1)}><ArrowDown size={12} /></button>{def.isHeroCapable && <button aria-label={`Toggle ${def.name} full width`} onClick={() => onWidth(card.id, card.width >= 700 ? 424 : 840)}>{card.width >= 700 ? <Minimize2 size={12} /> : <Maximize2 size={12} />}</button>}<button aria-label={`Remove ${def.name} from canvas`} onClick={() => onToggle(card.id)}><Trash2 size={12} /></button></div></div>}
      <div style={{ width: card.width, transform: `scale(${cardScale})`, transformOrigin: 'top left' }}><CardRenderer card={card} themeId={themeId} userData={userData} /></div>
    </div>
  }
  return <div className="canvas-panel">
    <div className="canvas-toolbar"><div className="segmented layout-switch" aria-label="Layout mode"><button className={layoutMode === 'pillar-right' ? 'active' : ''} onClick={() => onLayout('pillar-right')}><Columns2 size={14} /><span>Pillar right</span></button><button className={layoutMode === 'flow' ? 'active' : ''} onClick={() => onLayout('flow')}><LayoutGrid size={14} /><span>Flow</span></button></div><div className="canvas-views"><button className={`icon-button ${device === 'desktop' ? 'active' : ''}`} aria-label="Desktop preview" onClick={() => setDevice('desktop')}><Monitor size={15} /></button><button className={`icon-button ${device === 'mobile' ? 'active' : ''}`} aria-label="Mobile preview" onClick={() => setDevice('mobile')}><Smartphone size={15} /></button><span className="toolbar-divider" /><button className={`icon-button ${clean ? 'active' : ''}`} aria-label={clean ? 'Show editing controls' : 'Hide editing controls'} onClick={() => setClean(!clean)}><Eye size={15} /></button></div></div>
    <div className="canvas-stage" ref={container}>
      <div className="canvas-ruler"><span>README.md</span><span>{device === 'desktop' ? '860' : '424'} PX</span></div>
      {!activeCards.length ? <div className="canvas-empty"><Layers3 size={35} strokeWidth={1} /><h2>A blank canvas.<br/>A good place to start.</h2><p>Add your first card from the panel on the left.</p></div> : <div className="scaled-preview" style={{ width: logicalWidth * scale, height: bodyHeight * scale }}><div className="profile-composition" style={{ width: logicalWidth, transform: `scale(${scale})`, transformOrigin: 'top left', gap }}>
        {device === 'mobile' ? activeCards.map(wrapper) : <>{layout.heroes.map(wrapper)}<div className="profile-columns" style={{ gap: 12 }}><div className="profile-rows" style={{ gap }}>{layout.rows.map((row, i) => <div className="profile-row" style={{ gap: 12 }} key={i}>{row.map(wrapper)}</div>)}</div>{layout.pillar && wrapper(layout.pillar)}</div></>}
      </div></div>}
      <div className="canvas-stage-footer"><span>{clean ? 'Preview mode' : 'Drag handles to arrange · Select to edit'}</span><span><Expand size={11} /> {Math.round(scale * 100)}% · Fit</span></div>
    </div>
    <div className="canvas-footnote"><span className="status-dot live" />Rendered by Zig 0.16.0<span>SVG / resolution independent</span></div>
  </div>
}
