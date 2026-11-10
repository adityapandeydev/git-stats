import { aggregateLanguages } from './githubApi.js'
import { calculateRhythm } from './analytics.js'
import { cardSize } from './profileConfig.js'

const list = value => (value || '').split(',').map(s => s.trim().toLowerCase()).filter(Boolean)

// Same filters as the exported workflow: hidden languages and excluded
// repositories apply to both the languages card and Developer DNA.
export function visibleLanguages(userData, options) {
  const excluded = list(options.excludeRepos), hidden = list(options.hideLanguages)
  const base = excluded.length && userData.repositories ? aggregateLanguages(userData.repositories.filter(r => !excluded.includes(r.name.toLowerCase()))) : userData.languages
  return base.filter(l => !hidden.includes(l.name.toLowerCase()))
}

/** Request for the browser engine (src/studio.zig) for one card of a config. */
export function cardRequest(id, config, userData) {
  const { width, height } = cardSize(id, config)
  const o = config.options
  const languages = id === 'languages' || id === 'radar' ? visibleLanguages(userData, o) : id === 'milestones' ? userData.milestoneLanguages || userData.languages : userData.languages
  return {
    card: id, theme: config.theme, username: userData.login, width, height,
    border_radius: config.radius, count: o.languagesCount, sparkline: o.sparkline, timeframe: o.timeframe, timezone: o.timezone, languages,
    metrics: id === 'milestones' ? userData.milestoneMetrics || userData.metrics : o.timeframe === 'this-year' ? userData.yearMetrics || userData.metrics : userData.metrics,
    streak: userData.streak, rhythm: id === 'rhythm' ? calculateRhythm(userData.login, userData.commits, o.timezone) : userData.rhythm, velocity: userData.velocity,
  }
}
