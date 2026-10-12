import { useState } from 'react'
import { validateNumber } from '../services/numberField.js'

// Keep unfinished input (including an empty string) separate from saved settings.
export default function NumberField({ id, value, min, max, integer = false, onCommit }) {
  const [entry, setEntry] = useState({ saved: value, draft: String(value) })
  const [warning, setWarning] = useState('')
  if (entry.saved !== value) setEntry({ saved: value, draft: String(value) })

  function commit() {
    const result = validateNumber(entry.draft, { value, min, max, integer })
    setEntry({ saved: result.value, draft: String(result.value) })
    setWarning(result.warning)
    if (result.value !== value) onCommit(result.value)
  }

  return <>
    <input id={id} type="text" inputMode={integer ? 'numeric' : 'decimal'} autoComplete="off" spellCheck={false}
      value={entry.draft} aria-describedby={warning ? `${id}-warning` : undefined}
      onChange={event => { setEntry({ saved: value, draft: event.target.value }); setWarning('') }}
      onBlur={commit} onKeyDown={event => {
        if (event.key === 'Enter') { event.preventDefault(); event.currentTarget.blur() }
      }} />
    {warning && <p id={`${id}-warning`} className="number-field-warning" role="status">{warning}</p>}
  </>
}
