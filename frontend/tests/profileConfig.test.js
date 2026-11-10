import { test } from 'node:test'
import assert from 'node:assert/strict'
import { DEFAULT_CONFIG, MARKER_END, MARKER_START, cardArgs, cardSize, compileReadme, compileWorkflow, languagesMinHeight, normalizeConfig, placedCards, publishLinks, slotAccepts, updateReadmeSection, validUsername } from '../src/services/profileConfig.js'

const config = (layout, options = {}) => normalizeConfig({ ...DEFAULT_CONFIG, layout, options: { ...DEFAULT_CONFIG.options, ...options } })

test('slot rules keep languages in the tall slot and wide rows for wide cards', () => {
  assert.equal(slotAccepts('stack', 2, 'languages'), true)
  assert.equal(slotAccepts('stack', 2, 'stats'), false)
  assert.equal(slotAccepts('pair', 0, 'languages'), false)
  assert.equal(slotAccepts('wide', 0, 'milestones'), true)
  assert.equal(slotAccepts('wide', 0, 'stats'), false)
  assert.equal(slotAccepts('pair', 1, 'nope'), false)
})

test('normalizing drops duplicates, unknown rows and misplaced cards', () => {
  const c = config([{ type: 'pair', cards: ['stats', 'stats'] }, { type: 'grid', cards: ['radar'] }, { type: 'wide', cards: ['velocity'] }, { type: 'stack', cards: ['radar', null, 'languages'] }])
  assert.deepEqual(c.layout, [{ type: 'pair', cards: ['stats', null] }, { type: 'wide', cards: [null] }, { type: 'stack', cards: ['radar', null, 'languages'] }])
  assert.deepEqual(placedCards(c), ['stats', 'radar', 'languages'])
  assert.equal(normalizeConfig({ theme: 'missing' }).theme, 'tokyonight')
  assert.equal(normalizeConfig({ options: { languagesCount: 99, timezone: 40 } }).options.languagesCount, 16)
  assert.equal(normalizeConfig({ options: { timezone: 40 } }).options.timezone, 14)
})

test('filters cannot inject workflow expressions or new lines', () => {
  assert.throws(() => normalizeConfig({ options: { hideLanguages: '${{ secrets.X }}' } }), /single comma-separated line/)
  assert.throws(() => normalizeConfig({ options: { excludeRepos: 'a\nb' } }), /single comma-separated line/)
})

test('README rows use percentage widths so they never wrap', () => {
  const html = compileReadme(config(DEFAULT_CONFIG.layout))
  assert.match(html, /<img src="gitstats\/languages.svg" width="48%" alt="Top languages" align="right" \/>/)
  assert.match(html, /<img src="gitstats\/streak.svg" width="50%"[^>]*\/>\n  <br\/>\n  <img src="gitstats\/stats.svg" width="50%"/)
  assert.match(html, /radar.svg" width="49%"[\s\S]*rhythm.svg" width="49%"/)
  assert.match(html, /milestones.svg" width="100%"/)
  assert.doesNotMatch(html, /width="\d+"/)
  assert.equal(compileReadme(config([{ type: 'pair', cards: [null, null] }])), '')
})

test('languages card in a stack is as tall as the two stacked cards', () => {
  const stacked = cardSize('languages', config(DEFAULT_CONFIG.layout, { languagesCount: 8 }))
  // 48% × height / 400 ≈ 2 × 50% × 180 / 424
  assert.ok(Math.abs(0.48 * stacked.height / 400 - 180 / 424) < 0.01)
  assert.equal(cardSize('languages', config([{ type: 'stack', cards: [null, null, 'languages'] }], { languagesCount: 16 })).height, languagesMinHeight(16))
  assert.equal(cardSize('milestones', config(DEFAULT_CONFIG.layout)).width, 840)
  assert.equal(cardSize('radar', config(DEFAULT_CONFIG.layout)).width, 424)
})

test('README section is replaced in place or appended once', () => {
  const first = updateReadmeSection('# Hello\n\nIntro\n', 'A')
  assert.equal(first, `# Hello\n\nIntro\n\n${MARKER_START}\nA\n${MARKER_END}\n`)
  const second = updateReadmeSection(`${first}\nFooter\n`, 'B')
  assert.equal(second, `# Hello\n\nIntro\n\n${MARKER_START}\nB\n${MARKER_END}\n\nFooter\n`)
  assert.equal(updateReadmeSection('', 'C'), `${MARKER_START}\nC\n${MARKER_END}\n`)
})

test('CLI arguments carry every option to the right card', () => {
  const c = config(DEFAULT_CONFIG.layout, { hideLanguages: 'HTML, CSS', excludeRepos: 'dotfiles', timezone: -3.5, sparkline: false, timeframe: 'this-year', languagesCount: 8 })
  const args = id => cardArgs(id, c, { username: 'octocat', output: `gitstats/${id}.svg` })
  assert.deepEqual(args('languages').slice(0, 2), ['--generate', '--username=octocat'])
  assert.ok(args('languages').includes('--hide=HTML, CSS') && args('languages').includes('--langs-count=8'))
  assert.ok(args('radar').includes('--hide=HTML, CSS') && args('radar').includes('--exclude-repo=dotfiles'))
  assert.ok(!args('stats').some(a => a.startsWith('--hide')))
  assert.ok(args('rhythm').includes('--tz=-3.5'))
  assert.ok(args('streak').includes('--show-sparkline=false'))
  assert.ok(args('stats').includes('--timeframe=this-year'))
  assert.ok(args('milestones').includes('--card-width=840'))
  assert.equal(args('stats').at(-1), '--output=gitstats/stats.svg')
})

test('workflow embeds the config and only references the GH_TOKEN secret', () => {
  const c = config(DEFAULT_CONFIG.layout)
  const yaml = compileWorkflow(c)
  assert.match(yaml, /uses: adityapandeydev\/git-stats@/)
  assert.match(yaml, /permissions:\n {2}contents: write/)
  assert.match(yaml, /token: \$\{\{ secrets.GH_TOKEN \}\}/)
  assert.equal((yaml.match(/\$\{\{/g) || []).length, 1)
  const json = yaml.slice(yaml.indexOf('config: |') + 'config: |'.length)
  assert.deepEqual(JSON.parse(json), c)
})

test('usernames are validated and publish links are pre-filled', () => {
  assert.ok(validUsername('octo-cat'))
  assert.ok(!validUsername('-bad') && !validUsername('a'.repeat(40)) && !validUsername('a/b'))
  const links = publishLinks('octocat', 'name: x')
  assert.equal(links.repo, 'https://github.com/octocat/octocat')
  assert.match(links.newWorkflow, /\/octocat\/octocat\/new\/HEAD\?filename=\.github%2Fworkflows%2Fgitstats\.yml&value=name%3A%20x$/)
  assert.equal(links.rawCard('stats'), 'https://raw.githubusercontent.com/octocat/octocat/HEAD/gitstats/stats.svg')
})
