import { useEffect, useMemo, useState } from 'react'
import { ArrowDown, ArrowLeft, ArrowRight, ArrowUp, CircleAlert, Eye, LayoutGrid, LoaderCircle, Plus, RotateCcw, Trash2, X } from 'lucide-react'
import { CARDS, DEFAULT_CONFIG, ROW_TYPES, cardById, formatOffset } from '../services/profileConfig'
import { addRow, autoPlace, canPlace, deleteRow, findCard, moveRow, placeCard, removeCard } from '../services/layoutOps'
import { renderCard } from '../services/profilePreview'
import { THEMES } from '../constants/themes'
import NumberField from '../components/NumberField'
import ReadmePreview from './ReadmePreview'

const toUrl = svg => `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`

export default function DesignStep({ config, setConfig, data, engine, engineError, onBack, onNext, canPublish }) {
  const [view, setView] = useState('layout')
  const [selected, setSelected] = useState(() => config.layout.flatMap(r => r.cards).find(Boolean) || null)
  const [dragging, setDragging] = useState(null)
  const [over, setOver] = useState(null)
  const [armed, setArmed] = useState(null)
  const layout = config.layout
  const setLayout = fn => setConfig(c => ({ ...c, layout: fn(c.layout) }))
  const active = dragging || armed

  useEffect(() => {
    if (!armed) return
    const onKey = e => { if (e.key === 'Escape') setArmed(null) }
    addEventListener('keydown', onKey)
    return () => removeEventListener('keydown', onKey)
  }, [armed])

  // One render per card per change; the palette and the canvas share it.
  const images = useMemo(() => engine ? Object.fromEntries(CARDS.map(c => [c.id, toUrl(renderCard(engine, c.id, config, data).svg)])) : {}, [engine, config, data])
  const drop = (r, s) => {
    if (!active || !canPlace(layout, active, r, s)) return
    setLayout(l => placeCard(l, active, r, s))
    setSelected(active)
    setArmed(null); setDragging(null); setOver(null)
  }
  const dragProps = id => ({
    draggable: true,
    onDragStart: e => { e.dataTransfer.effectAllowed = 'move'; e.dataTransfer.setData('text/plain', id); setDragging(id); setArmed(null) },
    onDragEnd: () => { setDragging(null); setOver(null) },
  })
  const isSample = data?.source === 'demo'

  return <div className="design">
    <aside className="panel panel-pad palette" aria-label="Cards">
      <div className="panel-title">Cards</div>
      <div className="palette-list">
        {CARDS.map(card => {
          const placed = Boolean(findCard(layout, card.id))
          return <button key={card.id} type="button" className={`chip ${placed ? 'placed' : ''} ${armed === card.id ? 'armed' : ''}`} {...(placed ? {} : dragProps(card.id))}
            onClick={() => { if (placed) setSelected(card.id); else setArmed(armed === card.id ? null : card.id) }}
            onDoubleClick={() => { if (!placed) { setLayout(l => autoPlace(l, card.id)); setSelected(card.id); setArmed(null) } }}
            aria-pressed={armed === card.id} aria-label={`${card.name}${placed ? ', on your layout' : ''}`}>
            {images[card.id] ? <img src={images[card.id]} alt="" /> : <span className="card-loading" style={{ width: 64 }} />}
            <span><strong>{card.name}</strong><small>{placed ? 'On layout' : card.tall ? 'Tall · stacked rows' : card.wide ? 'Standard or full width' : 'Standard'}</small></span>
          </button>
        })}
      </div>
      <p className="hint">{armed ? <>Now choose a highlighted slot. <button className="btn btn-sm btn-ghost" onClick={() => setArmed(null)}>Cancel</button></> : 'Drag a card onto the layout. On touch screens, tap a card and then a slot. Double-click to add it to the first free spot.'}</p>
    </aside>

    <section className="canvas" aria-label="Layout">
      <div className="canvas-toolbar">
        <div className="segmented" role="group" aria-label="View">
          <button aria-pressed={view === 'layout'} onClick={() => setView('layout')}><LayoutGrid size={14} /> Layout</button>
          <button aria-pressed={view === 'github'} onClick={() => setView('github')}><Eye size={14} /> On GitHub</button>
        </div>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          <span className={`badge ${isSample ? 'sample' : 'live'}`}><span className="dot" />{isSample ? 'Sample data' : `@${data.login}`}</span>
          <button className="btn btn-sm btn-ghost" onClick={() => setConfig(c => ({ ...c, layout: DEFAULT_CONFIG.layout }))} title="Restore the default layout"><RotateCcw size={14} /> Reset</button>
        </div>
      </div>
      {engineError && <div className="notice error" role="alert"><CircleAlert size={16} />{engineError}</div>}
      {view === 'github' ? <ReadmePreview key="preview" config={config} data={data} engine={engine} /> : <div className="rows enter" key="layout">
        {!layout.length && <div className="empty-canvas"><LayoutGrid size={30} strokeWidth={1.5} /><h3>Start with a row</h3><p>Add a row below, then drag cards into it.</p></div>}
        {layout.map((row, r) => <div key={r} className={`row ${row.type}`}>
          <div className="row-head"><span>{ROW_TYPES[row.type].label}</span>
            <span className="row-tools">
              <button aria-label="Move row up" disabled={!r} onClick={() => setLayout(l => moveRow(l, r, -1))}><ArrowUp size={13} /></button>
              <button aria-label="Move row down" disabled={r === layout.length - 1} onClick={() => setLayout(l => moveRow(l, r, 1))}><ArrowDown size={13} /></button>
              <button aria-label="Delete row" onClick={() => setLayout(l => deleteRow(l, r))}><X size={13} /></button>
            </span>
          </div>
          {row.cards.map((id, s) => {
            const key = `${r}-${s}`
            const ok = active && canPlace(layout, active, r, s)
            const state = over === key ? (ok ? 'over' : 'reject') : active && ok && id !== active ? 'can-take' : ''
            return <div key={key} className={`slot ${id ? 'filled' : ''} ${row.type === 'stack' && s === 2 ? 'tall' : ''} ${state}`}
              onDragOver={e => { if (!dragging) return; if (ok) { e.preventDefault(); e.dataTransfer.dropEffect = 'move' } setOver(key) }}
              onDragLeave={() => setOver(o => (o === key ? null : o))}
              onDrop={e => { e.preventDefault(); drop(r, s) }}
              onClick={() => { if (armed) drop(r, s) }}>
              {id ? <div className={`slot-card ${selected === id ? 'selected' : ''}`} {...dragProps(id)} onClick={e => { if (!armed) { e.stopPropagation(); setSelected(id) } }}>
                {images[id] ? <img src={images[id]} alt={cardById(id).name} draggable="false" /> : <div className="card-loading"><LoaderCircle size={18} className="spin" /></div>}
                <button className="remove" aria-label={`Remove ${cardById(id).name}`} onClick={e => { e.stopPropagation(); setLayout(l => removeCard(l, id)); if (selected === id) setSelected(null) }}><Trash2 size={13} /></button>
              </div> : <span>{active ? (ok ? 'Drop here' : slotHint(row.type, s)) : slotHint(row.type, s)}</span>}
            </div>
          })}
        </div>)}
        <div className="add-row">
          {Object.entries(ROW_TYPES).map(([type, t]) => <button key={type} className="btn btn-sm" onClick={() => setLayout(l => addRow(l, type))}><Plus size={14} /> {t.label}</button>)}
        </div>
      </div>}
    </section>

    <aside className="panel panel-pad inspector" aria-label="Settings">
      <div>
        <div className="panel-title">Theme</div>
        <div className="themes">
          {THEMES.map(t => <button key={t.id} className="theme-swatch" aria-pressed={config.theme === t.id} onClick={() => setConfig(c => ({ ...c, theme: t.id }))}>
            <span style={{ background: t.bg, border: `1px solid ${t.border}` }}><i style={{ background: t.title }} /><i style={{ background: t.text }} /><i style={{ background: t.muted }} /></span>{t.name}
          </button>)}
        </div>
      </div>
      <CardSettings id={selected && findCard(layout, selected) ? selected : null} config={config} setConfig={setConfig} />
      <div className="field">
        <label className="label" htmlFor="radius">Corner radius <span>all cards · px</span></label>
        <NumberField key={config.radius} id="radius" min={0} max={24} value={config.radius} onCommit={radius => setConfig(c => ({ ...c, radius }))} />
      </div>
      <div className="step-footer" style={{ justifyContent: 'space-between' }}>
        <button className="btn btn-ghost" onClick={onBack}><ArrowLeft size={16} /> Profile</button>
        <button className="btn btn-primary" disabled={!canPublish || !layout.some(r => r.cards.some(Boolean))} onClick={onNext} >Publish <ArrowRight size={16} className="nudge" /></button>
        {!canPublish && <p className="hint">Add your username in <button className="btn btn-sm btn-ghost" onClick={onBack}>Profile</button> to publish.</p>}
      </div>
    </aside>
  </div>
}

