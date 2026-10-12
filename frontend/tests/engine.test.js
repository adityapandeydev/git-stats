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

test('streak keeps complete ranges on one line and handles inactive accounts', () => {
  const svg = render('streak')
  assert.doesNotMatch(svg, /<tspan/)
  assert.match(svg, /Oct 16, 2025 – Oct 11, 2026/)
  assert.match(render('streak', { streak: { ...DEMO_DATA.streak, current_streak: 0 } }), /No active streak/)
})
test('every card respects the default, custom, and square corner radius', () => {
  for (const card of ['languages', 'streak', 'stats', 'rhythm', 'radar', 'velocity', 'milestones']) {
    for (const radius of [4.5, 0, 16]) {
      const svg = render(card, { border_radius: radius })
      assert.match(svg, new RegExp(`<rect[^>]*rx="${radius.toFixed(1)}"`), `${card}: ${radius}`)
    }
  }
})
test('large streak counts and compact dimensions remain finite', () => {
  const streak = { ...DEMO_DATA.streak, current_streak: 4294967295, longest_streak: 4294967295 }
  const svg = render('streak', { streak, width: 300, height: 124 })
  assert.doesNotMatch(svg, /NaN|Infinity/)
  assert.match(svg, /4294967295/)
})

test('redesigned cards fit compact and hero sizes with large metrics', () => {
  const metrics = Object.fromEntries(Object.keys(DEMO_DATA.metrics).map(key => [key, 1e12]))
  for (const card of ['stats', 'rhythm', 'radar', 'velocity', 'milestones']) {
    for (const [width, height] of [[300, 124], [424, 180], [840, 180], [424, 360]]) {
      const svg = render(card, { width, height, metrics })
      assert.doesNotMatch(svg, /NaN|Infinity|\p{Extended_Pictographic}/u)
      assert.match(svg, new RegExp(`viewBox="0 0 ${width} ${height}"`))
    }
  }
})

test('empty rhythm and PR data retain honest zero states', () => {
  const rhythm = { ...DEMO_DATA.rhythm, total_commits: 0, day_commits: 0, night_commits: 0, matrix: Array.from({ length: 7 }, () => Array(24).fill(0)) }
  const svg = render('rhythm', { rhythm })
  assert.match(svg, /No activity yet/)
  assert.match(svg, /0% day/)
  assert.match(svg, /0% night/)
  assert.doesNotMatch(svg, /100% night|NaN/)
  assert.equal((svg.match(/height="7.10"/g) || []).length, 168)
  const velocity = { ...DEMO_DATA.velocity, total_prs: 0, merged_prs: 0, open_prs: 0, closed_prs: 0, merge_rate: 0, velocity_score: 0 }
  const empty = render('velocity', { velocity })
  assert.match(empty, /No pull requests/)
  assert.doesNotMatch(empty, /Hypersonic Shipper|18.5h|NaN/)
})

test('wide milestones use six tiles; the compact layout preserves all six values', () => {
  for (const width of [424, 840]) {
    const svg = render('milestones', { width })
    for (const value of ['69 Days', '16 Stacks', '3.1k Contribs', '64 Merged', '32 Repos', '520 Stars']) assert.ok(svg.includes(value))
    assert.equal((svg.match(/viewBox="0 0 24 24"/g) || []).length, 6)
  }
})

test('rhythm percentage labels sum to 100 for complementary day/night activity', () => {
  const rhythm = { ...DEMO_DATA.rhythm, total_commits: 200, day_commits: 123, night_commits: 77 }
  const svg = render('rhythm', { rhythm })
  assert.match(svg, /61% day/)
  assert.match(svg, /39% night/)
})
