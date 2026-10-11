import { ArrowUpRight, ChevronDown, SlidersHorizontal, Trash2 } from 'lucide-react'
import { THEMES } from '../constants/themes'
import { computeLanguagesHeight, getCardDef, cardRadius } from '../constants/cards'
import { CARD_ICONS } from '../constants/icons'

export default function Inspector({ card, themeId, onTheme, onUpdate, onRemove, target, onTarget, username }) {
  const def = card && getCardDef(card.id), Icon = card && CARD_ICONS[card.id]
  const minimum = card?.id === 'languages' ? computeLanguagesHeight(card.langsCount) : 180
  return <>
    <div className="panel-heading"><span>APPEARANCE</span><SlidersHorizontal size={13} /></div>
    <div className="theme-grid">{THEMES.map(theme => <button key={theme.id} title={theme.name} aria-label={`Use ${theme.name} theme`} aria-pressed={themeId === theme.id} onClick={() => onTheme(theme.id)} className={`theme-swatch ${themeId === theme.id ? 'selected' : ''}`}><span style={{ background: theme.bg }}><i style={{ background: theme.title }} /><i style={{ background: theme.text }} /><i style={{ background: theme.accent }} /></span></button>)}</div>
    <div className="theme-label"><strong>{THEMES.find(t => t.id === themeId)?.name}</strong><span>Card theme</span></div>
    <div className="inspector-divider" />
    <div className="panel-heading"><span>CARD SETTINGS</span><span className="small-label">{card ? '01 SELECTED' : 'NONE'}</span></div>
    {!card ? <p className="panel-caption">Select a card on the canvas to adjust its details.</p> : <div className="card-settings">
      <div className="selected-card-heading"><span className="selected-icon"><Icon size={19} /></span><div><h2>{def.name}</h2><p>{card.width} × {card.height} px</p></div></div>
      <label className="field-label" htmlFor="card-radius">Corner radius <span>default 4.5 px</span></label><div className="input-unit"><input id="card-radius" type="number" min="0" max={Math.min(card.width, card.height) / 2} step="0.5" value={cardRadius(card)} onChange={e => { if (e.target.value === '') return; const n = Number(e.target.value); if (Number.isFinite(n)) onUpdate(card.id, 'borderRadius', Math.min(Math.min(card.width, card.height) / 2, Math.max(0, n))) }} /><span>px</span></div>
      <label className="field-label">Width</label>
      {def.isHeroCapable ? <div className="segmented width-switch"><button className={card.width < 700 ? 'active' : ''} onClick={() => onUpdate(card.id, 'width', 424)}>Standard <small>424</small></button><button className={card.width >= 700 ? 'active' : ''} onClick={() => onUpdate(card.id, 'width', 840)}>Hero <small>840</small></button></div> : <div className="read-only-value">{card.width} px <span>Native card width</span></div>}
      {card.id === 'languages' && <>
        <div className="field-heading"><label className="field-label" htmlFor="language-count">Languages</label><output>{card.langsCount}</output></div><input id="language-count" type="range" min="6" max="16" step="1" value={card.langsCount} onChange={e => onUpdate(card.id, 'langsCount', Number(e.target.value))} /><div className="range-labels"><span>6 languages</span><span>16 languages</span></div>
        <label className="field-label" htmlFor="language-height">Height <span>minimum {minimum} px</span></label><div className="input-unit"><input id="language-height" type="number" min={minimum} max="1500" value={card.height} onChange={e => { const n = Number(e.target.value); if (Number.isFinite(n)) onUpdate(card.id, 'height', Math.min(1500, Math.max(minimum, n))) }} /><span>px</span></div><p className="field-help">Extra height increases row spacing. Real profiles can have fewer languages than your limit.</p>
        <label className="field-label" htmlFor="hidden-languages">Exclude languages</label><input id="hidden-languages" value={card.hide || ''} placeholder="HTML, CSS, Jupyter Notebook" onChange={e => onUpdate(card.id, 'hide', e.target.value)} /><p className="field-help">Comma-separated. Percentages recalculate automatically.</p>
        <label className="field-label" htmlFor="excluded-repos">Exclude repositories</label><input id="excluded-repos" value={card.excludeRepos || ''} placeholder="repo-name, another-repo" onChange={e => onUpdate(card.id, 'excludeRepos', e.target.value)} />
      </>}
      {card.id === 'streak' && <label className="toggle-field"><span>Contribution momentum<small>14-day sparkline</small></span><input type="checkbox" checked={card.sparkline !== false} onChange={e => onUpdate(card.id, 'sparkline', e.target.checked)} /><span className="toggle-track" aria-hidden="true" /></label>}
      {card.id === 'stats' && <><label className="field-label" htmlFor="stats-timeframe">Contribution scope</label><select id="stats-timeframe" value={card.timeframe || 'all-time'} onChange={e => onUpdate(card.id, 'timeframe', e.target.value)}><option value="all-time">All time</option><option value="this-year">Last 12 months (native “this-year”)</option></select><p className="field-help">Matches the native CLI. PR and star totals remain lifetime values.</p></>}
      {card.id === 'rhythm' && <><label className="field-label" htmlFor="rhythm-timezone">UTC offset</label><input id="rhythm-timezone" type="number" min="-12" max="14" step="0.25" value={card.timezone ?? 5.5} onChange={e => onUpdate(card.id, 'timezone', Math.min(14, Math.max(-12, Number(e.target.value))))} /><p className="field-help">Fractional offsets supported. Used for commit hours and day boundaries.</p></>}
      <button className="remove-card" onClick={() => onRemove(card.id)}><Trash2 size={13} /> Remove from canvas</button>
    </div>}
    <div className="inspector-divider" />
    <details className="destination-settings"><summary><span>EXPORT DESTINATION</span><ChevronDown size={13} /></summary><label className="field-label" htmlFor="repo-owner">Repository owner</label><input id="repo-owner" value={target.owner} placeholder={username || 'username'} onChange={e => onTarget({ owner: e.target.value })} /><label className="field-label" htmlFor="repo-name">Repository</label><input id="repo-name" value={target.repo} onChange={e => onTarget({ repo: e.target.value })} /><label className="field-label" htmlFor="repo-branch">Branch</label><input id="repo-branch" value={target.branch} onChange={e => onTarget({ branch: e.target.value })} /><p className="field-help">Generated SVGs live in this repository. Embed them in your separate profile README.</p></details>
    <a className="inspector-docs" href="https://github.com/adityapandeydev/git-stats#cli-reference--local-usage" target="_blank" rel="noreferrer">Explore the native engine <ArrowUpRight size={12} /></a>
  </>
}
