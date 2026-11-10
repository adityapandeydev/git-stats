// Pure layout edits for the Studio canvas. Every function returns a new layout.
import { ROW_TYPES, slotAccepts } from './profileConfig.js'

const clone = layout => layout.map(row => ({ ...row, cards: [...row.cards] }))

/** Where a card currently is, or null. */
export function findCard(layout, id) {
  for (let r = 0; r < layout.length; r++) {
    const s = layout[r].cards.indexOf(id)
    if (s >= 0) return { r, s }
  }
  return null
}

/** Can `id` be dropped into row r, slot s (swapping with any occupant)? */
export function canPlace(layout, id, r, s) {
  const row = layout[r]
  if (!row || !slotAccepts(row.type, s, id)) return false
  const from = findCard(layout, id)
  const occupant = row.cards[s]
  // A swap must also be valid for the card being displaced.
  if (from && occupant && occupant !== id) return slotAccepts(layout[from.r].type, from.s, occupant)
  return true
}

/**
 * Drop a card into a slot. A card dragged from another slot swaps with the
 * occupant; a card dragged from the palette sends the occupant back to it.
 */
export function placeCard(layout, id, r, s) {
  if (!canPlace(layout, id, r, s)) return layout
  const next = clone(layout)
  const from = findCard(next, id)
  const occupant = next[r].cards[s]
  if (from) next[from.r].cards[from.s] = occupant && occupant !== id ? occupant : null
  next[r].cards[s] = id
  return next
}

export const removeCard = (layout, id) => layout.map(row => ({ ...row, cards: row.cards.map(c => (c === id ? null : c)) }))

export const addRow = (layout, type) => (ROW_TYPES[type] ? [...clone(layout), { type, cards: Array(ROW_TYPES[type].slots).fill(null) }] : layout)

export const deleteRow = (layout, r) => layout.filter((_, i) => i !== r)

export function moveRow(layout, r, delta) {
  const to = r + delta
  if (to < 0 || to >= layout.length) return layout
  const next = clone(layout)
  ;[next[r], next[to]] = [next[to], next[r]]
  return next
}

/** First empty slot that accepts the card, adding a suitable row if none exists. */
export function autoPlace(layout, id) {
  if (findCard(layout, id)) return layout
  for (let r = 0; r < layout.length; r++) {
    for (let s = 0; s < layout[r].cards.length; s++) if (!layout[r].cards[s] && slotAccepts(layout[r].type, s, id)) return placeCard(layout, id, r, s)
  }
  const type = id === 'languages' ? 'stack' : 'pair'
  const grown = addRow(layout, type)
  return placeCard(grown, id, grown.length - 1, id === 'languages' ? 2 : 0)
}
