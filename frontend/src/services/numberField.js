export function validateNumber(draft, { value, min, max, integer = false }) {
  const raw = draft.trim()
  const number = /^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(raw) ? Number(raw) : NaN
  const clamp = n => Math.min(max, Math.max(min, n))
  if (!Number.isFinite(number)) {
    const restored = clamp(value)
    return { value: restored, warning: `Enter a number between ${min} and ${max}. Restored to ${restored}.` }
  }
  if (number < min) return { value: min, warning: `Minimum is ${min}. Reset to ${min}.` }
  if (number > max) return { value: max, warning: `Maximum is ${max}. Reset to ${max}.` }
  if (integer && !Number.isInteger(number)) {
    const rounded = clamp(Math.round(number))
    return { value: rounded, warning: `Use a whole number. Rounded to ${rounded}.` }
  }
  return { value: number, warning: '' }
}
