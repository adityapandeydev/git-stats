import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { profilePreview } from '../src/services/profilePreview.js'
import { generateProfileHtml } from '../src/services/compiler.js'
import { DEMO_DATA } from '../src/services/demo.js'
import { createCard } from '../src/constants/cards.js'
const { instance } = await WebAssembly.instantiate(readFileSync(new URL('../public/engine.wasm', import.meta.url)), {})
const base = { engine: instance.exports, username: 'octocat', themeId: 'tokyonight', userData: DEMO_DATA, target: {}, layoutMode: 'pillar-right' }

test('final preview preserves exported HTML ordering, widths, alignment and breaks', () => {
  for (const layoutMode of ['pillar-right', 'flow']) {
    const cards = [createCard('milestones'), createCard('streak'), createCard('stats'), createCard('languages')]
    const { document, failures } = profilePreview({ ...base, cards, layoutMode })
    assert.deepEqual(failures, [])
    const markup = document.match(/<article class="markdown-body">([\s\S]*)<\/article>/)[1]
    const stripSources = html => html.replace(/src="[^"]*"/g, 'src="LOCAL"')
    assert.equal(stripSources(markup), stripSources(generateProfileHtml('octocat', cards, layoutMode)))
    assert.doesNotMatch(document, /raw\.githubusercontent\.com|canvas-card-tools|<script|Authorization/)
    assert.match(document, /default-src 'none'/)
  }
})
test('limited and missing data produce honest preview-only placeholders', () => {
  const cards = [createCard('streak'), createCard('languages')]
  const data = { ...DEMO_DATA, source: 'public', available: ['languages'] }
  const result = profilePreview({ ...base, cards, userData: data })
  assert.deepEqual(result.failures, ['streak'])
  assert.ok([...result.document.matchAll(/src="data:image\/svg\+xml;charset=utf-8,([^"]*)"/g)].some(match => decodeURIComponent(match[1]).includes('Connect GitHub to preview this card')))
  assert.doesNotMatch(generateProfileHtml('octocat', cards), /data:|Connect GitHub/)
  assert.deepEqual(profilePreview({ ...base, cards, userData: null }).failures.sort(), ['languages', 'streak'])
})
test('light backgrounds and empty compositions remain usable', () => {
  const { document } = profilePreview({ ...base, cards: [], light: true })
  assert.match(document, /color-scheme:light/)
  assert.match(document, /<div align="center">\n<\/div>/)
})
