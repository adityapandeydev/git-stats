import { useEffect, useMemo, useState } from 'react'
import { ArrowUpRight, Check, CircleHelp, Code2, Layers3, Link2, LoaderCircle, RotateCcw, SlidersHorizontal, X } from 'lucide-react'
import Navbar from './components/Navbar'
import CardCatalog from './components/CardCatalog'
import ProfileCanvas from './components/ProfileCanvas'
import Inspector from './components/Inspector'
import ExportDeck from './components/ExportDeck'
import DeployModal from './components/DeployModal'
import Dialog from './components/Dialog'
import TokenGuide from './components/TokenGuide'
import { DEFAULT_ACTIVE_CARDS, createCard, computeLanguagesHeight, getCardDef, cardRadius } from './constants/cards'
import { THEMES } from './constants/themes'
import { generateProfileHtml, generateWorkflowYaml } from './services/compiler'
import { fetchUserData } from './services/githubApi'
import { DEMO_DATA } from './services/demo'

const storageKey = 'gitstats-studio-v1'
const defaults = { version: 1, username: 'octocat', themeId: 'tokyonight', activeCards: DEFAULT_ACTIVE_CARDS, layoutMode: 'pillar-right', target: { owner: '', repo: 'git-stats', branch: 'main' } }
function restoreCard(card) {
  const def = getCardDef(card.id)
  const count = Math.min(16, Math.max(6, Math.round(Number(card.langsCount) || 12)))
  return { ...createCard(card.id), borderRadius: cardRadius(card),
    width: def.isHeroCapable ? card.width >= 700 ? 840 : 424 : def.defaultWidth,
    height: Math.max(card.id === 'languages' ? computeLanguagesHeight(count) : 180, card.height),
    langsCount: count, hide: typeof card.hide === 'string' ? card.hide : '', excludeRepos: typeof card.excludeRepos === 'string' ? card.excludeRepos : '',
    sparkline: card.sparkline !== false, timeframe: card.timeframe === 'this-year' ? 'this-year' : 'all-time',
    timezone: Number.isFinite(Number(card.timezone)) ? Math.min(14, Math.max(-12, Number(card.timezone))) : 5.5,
  }
}
function restore() {
  const params = new URLSearchParams(location.search)
  const urlUser = params.get('user') || params.get('u')
  try {
    const value = JSON.parse(localStorage.getItem(storageKey))
    if (value?.version === 1 && Array.isArray(value.activeCards) && value.activeCards.length <= 7 && value.activeCards.every(c => getCardDef(c.id) && Number.isInteger(c.width) && c.width >= 300 && c.width <= 1200 && Number.isInteger(c.height) && c.height >= 124 && c.height <= 1500) && new Set(value.activeCards.map(c => c.id)).size === value.activeCards.length) {
      return { ...defaults, ...value, username: urlUser || (typeof value.username === 'string' ? value.username : defaults.username), layoutMode: value.layoutMode === 'flow' ? 'flow' : 'pillar-right', themeId: THEMES.some(t => t.id === value.themeId) ? value.themeId : defaults.themeId, target: Object.fromEntries(Object.entries(defaults.target).map(([key, fallback]) => [key, typeof value.target?.[key] === 'string' ? value.target[key] : fallback])), activeCards: value.activeCards.map(restoreCard) }
    }
  } catch { /* Storage may be unavailable or contain an older draft. */ }
  return { ...defaults, username: urlUser || defaults.username }
}

