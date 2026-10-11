import { useEffect, useMemo, useState } from 'react'
import { LockKeyhole, AlertCircle, LoaderCircle } from 'lucide-react'
import { loadEngine, renderNative } from '../../services/engine'
import { aggregateLanguages } from '../../services/githubApi'
import { cardRadius } from '../../constants/cards'
import { calculateRhythm } from '../../services/analytics'

export default function CardRenderer({ card, themeId, userData }) {
  const [engine, setEngine] = useState(null)
  const [error, setError] = useState('')
  const [imageUrl, setImageUrl] = useState('')
  useEffect(() => {
    let live = true
    loadEngine().then(value => { if (live) setEngine(value) }).catch(e => { if (live) setError(e.message) })
    return () => { live = false }
  }, [])
  const available = userData?.available.includes(card.id)
  const result = useMemo(() => {
    if (!engine || !userData || !available) return null
    try {
      const hidden = (card.hide || '').split(',').map(s => s.trim().toLowerCase()).filter(Boolean)
      const excluded = (card.excludeRepos || '').split(',').map(s => s.trim().toLowerCase()).filter(Boolean)
      const allLanguages = excluded.length && userData.repositories ? aggregateLanguages(userData.repositories.filter(r => !excluded.includes(r.name.toLowerCase()))) : userData.languages
      const languages = card.id === 'languages' ? allLanguages.filter(l => !hidden.includes(l.name.toLowerCase())) : card.id === 'milestones' ? userData.milestoneLanguages || userData.languages : userData.languages
      const svg = renderNative(engine, {
        card: card.id, theme: themeId, username: userData.login, width: card.width, height: card.height,
        border_radius: cardRadius(card), count: card.langsCount || 12, sparkline: card.sparkline !== false, timeframe: card.timeframe || 'all-time', languages,
        metrics: card.id === 'milestones' ? userData.milestoneMetrics || userData.metrics : card.timeframe === 'this-year' ? userData.yearMetrics : userData.metrics,
        streak: userData.streak, rhythm: card.id === 'rhythm' ? calculateRhythm(userData.login, userData.commits, card.timezone ?? 5.5) : userData.rhythm, velocity: userData.velocity,
      })
      return { svg }
    } catch (e) { return { error: e.message } }
  }, [engine, card, themeId, userData, available])
  useEffect(() => {
    if (!result?.svg) return
    const url = URL.createObjectURL(new Blob([result.svg], { type: 'image/svg+xml' }))
    // Blob URLs are external resources: create and revoke them with the effect lifecycle.
    // oxlint-disable-next-line react/set-state-in-effect
    setImageUrl(url)
    return () => URL.revokeObjectURL(url)
  }, [result])
  if (result?.svg && imageUrl) return <img className="native-card" src={imageUrl} width={card.width} height={card.height} style={{ borderRadius: cardRadius(card) }} alt={`${card.id} profile card`} draggable="false" />
  const message = error || result?.error
  return <div className="card-placeholder" style={{ width: card.width, minHeight: card.height, borderRadius: cardRadius(card) }}>
    {message ? <AlertCircle size={22} /> : !available ? <LockKeyhole size={22} /> : <LoaderCircle size={22} className="spin" />}
    <strong>{message ? 'Preview unavailable' : !userData ? 'Waiting for profile data' : !available ? 'Connect GitHub to preview' : 'Loading native renderer'}</strong>
    <span>{message || (!userData ? 'Profile data has not loaded yet. Your design and export settings are preserved.' : !available ? 'This card needs authenticated contribution data. It will still be included in your export.' : 'The same Zig engine, running in your browser.')}</span>
  </div>
}
