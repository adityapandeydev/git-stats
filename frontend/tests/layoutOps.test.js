import { test } from 'node:test'
import assert from 'node:assert/strict'
import { addRow, autoPlace, canPlace, deleteRow, findCard, moveRow, placeCard, removeCard } from '../src/services/layoutOps.js'

const base = () => [{ type: 'stack', cards: ['streak', 'stats', 'languages'] }, { type: 'pair', cards: ['radar', null] }, { type: 'wide', cards: ['milestones'] }]

test('placing from the palette fills a slot and returns the occupant to the palette', () => {
  const next = placeCard(base(), 'velocity', 1, 0)
  assert.deepEqual(next[1].cards, ['velocity', null])
  assert.equal(findCard(next, 'radar'), null)
})

test('dragging between slots swaps cards when both moves are valid', () => {
  const next = placeCard(base(), 'stats', 1, 0)
  assert.deepEqual(next[0].cards, ['streak', 'radar', 'languages'])
  assert.deepEqual(next[1].cards, ['stats', null])
  // radar cannot go into a wide row, so streak (wide-capable) <-> milestones works but stats does not.
  assert.equal(canPlace(base(), 'stats', 2, 0), false)
  assert.equal(canPlace(base(), 'streak', 2, 0), true)
  assert.deepEqual(placeCard(base(), 'streak', 2, 0)[0].cards, ['milestones', 'stats', 'languages'])
})

test('invalid drops leave the layout unchanged', () => {
  const layout = base()
  assert.equal(placeCard(layout, 'languages', 1, 1), layout)
  assert.equal(placeCard(layout, 'stats', 0, 2), layout)
  // Swapping languages into a pair row would put it in a slot that rejects it.
  assert.equal(canPlace(layout, 'radar', 0, 2), false)
})

test('rows can be added, moved and removed without mutating the input', () => {
  const layout = base()
  const added = addRow(layout, 'pair')
  assert.equal(added.length, 4)
  assert.equal(layout.length, 3)
  assert.deepEqual(moveRow(layout, 0, 1).map(r => r.type), ['pair', 'stack', 'wide'])
  assert.equal(moveRow(layout, 0, -1), layout)
  assert.deepEqual(deleteRow(layout, 1).map(r => r.type), ['stack', 'wide'])
  assert.deepEqual(removeCard(layout, 'stats')[0].cards, ['streak', null, 'languages'])
})

test('auto-place uses the first free slot or adds a fitting row', () => {
  assert.deepEqual(autoPlace(base(), 'rhythm')[1].cards, ['radar', 'rhythm'])
  const full = autoPlace(autoPlace(base(), 'rhythm'), 'velocity')
  assert.deepEqual(full.at(-1), { type: 'pair', cards: ['velocity', null] })
  const withoutLanguages = removeCard(base(), 'languages')
  assert.deepEqual(autoPlace(withoutLanguages, 'languages')[0].cards, ['streak', 'stats', 'languages'])
  assert.deepEqual(autoPlace([], 'languages'), [{ type: 'stack', cards: [null, null, 'languages'] }])
})
