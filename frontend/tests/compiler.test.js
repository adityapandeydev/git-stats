import { test } from 'node:test'
import assert from 'node:assert/strict'
import { generateProfileHtml, generateWorkflowYaml, layoutCards, validateTarget, getGitHubWebEditUrl } from '../src/services/compiler.js'

const card = (id, width = 424, extra = {}) => ({ id, width, height: 180, ...extra })
test('workflow preserves profile, destination, order and card options', () => {
  const cards = [card('streak', 424, { sparkline: false }), card('rhythm', 424, { timezone: -3.5 }), card('languages', 400, { langsCount: 7, height: 226, hide: "HTML,O'Reilly" })]
  const yaml = generateWorkflowYaml('octocat', cards, 'nord', '', { owner: 'another-owner', repo: 'my-stats', branch: 'profile/cards' })
  assert.match(yaml, /--username='octocat'/)
  assert.match(yaml, /--show-sparkline=false/)
  assert.match(yaml, /--tz=-3.5/)
  assert.match(yaml, /--langs-count=7/)
  assert.match(yaml, /--animate=false/)
  assert.match(yaml, /secrets.GH_TOKEN \|\| github.token/)
  assert.match(yaml, /ref: "profile\/cards"/)
  assert.ok(yaml.indexOf('--streak') < yaml.indexOf('--rhythm'))
  assert.doesNotMatch(yaml, /git add -A|git add \./)
})
test('flow packs pairs and isolates heroes consistently', () => {
  const cards = [card('streak'), card('stats'), card('milestones', 840), card('radar'), card('velocity')]
  assert.deepEqual(layoutCards(cards, 'flow').rows.map(r => r.map(c => c.id)), [['streak', 'stats'], ['milestones'], ['radar', 'velocity']])
  assert.equal((generateProfileHtml('octocat', cards, 'flow').match(/<br\/>/g) || []).length, 2)
})
test('pillar moves heroes above columns and keeps language pinned', () => {
  const layout = layoutCards([card('milestones', 840), card('streak'), card('languages', 400), card('stats')])
  assert.equal(layout.heroes[0].id, 'milestones')
  assert.equal(layout.pillar.id, 'languages')
  assert.deepEqual(layout.rows.map(r => r[0].id), ['streak', 'stats'])
})
test('unsafe targets and empty workflows are rejected', () => {
  assert.throws(() => validateTarget('$(whoami)'))
  assert.throws(() => validateTarget('octocat', { branch: '../main' }))
  assert.throws(() => generateWorkflowYaml('octocat', []))
  assert.throws(() => generateWorkflowYaml('octocat', [card('languages', 400, { hide: '${{ secrets.GH_TOKEN }}' })]))
  assert.match(getGitHubWebEditUrl('octocat', {}, false), /\/new\/main\?filename=/)
})

test('workflow exports per-card radius and preserves legacy defaults', () => {
  const yaml = generateWorkflowYaml('octocat', [card('streak', 424, { borderRadius: 0 }), card('stats', 424, { borderRadius: 16 }), card('radar')])
  assert.match(yaml, /--border-radius=0 /)
  assert.match(yaml, /--border-radius=16 /)
  assert.match(yaml, /--border-radius=4.5 /)
})
