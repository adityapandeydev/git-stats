// Shared by Studio (browser) and the GitHub Action (Node, action/run.mjs).
// Keep it dependency-free ESM: the action imports this file directly.
import { THEMES } from '../constants/themes.js'

export const ENGINE_REPO = 'adityapandeydev/git-stats'
// Tag or branch of this repository that exported workflows run.
export const ACTION_REF = 'main'
export const OUTPUT_DIR = 'gitstats'
export const WORKFLOW_PATH = '.github/workflows/gitstats.yml'
export const MARKER_START = '<!-- gitstats:start -->'
export const MARKER_END = '<!-- gitstats:end -->'

export const THEME_IDS = THEMES.map(theme => theme.id)

export const CARDS = [
  { id: 'streak', name: 'Contribution streak', flag: '--streak', blurb: 'Current and longest streak, with 14 days of activity.', wide: true },
  { id: 'stats', name: 'Developer stats', flag: '--stats', blurb: 'Score out of 1000, how it is made, and headline totals.' },
  { id: 'languages', name: 'Top languages', flag: '--generate', blurb: 'Your most used languages by code size.', tall: true },
  { id: 'radar', name: 'Developer DNA', flag: '--radar', blurb: 'How your code splits across five domains.' },
  { id: 'rhythm', name: 'Commit rhythm', flag: '--rhythm', blurb: 'When you commit, by weekday and hour.', wide: true },
  { id: 'velocity', name: 'Pull requests', flag: '--velocity', blurb: 'Merge time, merge rate and size of recent work.' },
  { id: 'milestones', name: 'Milestones', flag: '--milestones', blurb: 'Six achievements with progress to the next tier.', wide: true },
]
export const cardById = id => CARDS.find(card => card.id === id)

// Row types. Slot rules keep every layout tidy on GitHub:
// - "pair": two standard cards side by side
// - "wide": one full-width card (streak, rhythm or milestones)
// - "stack": two standard cards stacked beside the tall languages card
export const ROW_TYPES = {
  pair: { label: 'Two cards', slots: 2 },
  wide: { label: 'Full width', slots: 1 },
  stack: { label: 'Stacked + languages', slots: 3 },
}

/** Which cards may go in a slot. */
export function slotAccepts(type, slot, id) {
  const card = cardById(id)
  if (!card) return false
  if (type === 'stack' && slot === 2) return id === 'languages'
  if (id === 'languages') return false
  if (type === 'wide') return Boolean(card.wide)
  return true
}

export const DEFAULT_OPTIONS = {
  languagesCount: 12,
  hideLanguages: '',
  excludeRepos: '',
  timezone: 0,
  timeframe: 'all-time',
  sparkline: true,
}

export const DEFAULT_CONFIG = {
  version: 1,
  theme: 'tokyonight',
  radius: 4.5,
  layout: [
    { type: 'stack', cards: ['streak', 'stats', 'languages'] },
    { type: 'pair', cards: ['radar', 'rhythm'] },
    { type: 'wide', cards: ['milestones'] },
  ],
  options: DEFAULT_OPTIONS,
}

const clamp = (value, min, max, fallback) => {
  const n = Number(value)
  return Number.isFinite(n) ? Math.min(max, Math.max(min, n)) : fallback
}
const singleLine = value => {
  const text = typeof value === 'string' ? value.trim() : ''
  // GitHub evaluates ${{ }} inside workflow inputs; never let it reach the YAML.
  if (/[\r\n]/.test(text) || text.includes('${{')) throw new Error('Filters must be a single comma-separated line.')
  return text
}

/** Validate and fill a config. Throws an Error with a readable message. */
export function normalizeConfig(input = {}) {
  const theme = THEME_IDS.includes(input.theme) ? input.theme : DEFAULT_CONFIG.theme
  const radius = clamp(input.radius, 0, 24, DEFAULT_CONFIG.radius)
  const seen = new Set()
  const layout = (Array.isArray(input.layout) ? input.layout : []).flatMap(row => {
    const type = ROW_TYPES[row?.type] ? row.type : null
    if (!type) return []
    const cards = Array.from({ length: ROW_TYPES[type].slots }, (_, slot) => {
      const id = row.cards?.[slot]
      if (!id || seen.has(id) || !slotAccepts(type, slot, id)) return null
      seen.add(id)
      return id
    })
    return [{ type, cards }]
  })
  const o = { ...DEFAULT_OPTIONS, ...(input.options || {}) }
  const options = {
    languagesCount: Math.round(clamp(o.languagesCount, 6, 16, 12)),
    hideLanguages: singleLine(o.hideLanguages),
    excludeRepos: singleLine(o.excludeRepos),
    timezone: clamp(o.timezone, -12, 14, 0),
    timeframe: o.timeframe === 'this-year' ? 'this-year' : 'all-time',
    sparkline: o.sparkline !== false,
  }
  return { version: 1, theme, radius, layout, options }
}

/** Card ids in reading order. */
export const placedCards = config => config.layout.flatMap(row => row.cards.filter(Boolean))

