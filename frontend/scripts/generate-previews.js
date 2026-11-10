// Offline documentation samples. Never writes live generated/ cards or bento artifacts.
import { readFileSync, writeFileSync } from 'node:fs'
import { DEMO_DATA } from '../src/services/demo.js'
import { DEFAULT_CONFIG, normalizeConfig } from '../src/services/profileConfig.js'
import { cardRequest } from '../src/services/cardRequest.js'
import { renderNative } from '../src/services/engine.js'
const { instance } = await WebAssembly.instantiate(readFileSync(new URL('../public/engine.wasm', import.meta.url)), {})
const configFor = (id, options = {}) => normalizeConfig({ ...DEFAULT_CONFIG, layout: [{ type: 'pair', cards: [id, null] }], options: { ...DEFAULT_CONFIG.options, timezone: 5.5, ...options } })
for (const id of ['streak', 'stats', 'rhythm', 'radar', 'velocity', 'milestones']) {
  writeFileSync(new URL(`../../preview/${id}/standard.svg`, import.meta.url), renderNative(instance.exports, cardRequest(id, configFor(id), DEMO_DATA)))
  if (id === 'streak') writeFileSync(new URL('../../preview/streak/minimal.svg', import.meta.url), renderNative(instance.exports, cardRequest(id, configFor(id, { sparkline: false }), DEMO_DATA)))
}
console.log('Updated seven documentation previews using labelled sample data.')
