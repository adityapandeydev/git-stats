import { useEffect, useMemo, useState } from 'react'
import { Info } from 'lucide-react'
import { CARDS, DEFAULT_CONFIG, normalizeConfig } from '../services/profileConfig'
import { loadEngine } from '../services/engine'
import { renderCard } from '../services/profilePreview'
import { DEMO_DATA } from '../services/demo'

export const Section = ({ title, children }) => <section className="reveal">{title && <h2>{title}</h2>}{children}</section>
export const Callout = ({ children }) => <div className="callout"><Info size={18} /><p>{children}</p></div>

export function CardGallery() {
  const [engine, setEngine] = useState(null)
  useEffect(() => { let live = true; loadEngine().then(e => live && setEngine(e)).catch(() => {}); return () => { live = false } }, [])
  const config = useMemo(() => normalizeConfig({ ...DEFAULT_CONFIG, layout: [], options: { ...DEFAULT_CONFIG.options, timezone: 5.5 } }), [])
  return <div className="card-gallery">
    {CARDS.map(card => <figure key={card.id} className="reveal">
      {engine ? <img src={`data:image/svg+xml;charset=utf-8,${encodeURIComponent(renderCard(engine, card.id, config, DEMO_DATA).svg)}`} alt={`${card.name} example`} /> : <div className="card-loading" />}
      <figcaption><strong>{card.name}</strong><span>{card.blurb}</span></figcaption>
    </figure>)}
  </div>
}
