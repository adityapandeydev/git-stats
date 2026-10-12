import { useEffect, useMemo, useRef, useState, useLayoutEffect } from 'react'
import { Monitor, Smartphone, Sun, Moon, Maximize2, Minimize2 } from 'lucide-react'
import { loadEngine } from '../services/engine'
import { profilePreview } from '../services/profilePreview'

export default function ProfilePreview({ username, activeCards, layoutMode, themeId, userData, target }) {
  const [engine, setEngine] = useState(null), [error, setError] = useState('')
  const [mobile, setMobile] = useState(false), [light, setLight] = useState(false), [fit, setFit] = useState(true)
  const [availableWidth, setAvailableWidth] = useState(900)
  const container = useRef(null)
  useEffect(() => {
    let active = true
    loadEngine().then(value => { if (active) setEngine(value) }).catch(e => { if (active) setError(e.message) })
    return () => { active = false }
  }, [])
  useLayoutEffect(() => {
    const observer = new ResizeObserver(([entry]) => setAvailableWidth(entry.contentRect.width))
    if (container.current) observer.observe(container.current)
    return () => observer.disconnect()
  }, [])
  const result = useMemo(() => {
    if (!engine) return null
    try { return profilePreview({ engine, username, cards: activeCards, layoutMode, themeId, userData, target, light }) }
    catch (e) { return { error: e.message } }
  }, [engine, username, activeCards, layoutMode, themeId, userData, target, light])
  const width = mobile ? 375 : 928
  const scale = fit ? Math.min(1, Math.max(0.1, (availableWidth - 32) / width)) : 1
  // Allow native document scrolling without scripts or access to the parent tab.
  const height = mobile ? 560 : 460
  return <section className="readme-preview" aria-label="Final profile preview">
    <div className="readme-preview-toolbar"><div className="segmented" aria-label="README viewport"><button className={!mobile ? 'active' : ''} aria-pressed={!mobile} onClick={() => setMobile(false)}><Monitor size={14} />Desktop</button><button className={mobile ? 'active' : ''} aria-pressed={mobile} onClick={() => setMobile(true)}><Smartphone size={14} />Mobile</button></div><div className="canvas-views"><button className="icon-button" aria-label={light ? 'Use dark README background' : 'Use light README background'} onClick={() => setLight(!light)}>{light ? <Moon size={15} /> : <Sun size={15} />}</button><button className="preview-size-button" onClick={() => setFit(!fit)}>{fit ? <Maximize2 size={13} /> : <Minimize2 size={13} />}{fit ? 'Actual size' : 'Fit to panel'}</button></div></div>
    <div className="readme-preview-stage" ref={container}><div className="readme-frame-size" style={{ width: width * scale, height: height * scale }}>
      {error || result?.error ? <p role="alert">{error || result.error}</p> : result ? <iframe title="GitHub README layout preview" sandbox="" srcDoc={result.document} style={{ width, height, transform: `scale(${scale})`, transformOrigin: 'top left' }} /> : <p role="status">Loading native card previews…</p>}
    </div></div>
    <div className="readme-preview-caption"><strong>{mobile ? '375' : '928'} px · {Math.round(scale * 100)}%{fit ? ' fit' : ' actual size'}</strong><span>{userData?.source === 'demo' ? 'Sample data' : userData?.source === 'authenticated' ? 'Authenticated data' : userData?.source === 'public' ? 'Limited public data' : 'Data unavailable'} · Exported HTML with local SVGs</span></div>
    {!!result?.failures?.length && <p className="preview-warning">{result.failures.length} card{result.failures.length > 1 ? 's need' : ' needs'} a data connection. Placeholders are not included in your export.</p>}
    <p className="preview-disclosure">GitHub-style image sizing and wrapping, without editing controls. GitHub’s available width, future styles, and other README content can affect the final layout. Scroll inside the preview to see the full profile.</p>
  </section>
}
