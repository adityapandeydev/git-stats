// Offline documentation samples. Never writes live generated/ cards or bento artifacts.
import { readFileSync, writeFileSync } from 'node:fs'
import { DEMO_DATA } from '../src/services/demo.js'
import { createCard } from '../src/constants/cards.js'
import { cardRequest } from '../src/services/cardRequest.js'
import { renderNative } from '../src/services/engine.js'
const { instance } = await WebAssembly.instantiate(readFileSync(new URL('../public/engine.wasm', import.meta.url)), {})
for (const id of ['streak', 'stats', 'rhythm', 'radar', 'velocity', 'milestones']) {
  const card = { ...createCard(id), width: 424, height: 180 }
  writeFileSync(new URL(`../../preview/${id}/standard.svg`, import.meta.url), renderNative(instance.exports, cardRequest(card, 'tokyonight', DEMO_DATA)))
  if (id === 'streak') writeFileSync(new URL('../../preview/streak/minimal.svg', import.meta.url), renderNative(instance.exports, cardRequest({ ...card, sparkline: false }, 'tokyonight', DEMO_DATA)))
}
console.log('Updated seven documentation previews using labelled sample data.')
