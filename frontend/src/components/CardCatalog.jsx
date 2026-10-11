import { ArrowDown, ArrowUp, Check, CircleDot, GripVertical, Plus, Trash2 } from 'lucide-react'
import { CARD_DEFINITIONS } from '../constants/cards'
import { useState } from 'react'
import { CARD_ICONS } from '../constants/icons'
const labels = { streak: 'Contribution streak', stats: 'Developer stats', languages: 'Top languages', rhythm: 'Commit rhythm', radar: 'Developer DNA', velocity: 'PR velocity', milestones: 'Career milestones' }

export function DragHandle({ id, onStart, onEnd }) {
  return <button className="drag-handle" aria-label={`Drag ${labels[id]}`} title="Drag to reorder" draggable onDragStart={e => { e.stopPropagation(); e.dataTransfer.effectAllowed = 'move'; e.dataTransfer.setData('application/x-gitstats-card', id); onStart?.(id) }} onDragEnd={onEnd}><GripVertical size={14} /></button>
}

export default function CardCatalog({ cards, selected, onSelect, onToggle, onReorder, onMove, layoutMode }) {
  const [dragging, setDragging] = useState(null)
  const [over, setOver] = useState(null)
  return <>
    <div className="panel-heading"><span>YOUR CARDS</span><span className="count-badge">{cards.length.toString().padStart(2, '0')}</span></div>
    <p className="panel-caption">Arrange your profile, one card at a time.</p>
    <div className="layer-list">
      {cards.map((card, index) => { const Icon = CARD_ICONS[card.id]; return <div key={card.id} data-layer={card.id} className={`layer-row ${selected === card.id ? 'selected' : ''} ${over === card.id && dragging !== card.id ? 'drop-target' : ''}`} onDragOver={e => { if (e.dataTransfer.types.includes('application/x-gitstats-card')) { e.preventDefault(); setOver(card.id) } }} onDrop={e => { e.preventDefault(); onReorder(e.dataTransfer.getData('application/x-gitstats-card'), card.id); setOver(null); setDragging(null) }}>
        <DragHandle id={card.id} onStart={setDragging} onEnd={() => { setDragging(null); setOver(null) }} />
        <button className="layer-select" onClick={() => onSelect(card.id)} aria-pressed={selected === card.id}><Icon size={16} /><span>{labels[card.id]}<small>{card.width >= 700 ? 'Full width' : card.id === 'languages' && layoutMode === 'pillar-right' ? 'Pinned right' : `${card.width} × ${card.height}`}</small></span></button>
        <div className="layer-actions"><button aria-label={`Move ${labels[card.id]} up`} disabled={!index} onClick={() => onMove(card.id, -1)}><ArrowUp size={12} /></button><button aria-label={`Move ${labels[card.id]} down`} disabled={index === cards.length - 1} onClick={() => onMove(card.id, 1)}><ArrowDown size={12} /></button><button aria-label={`Remove ${labels[card.id]}`} onClick={() => onToggle(card.id)}><Trash2 size={12} /></button></div>
      </div> })}
      {!cards.length && <div className="empty-layers"><CircleDot size={18} /><p>Your canvas is empty.<br/>Add a card below to begin.</p></div>}
    </div>
    <div className="panel-heading catalog-heading"><span>ADD TO CANVAS</span><Plus size={13} /></div>
    <div className="catalog-list">{CARD_DEFINITIONS.map(def => { const Icon = CARD_ICONS[def.id], added = cards.some(c => c.id === def.id); return <button className="catalog-item" key={def.id} disabled={added} onClick={() => onToggle(def.id)}><Icon size={16} /><span>{labels[def.id]}</span>{added ? <Check size={14} /> : <Plus size={14} />}</button> })}</div>
    <p className="catalog-hint">Select a card to fine-tune its details.</p>
  </>
}
