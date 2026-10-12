import { useEffect, useMemo, useState } from 'react'
import { LockKeyhole, AlertCircle, LoaderCircle } from 'lucide-react'
import { loadEngine, renderNative } from '../../services/engine'
import { cardRadius } from '../../constants/cards'
import { cardRequest } from '../../services/cardRequest'

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
      const svg = renderNative(engine, cardRequest(card, themeId, userData))
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
