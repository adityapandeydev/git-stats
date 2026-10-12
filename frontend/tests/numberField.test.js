import { test } from 'node:test'
import assert from 'node:assert/strict'
import { validateNumber } from '../src/services/numberField.js'

test('numeric settings clamp at either bound and report the correction', () => {
  const bounds = { value: 294, min: 294, max: 1500, integer: true }
  for (const [draft, expected] of [['100', 294], ['2000', 1500]]) {
    const result = validateNumber(draft, bounds)
    assert.equal(result.value, expected)
    assert.ok(result.warning.includes(`Reset to ${expected}`))
  }
  assert.deepEqual(validateNumber('400', bounds), { value: 400, warning: '' })
  assert.equal(validateNumber('400.6', bounds).value, 401)
})

test('empty, partial and invalid edits restore the saved setting on commit', () => {
  for (const draft of ['', ' ', '-', '.', 'NaN', 'Infinity', '0x10', '12px', '1e3']) {
    const result = validateNumber(draft, { value: 4.5, min: 0, max: 90 })
    assert.equal(result.value, 4.5)
    assert.ok(result.warning)
  }
})

test('zero, fractional radii, signed UTC offsets and changing minimums remain valid', () => {
  assert.deepEqual(validateNumber('0', { value: 4.5, min: 0, max: 90 }), { value: 0, warning: '' })
  assert.deepEqual(validateNumber('-.5', { value: 5.5, min: -12, max: 14 }), { value: -0.5, warning: '' })
  assert.equal(validateNumber('20', { value: 5.5, min: -12, max: 14 }).value, 14)
  assert.equal(validateNumber('', { value: 294, min: 430, max: 1500 }).value, 430)
})
