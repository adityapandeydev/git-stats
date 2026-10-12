import { aggregateLanguages } from './githubApi.js'
import { calculateRhythm } from './analytics.js'
import { cardRadius } from '../constants/cards.js'

export function cardRequest(card, themeId, userData) {
  const hidden = (card.hide || '').split(',').map(s => s.trim().toLowerCase()).filter(Boolean)
  const excluded = (card.excludeRepos || '').split(',').map(s => s.trim().toLowerCase()).filter(Boolean)
  const allLanguages = excluded.length && userData.repositories ? aggregateLanguages(userData.repositories.filter(r => !excluded.includes(r.name.toLowerCase()))) : userData.languages
  const languages = card.id === 'languages' ? allLanguages.filter(l => !hidden.includes(l.name.toLowerCase())) : card.id === 'milestones' ? userData.milestoneLanguages || userData.languages : userData.languages
  return {
    card: card.id, theme: themeId, username: userData.login, width: card.width, height: card.height,
    border_radius: cardRadius(card), count: card.langsCount || 12, sparkline: card.sparkline !== false, timeframe: card.timeframe || 'all-time', languages,
    metrics: card.id === 'milestones' ? userData.milestoneMetrics || userData.metrics : card.timeframe === 'this-year' ? userData.yearMetrics : userData.metrics,
    streak: userData.streak, rhythm: card.id === 'rhythm' ? calculateRhythm(userData.login, userData.commits, card.timezone ?? 5.5) : userData.rhythm, velocity: userData.velocity,
  }
}
