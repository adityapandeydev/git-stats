import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { DEMO_DATA } from '../src/services/demo.js'
const { instance } = await WebAssembly.instantiate(readFileSync(new URL('../public/engine.wasm', import.meta.url)), {})
const engine = instance.exports
const encoder = new TextEncoder(), decoder = new TextDecoder()
function render(card, overrides = {}) {
  const request = { card, username: 'demo', languages: DEMO_DATA.languages, metrics: DEMO_DATA.metrics, streak: DEMO_DATA.streak, rhythm: DEMO_DATA.rhythm, velocity: DEMO_DATA.velocity, ...overrides }
  const bytes = encoder.encode(JSON.stringify(request)), pointer = engine.studio_alloc(bytes.length)
  try {
    new Uint8Array(engine.memory.buffer, pointer, bytes.length).set(bytes)
    const output = engine.studio_render(pointer, bytes.length)
    assert.ok(output, `Failed to render ${card}`)
    return decoder.decode(new Uint8Array(engine.memory.buffer, output, engine.studio_output_len()))
  } finally { engine.studio_free(pointer, bytes.length) }
}
test('all seven native cards render without host imports or emoji', () => {
  assert.deepEqual(WebAssembly.Module.imports(new WebAssembly.Module(readFileSync(new URL('../public/engine.wasm', import.meta.url)))), [])
  for (const card of ['languages', 'streak', 'stats', 'rhythm', 'radar', 'velocity', 'milestones']) {
    const svg = render(card)
    assert.match(svg, /<svg/)
    assert.doesNotMatch(svg, /NaN|Infinity|\p{Extended_Pictographic}/u)
  }
})
test('language minimum height follows actual available languages for counts 6–16', () => {
  for (let count = 6; count <= 16; count++) {
    const svg = render('languages', { width: 400, height: 124, count })
    assert.match(svg, new RegExp(`height="${124 + (Math.ceil(count / 2) - 1) * 34}"`))
  }
  const svg = render('languages', { width: 400, height: 124, count: 16, languages: DEMO_DATA.languages.slice(0, 2) })
  assert.match(svg, /height="124"/)
  assert.doesNotMatch(svg, /Go|Python/)
})
test('zero languages and zero contribution values do not fabricate data', () => {
  const svg = render('languages', { languages: [] })
  assert.doesNotMatch(svg, /Rust|Python|NaN/)
  const streak = { ...DEMO_DATA.streak, current_streak: 0, longest_streak: 0, total_contributions: 0, recent_14_days: Array(14).fill(0), max_14_day_count: 0, total_14_day_count: 0 }
  assert.doesNotMatch(render('streak', { streak }), /NaN|Infinity/)
})
test('sparkline and theme settings reach the native renderer', () => {
  assert.match(render('stats', { theme: 'nord' }), /#2e3440/)
  assert.doesNotMatch(render('streak', { sparkline: false }), /14-DAY MOMENTUM/)
})