export default function App() {
  const [config, setConfig] = useState(restore)
  const [selected, setSelected] = useState('streak')
  const [data, setData] = useState(DEMO_DATA)
  const [live, setLive] = useState(() => Boolean(new URLSearchParams(location.search).get('user') || new URLSearchParams(location.search).get('u')))
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [token, setToken] = useState('')
  const [tokenDraft, setTokenDraft] = useState('')
  const [connectOpen, setConnectOpen] = useState(false)
  const [deployOpen, setDeployOpen] = useState(false)
  const [exportOpen, setExportOpen] = useState(false)
  const [mobilePanel, setMobilePanel] = useState('')
  const [refresh, setRefresh] = useState(0)
  const [saved, setSaved] = useState(true)
  const { username, themeId, activeCards, layoutMode, target } = config
  const update = patch => setConfig(previous => ({ ...previous, ...patch }))

  useEffect(() => {
    // Persist immediately so navigation cannot discard the latest edit.
    let stored = true
    try { localStorage.setItem(storageKey, JSON.stringify(config)) }
    catch { stored = false }
    // Storage is an external system; this reports its success to the user.
    // oxlint-disable-next-line react/set-state-in-effect
    setSaved(stored)
  }, [config])
  useEffect(() => {
    if (!live) return
    const controller = new AbortController()
    const timer = setTimeout(() => {
      setLoading(true); setError(''); setData(null)
      fetchUserData(username, token, { signal: controller.signal }).then(result => {
        if (!controller.signal.aborted) setData(result)
      }).catch(e => {
        if (!controller.signal.aborted) setError(e.message)
      }).finally(() => { if (!controller.signal.aborted) setLoading(false) })
    }, 650)
    return () => { clearTimeout(timer); controller.abort() }
  }, [username, token, live, refresh])

  const toggle = id => {
    setConfig(previous => {
      const exists = previous.activeCards.some(c => c.id === id)
      return { ...previous, activeCards: exists ? previous.activeCards.filter(c => c.id !== id) : [...previous.activeCards, createCard(id)] }
    })
    setSelected(id)
  }
  const updateCard = (id, property, value) => setConfig(previous => ({ ...previous, activeCards: previous.activeCards.map(card => {
    if (card.id !== id) return card
    const next = { ...card, [property]: value }
    if (property === 'langsCount') next.height = computeLanguagesHeight(value) + Math.max(0, card.height - computeLanguagesHeight(card.langsCount))
    return next
  }) }))
  const reorder = (sourceId, targetId) => setConfig(previous => {
    const cards = [...previous.activeCards], from = cards.findIndex(c => c.id === sourceId), to = cards.findIndex(c => c.id === targetId)
    if (from < 0 || to < 0 || from === to) return previous
    const [card] = cards.splice(from, 1); cards.splice(to, 0, card)
    return { ...previous, activeCards: cards }
  })
  const move = (id, delta) => {
    const index = activeCards.findIndex(c => c.id === id)
    if (activeCards[index + delta]) reorder(id, activeCards[index + delta].id)
  }
  const compiled = useMemo(() => {
    try { return { html: generateProfileHtml(username, activeCards, layoutMode, target), yaml: generateWorkflowYaml(username, activeCards, themeId, '', target) } }
    catch (e) { return { html: '', yaml: '', error: e.message } }
  }, [username, activeCards, layoutMode, themeId, target])
  const selectedCard = activeCards.find(c => c.id === selected)
  const sourceLabel = loading ? 'Loading GitHub' : data?.source === 'demo' ? 'Sample data' : data?.source === 'authenticated' ? 'Connected to GitHub' : data?.source === 'public' ? 'Public data · limited' : 'Data unavailable'

  return <div className="studio-shell">
    <Navbar username={username} onUsername={value => { update({ username: value }); if (live) { setData(null); setError(''); setLoading(true) } }} onLoad={() => { setData(null); setError(''); setLoading(true); setLive(true); setRefresh(n => n + 1) }} loading={loading} onExport={() => setExportOpen(true)} onDeploy={() => setDeployOpen(true)} canExport={!compiled.error} connected={Boolean(token)} onConnect={() => { setTokenDraft(token); setConnectOpen(true) }} />
    <div className="workspace-heading">
      <div><div className="eyebrow">PROFILE WORKSPACE <span>/</span> 01</div><h1>Make your work visible<span>.</span></h1><p>A profile that looks like you. Built with your data.</p></div>
      <div className="heading-meta"><span className="save-state"><Check size={13} />{saved ? 'Draft saved on this device' : 'Draft in memory only'}</span><a href="https://github.com/adityapandeydev/git-stats" target="_blank" rel="noreferrer">View engine <ArrowUpRight size={13} /></a></div>
    </div>
    <div className="mobile-panel-tabs"><button onClick={() => setMobilePanel(mobilePanel === 'cards' ? '' : 'cards')}><Layers3 size={15} /> Cards</button><button onClick={() => setMobilePanel(mobilePanel === 'settings' ? '' : 'settings')}><SlidersHorizontal size={15} /> Settings</button></div>
    {mobilePanel && <button className="panel-scrim" aria-label="Close side panel" onClick={() => setMobilePanel('')} />}
    <main className="studio-workspace">
      <aside className={`left-panel ${mobilePanel === 'cards' ? 'panel-open' : ''}`} aria-label="Card layers">
        <button className="panel-dismiss" aria-label="Close cards panel" onClick={() => setMobilePanel('')}><X size={17} /> Close</button>
        <CardCatalog cards={activeCards} selected={selected} onSelect={id => { setSelected(id); setMobilePanel('settings') }} onToggle={toggle} onReorder={reorder} onMove={move} layoutMode={layoutMode} />
        <div className="sidebar-note"><Code2 size={17} /><div><strong>Native by design</strong><p>These SVGs come from the same Zig renderer as your profile.</p></div></div>
      </aside>
      <section className="canvas-column" aria-label="Profile designer">
        <ProfileCanvas username={username} target={target} activeCards={activeCards} selected={selected} onSelect={id => { setSelected(id); setMobilePanel('settings') }} layoutMode={layoutMode} onLayout={value => update({ layoutMode: value })} themeId={themeId} userData={data} onReorder={reorder} onMove={move} onToggle={toggle} onWidth={(id, width) => updateCard(id, 'width', width)} />
        <div className="data-strip"><span className={`status-dot ${data?.source === 'authenticated' ? 'live' : ''}`} /><strong>{sourceLabel}</strong>{loading && <LoaderCircle size={13} className="spin" />}<span className="data-account">{data && data.source !== 'demo' ? `@${data.login}` : 'Design freely, then load your profile'}</span><button onClick={() => { setTokenDraft(token); setConnectOpen(true) }}><Link2 size={13} />{token ? 'Manage connection' : 'Connect GitHub'}</button></div>
        {error && <div className="notice error" role="alert">{error}<button onClick={() => { setLive(false); setLoading(false); setError(''); setData(DEMO_DATA) }}>Use sample data</button></div>}
        <details className="data-details"><summary><CircleHelp size={13} /> About this preview</summary>{(data?.notes || ['Load a profile to view its available data.']).map(note => <p key={note}>{note}</p>)}</details>
      </section>
      <aside className={`right-panel ${mobilePanel === 'settings' ? 'panel-open' : ''}`} aria-label="Card inspector"><button className="panel-dismiss" aria-label="Close settings panel" onClick={() => setMobilePanel('')}><X size={17} /> Close</button><Inspector card={selectedCard} themeId={themeId} onTheme={value => update({ themeId: value })} onUpdate={updateCard} onRemove={toggle} target={target} onTarget={value => update({ target: { ...target, ...value } })} username={username} /></aside>
    </main>
    <footer className="studio-footer"><span><span className="footer-mark">gs</span> Engineered in Zig. Designed by you.</span><button onClick={() => { update({ activeCards: DEFAULT_ACTIVE_CARDS, themeId: 'tokyonight', layoutMode: 'pillar-right' }); setSelected('streak') }}><RotateCcw size={12} /> Reset design</button><span className="footer-version">STUDIO / v1.0</span></footer>
    {exportOpen && <ExportDeck htmlCode={compiled.html} yamlCode={compiled.yaml} error={compiled.error} onClose={() => setExportOpen(false)} />}
    {deployOpen && <DeployModal dataSource={data?.source} username={username} yamlContent={compiled.yaml} error={compiled.error} target={target} onTarget={value => update({ target: { ...target, ...value } })} onClose={() => setDeployOpen(false)} />}
    {connectOpen && <Dialog onClose={() => setConnectOpen(false)} labelledBy="connection-title" className="connection-dialog">
      <div className="dialog-heading"><div><span className="eyebrow">DATA CONNECTION</span><h2 id="connection-title">Bring your profile to life.</h2></div><button className="icon-button" aria-label="Close connection" onClick={() => setConnectOpen(false)}><X size={18} /></button></div>
      <p>Preview with read access. A token lets Studio load contribution history, rhythm, PR velocity, and achievements. Public previews include languages and developer DNA.</p>
      <label className="field-label" htmlFor="read-token">Preview token · read access</label><input autoFocus id="read-token" type="password" autoComplete="off" placeholder="github_pat_…" value={tokenDraft} onChange={e => setTokenDraft(e.target.value)} />
      <p className="field-help">Choose the repositories you want included and grant read access to their contents, pull requests, and issues. GitHub account and organization policies can limit visibility. Tokens stay in tab memory, never in drafts or exports.</p>
      <TokenGuide />
      <p className="field-help">Want Studio to commit the workflow? Deploy profile has a separate temporary write-token field. A deployment token restricted to your fork can be used in both fields for public data. For broader private previews, keep the read token separate so those repositories do not receive write access.</p>
      <div className="dialog-actions"><button className="button secondary" onClick={() => { setToken(''); setTokenDraft(''); setConnectOpen(false) }}>Disconnect</button><button className="button primary" onClick={() => { setToken(tokenDraft.trim()); setTokenDraft(''); setLive(true); setRefresh(n => n + 1); setConnectOpen(false) }}>Load profile <ArrowUpRight size={15} /></button></div>
    </Dialog>}
  </div>
}