function slotHint(type, slot) {
  if (type === 'stack' && slot === 2) return 'Top languages'
  if (type === 'wide') return 'Streak, rhythm or milestones'
  return 'Any card'
}

function CardSettings({ id, config, setConfig }) {
  const o = config.options
  const set = patch => setConfig(c => ({ ...c, options: { ...c.options, ...patch } }))
  if (!id) return <div className="settings"><h3>Card settings</h3><p className="hint">Select a card on the layout to change its settings.</p></div>
  const card = cardById(id)
  const filters = <>
    <div className="field"><label className="label" htmlFor="hide">Hide languages</label><input id="hide" className="input" value={o.hideLanguages} placeholder="HTML, CSS, Jupyter Notebook" onChange={e => set({ hideLanguages: e.target.value.replace(/[\r\n]/g, '') })} /></div>
    <div className="field"><label className="label" htmlFor="exclude">Skip repositories</label><input id="exclude" className="input" value={o.excludeRepos} placeholder="dotfiles, old-site" onChange={e => set({ excludeRepos: e.target.value.replace(/[\r\n]/g, '') })} /></div>
    <p className="hint">Comma-separated. Applies to both Top languages and Developer DNA.</p>
  </>
  return <div className="settings" key={id}>
    <h3>{card.name}</h3>
    <p>{card.blurb}</p>
    {id === 'languages' && <>
      <div className="field"><label className="label" htmlFor="count">Languages shown</label>
        <div className="range-row"><input id="count" type="range" min="6" max="16" value={o.languagesCount} onChange={e => set({ languagesCount: Number(e.target.value) })} /><output htmlFor="count">{o.languagesCount}</output></div></div>
      {filters}
    </>}
    {id === 'radar' && filters}
    {id === 'streak' && <label className="switch"><span><strong style={{ display: 'block', fontSize: 14 }}>14-day activity</strong><span className="hint">Daily contributions under the streak</span></span><input type="checkbox" checked={o.sparkline} onChange={e => set({ sparkline: e.target.checked })} /></label>}
    {id === 'stats' && <div className="field"><label className="label" htmlFor="timeframe">Commits counted</label>
      <select id="timeframe" className="select" value={o.timeframe} onChange={e => set({ timeframe: e.target.value })}><option value="all-time">All time</option><option value="this-year">Last 12 months</option></select>
      <p className="hint">Pull requests and stars are always lifetime totals.</p></div>}
    {id === 'rhythm' && <div className="field"><label className="label" htmlFor="tz">Timezone <span>{formatOffset(o.timezone)}</span></label>
      <NumberField key={o.timezone} id="tz" min={-12} max={14} value={o.timezone} onCommit={timezone => set({ timezone })} />
      <p className="hint">Hours from UTC, for example 5.5 or −3. <button className="btn btn-sm btn-ghost" onClick={() => set({ timezone: Math.round(-new Date().getTimezoneOffset() / 15) / 4 })}>Use mine</button></p></div>}
    {(id === 'velocity' || id === 'milestones') && <p className="hint">This card has no settings.</p>}
    {card.wide && <p className="hint">Tip: put it in a full-width row to make it 840 px wide.</p>}
  </div>
}

