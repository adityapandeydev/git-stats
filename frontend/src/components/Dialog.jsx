import { useEffect, useRef } from 'react'
export default function Dialog({ children, onClose, labelledBy, className = '' }) {
  const ref = useRef(null)
  useEffect(() => {
    const previous = document.activeElement
    const overflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    ref.current?.querySelector('input, button, a, select, textarea')?.focus()
    return () => { document.body.style.overflow = overflow; previous?.focus?.() }
  }, [])
  const handleKey = e => {
    if (e.key === 'Escape') { e.stopPropagation(); onClose() }
    if (e.key !== 'Tab') return
    const elements = [...ref.current.querySelectorAll('button:not(:disabled), a[href], input, select, textarea, [tabindex="0"]')].filter(el => el.offsetParent !== null)
    const first = elements[0], last = elements.at(-1)
    if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last?.focus() }
    if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first?.focus() }
  }
  return <div className="modal-backdrop" onClick={onClose}><section ref={ref} className={`dialog ${className}`} role="dialog" aria-modal="true" aria-labelledby={labelledBy} onClick={e => e.stopPropagation()} onKeyDown={handleKey}>{children}</section></div>
}
