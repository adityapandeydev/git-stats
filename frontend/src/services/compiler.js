import { getCardDef } from '../constants/cards.js'
import { THEMES } from '../constants/themes.js'

export function validateTarget(username, target = {}) {
  const user = username.trim()
  const owner = (target.owner || user).trim()
  const repo = (target.repo || 'git-stats').trim()
  const branch = (target.branch || 'main').trim()
  if (!/^[a-z\d](?:[a-z\d-]{0,37}[a-z\d])?$/i.test(user)) throw new Error('Enter a valid GitHub username.')
  if (!/^[a-z\d](?:[a-z\d-]{0,37}[a-z\d])?$/i.test(owner)) throw new Error('Enter a valid repository owner.')
  if (!/^[\w.-]+$/.test(repo) || repo === '.' || repo === '..') throw new Error('Enter a valid repository name.')
  if (!branch || /[\s~^:?*\[\\]|\.\.|@\{|\/\/|^[/.]|[/.]$/.test(branch)) throw new Error('Enter a valid branch name.')
  return { username: user, owner, repo, branch }
}

// Canvas and README share row packing. Heroes precede the pinned columns.
export function layoutCards(cards, mode = 'pillar-right') {
  const languages = mode === 'pillar-right' ? cards.find(c => c.id === 'languages') : null
  const heroes = languages ? cards.filter(c => c.width >= 700) : []
  const body = cards.filter(c => c !== languages && !heroes.includes(c))
  if (languages && body.length) return { heroes, pillar: languages, rows: body.map(c => [c]) }
  const rows = []
  let row = []
  let width = 0
  for (const card of languages ? cards.filter(c => !heroes.includes(c)) : cards) {
    if (row.length && (width + 12 + card.width > 860 || card.width >= 700)) {
      rows.push(row); row = []; width = 0
    }
    row.push(card); width += (row.length > 1 ? 12 : 0) + card.width
    if (card.width >= 700) { rows.push(row); row = []; width = 0 }
  }
  if (row.length) rows.push(row)
  return { heroes, pillar: null, rows }
}

const escapeHtml = value => value.replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll('<', '&lt;')
const quote = value => `'${String(value).replaceAll("'", "'\\''")}'`

export function generateProfileHtml(username, cards, mode = 'pillar-right', target = {}) {
  const { owner, repo, branch } = validateTarget(username, target)
  const base = `https://raw.githubusercontent.com/${owner}/${repo}/${branch.split('/').map(encodeURIComponent).join('/')}/generated`
  const image = (c, align = '') => `  <img${align} src="${escapeHtml(base)}/${c.id}.svg" width="${c.width}" alt="${getCardDef(c.id).name}" />`
  const layout = layoutCards(cards, mode)
  const lines = ['<div align="center">']
  for (const c of layout.heroes) lines.push(image(c), '  <br/>')
  if (layout.pillar) lines.push(image(layout.pillar, ' align="right"'))
  layout.rows.forEach((row, i) => {
    lines.push(...row.map(c => image(c)))
    if (i < layout.rows.length - 1) lines.push('  <br/>')
  })
  lines.push('</div>')
  return lines.join('\n')
}

export function generateWorkflowYaml(username, cards, theme = 'tokyonight', hideLangs = '', target = {}) {
  const destination = validateTarget(username, target)
  if (!cards.length) throw new Error('Add at least one card before exporting.')
  if (!THEMES.some(t => t.id === theme)) throw new Error('Select a supported theme.')
  const commands = cards.map(card => {
    const def = getCardDef(card.id)
    if (!def || !Number.isInteger(card.width) || !Number.isInteger(card.height) || card.width < 300 || card.width > 1200 || card.height < 124 || card.height > 1500) throw new Error('Invalid card dimensions.')
    const args = [def.flag, `--username=${quote(destination.username)}`, `--theme=${quote(theme)}`, `--card-width=${card.width}`, `--card-height=${card.height}`, '--border-radius=4.5', '--svg-icons', '--strict-data']
    if (card.id === 'languages') {
      args.push(`--langs-count=${Math.min(16, Math.max(6, card.langsCount || 12))}`, '--layout=standard', '--columns=2')
      if (card.hide || hideLangs) args.push(`--hide=${quote(card.hide || hideLangs)}`)
      if (card.excludeRepos) args.push(`--exclude-repo=${quote(card.excludeRepos)}`)
    }
    if (card.id === 'streak') args.push(`--show-sparkline=${card.sparkline !== false}`)
    if (card.id === 'stats') args.push(`--timeframe=${quote(card.timeframe === 'this-year' ? 'this-year' : 'all-time')}`)
    if (card.id === 'rhythm') args.push(`--tz=${Number.isFinite(Number(card.timezone)) ? Math.min(14, Math.max(-12, Number(card.timezone))) : 5.5}`)
    args.push(`--output=${quote(`generated/${card.id}.svg`)}`)
    return `          ./zig-out/bin/git_stats ${args.join(' \\\n            ')}`
  }).join('\n\n')
  const files = cards.map(c => quote(`generated/${c.id}.svg`)).join(' ')
  return `name: Generate GitStats Profile Cards

on:
  schedule:
    - cron: '0 */4 * * *'
  workflow_dispatch:
  push:
    branches: [${JSON.stringify(destination.branch)}]
    paths: ['.github/workflows/generate-stats.yml']

permissions:
  contents: write

concurrency:
  group: gitstats-generation
  cancel-in-progress: false

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${JSON.stringify(destination.branch)}
      - uses: mlugg/setup-zig@v2
        with:
          version: "0.16.0"
      - name: Build and generate cards
        env:
          GH_TOKEN: \${{ secrets.GH_TOKEN || github.token }}
        run: |
          zig build -Doptimize=ReleaseFast
          mkdir -p generated

${commands}

      - name: Commit updated cards
        run: |
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git config user.name "github-actions[bot]"
          git add -f -- ${files}
          if ! git diff --staged --quiet; then
            git commit -m "chore(stats): update profile cards [skip ci]"
            git push
          fi
`
}

export function getGitHubWebEditUrl(username, target = {}, exists = true) {
  const { owner, repo, branch } = validateTarget(username, target)
  const base = `https://github.com/${owner}/${repo}`
  const ref = encodeURIComponent(branch)
  return exists ? `${base}/edit/${ref}/.github/workflows/generate-stats.yml` : `${base}/new/${ref}?filename=.github%2Fworkflows%2Fgenerate-stats.yml`
}