// Natural card sizes. In a stack row the languages card is stretched so that,
// at 48% width, it is as tall as two 424 × 180 cards at 50% width.
export function languagesMinHeight(count) {
  return 124 + (Math.ceil(count / 2) - 1) * 34
}
export function cardSize(id, config) {
  const row = config.layout.find(r => r.cards.includes(id))
  if (id === 'languages') {
    const min = languagesMinHeight(config.options.languagesCount)
    return { width: 400, height: row?.type === 'stack' ? Math.max(min, 356) : min }
  }
  return { width: row?.type === 'wide' ? 840 : 424, height: 180 }
}

/** Native CLI arguments for one card (no shell quoting; pass as an argv array). */
export function cardArgs(id, config, { username, output }) {
  const card = cardById(id)
  const { width, height } = cardSize(id, config)
  const o = config.options
  const args = [card.flag, `--username=${username}`, `--theme=${config.theme}`, `--card-width=${width}`, `--card-height=${height}`, `--border-radius=${config.radius}`, '--animate=false', '--svg-icons', '--strict-data']
  if (id === 'languages') args.push(`--langs-count=${o.languagesCount}`, '--layout=standard', '--columns=2')
  if (id === 'languages' || id === 'radar') {
    if (o.hideLanguages) args.push(`--hide=${o.hideLanguages}`)
    if (o.excludeRepos) args.push(`--exclude-repo=${o.excludeRepos}`)
  }
  if (id === 'streak') args.push(`--show-sparkline=${o.sparkline}`)
  if (id === 'stats') args.push(`--timeframe=${o.timeframe}`)
  if (id === 'rhythm') args.push(`--tz=${o.timezone}`)
  args.push(`--output=${output}`)
  return args
}

const escapeAttr = value => String(value).replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll('<', '&lt;')

/**
 * README markup. GitHub strips CSS, so layout comes from HTML attributes only.
 * Percentage widths can't add up past 100%, so rows never wrap at any width.
 */
export function compileReadme(config, src = id => `${OUTPUT_DIR}/${id}.svg`) {
  const img = (id, width, extra = '') => `  <img src="${escapeAttr(src(id))}" width="${width}" alt="${escapeAttr(cardById(id).name)}"${extra} />`
  const blocks = []
  for (const row of config.layout) {
    const lines = []
    if (row.type === 'wide' && row.cards[0]) lines.push(img(row.cards[0], '100%'))
    if (row.type === 'pair') for (const id of row.cards.filter(Boolean)) lines.push(img(id, '49%'))
    if (row.type === 'stack') {
      const [top, bottom, tall] = row.cards
      if (tall) lines.push(img(tall, '48%', ' align="right"'))
      if (top) lines.push(img(top, '50%'))
      if (top && bottom) lines.push('  <br/>')
      if (bottom) lines.push(img(bottom, '50%'))
    }
    if (lines.length) blocks.push(['<p align="center">', ...lines, '</p>'].join('\n'))
  }
  return blocks.join('\n')
}

/** Replace the marked section of a README, or append one. */
export function updateReadmeSection(readme, markup) {
  const block = `${MARKER_START}\n${markup}\n${MARKER_END}`
  const start = readme.indexOf(MARKER_START), end = readme.indexOf(MARKER_END)
  if (start >= 0 && end > start) return readme.slice(0, start) + block + readme.slice(end + MARKER_END.length)
  return `${readme.replace(/\s*$/, '')}${readme.trim() ? '\n\n' : ''}${block}\n`
}

/** The workflow users commit to their username/username repository. */
export function compileWorkflow(config) {
  const json = JSON.stringify(config, null, 2).split('\n').map(line => `            ${line}`).join('\n')
  return `name: GitStats

on:
  schedule:
    - cron: '0 */4 * * *'
  workflow_dispatch:
  push:
    paths: ['${WORKFLOW_PATH}']

permissions:
  contents: write

concurrency:
  group: gitstats
  cancel-in-progress: false

jobs:
  cards:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ${ENGINE_REPO}@${ACTION_REF}
        with:
          # Optional: add a GH_TOKEN secret to include private contributions.
          token: \${{ secrets.GH_TOKEN }}
          config: |
${json}
`
}

/** "UTC+5:30", "UTC−3", "UTC". Matches the rhythm card header. */
export function formatOffset(hours) {
  if (!hours) return 'UTC'
  const total = Math.round(Math.abs(hours) * 60), sign = hours < 0 ? '−' : '+'
  return `UTC${sign}${Math.floor(total / 60)}${total % 60 ? `:${String(total % 60).padStart(2, '0')}` : ''}`
}

export const validUsername = name => /^[a-z\d](?:[a-z\d-]{0,37}[a-z\d])?$/i.test(String(name || '').trim())

/** GitHub URLs for publishing. GitHub pre-fills new files from filename and value. */
export function publishLinks(username, yaml) {
  const repo = `https://github.com/${username}/${username}`
  return {
    repo,
    createRepo: `https://github.com/new?name=${encodeURIComponent(username)}&visibility=public`,
    newWorkflow: `${repo}/new/HEAD?filename=${encodeURIComponent(WORKFLOW_PATH)}&value=${encodeURIComponent(yaml)}`,
    editWorkflow: `${repo}/edit/HEAD/${WORKFLOW_PATH}`,
    actions: `${repo}/actions`,
    secrets: `${repo}/settings/secrets/actions/new`,
    rawCard: id => `https://raw.githubusercontent.com/${username}/${username}/HEAD/${OUTPUT_DIR}/${id}.svg`,
  }
}
