import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { profilePreview } from '../src/services/profilePreview.js'
import { DEFAULT_CONFIG, compileReadme, normalizeConfig } from '../src/services/profileConfig.js'
import { DEMO_DATA } from '../src/services/demo.js'
const { instance } = await WebAssembly.instantiate(readFileSync(new URL('../public/engine.wasm', import.meta.url)), {})
const engine = instance.exports
const config = normalizeConfig(DEFAULT_CONFIG)

test('preview renders exactly the exported README markup with local images', () => {
  const { document, failures } = profilePreview({ engine, config, userData: DEMO_DATA })
  assert.deepEqual(failures, [])
  const markup = document.match(/<article class="markdown-body">([\s\S]*)<\/article>/)[1]
  const strip = html => html.replace(/src="[^"]*"/g, 'src="LOCAL"')
  assert.equal(strip(markup), strip(compileReadme(config)))
  assert.doesNotMatch(document, /raw\.githubusercontent\.com|<script|Authorization/)
  assert.match(document, /default-src 'none'/)
})

test('cards without data become labelled preview-only placeholders', () => {
  const data = { ...DEMO_DATA, source: 'public', available: ['languages', 'radar'] }
  const { document, failures } = profilePreview({ engine, config, userData: data })
  assert.deepEqual(failures.sort(), ['milestones', 'rhythm', 'stats', 'streak'])
  assert.ok([...document.matchAll(/src="data:image\/svg\+xml;charset=utf-8,([^"]*)"/g)].some(m => decodeURIComponent(m[1]).includes('Add a token to preview this card')))
  assert.doesNotMatch(compileReadme(config), /data:|token/)
  assert.equal(profilePreview({ engine, config, userData: null }).failures.length, 6)
})

test('light mode and empty layouts stay usable', () => {
  const empty = normalizeConfig({ ...DEFAULT_CONFIG, layout: [] })
  const { document } = profilePreview({ engine, config: empty, userData: DEMO_DATA, light: true })
  assert.match(document, /color-scheme:light/)
  assert.match(document, /<article class="markdown-body"><\/article>/)
})
