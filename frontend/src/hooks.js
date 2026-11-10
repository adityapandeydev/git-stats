import { useCallback, useEffect, useRef, useState, useSyncExternalStore } from 'react'

// ---- Routing: #/ (studio) and #/docs/<page>. Works on any static host. ----
const readRoute = () => {
  const parts = location.hash.replace(/^#\/?/, '').split('/').filter(Boolean)
  return parts[0] === 'docs' ? { page: 'docs', doc: parts[1] || 'getting-started' } : { page: 'studio', doc: null }
}
let route = readRoute()
const listeners = new Set()
addEventListener('hashchange', () => { route = readRoute(); listeners.forEach(fn => fn()) })
export function useRoute() {
  return useSyncExternalStore(fn => { listeners.add(fn); return () => listeners.delete(fn) }, () => route)
}

// ---- Theme: circular reveal from the toggle where View Transitions exist. ----
export function useTheme() {
  const [theme, setThemeState] = useState(() => document.documentElement.dataset.theme || 'dark')
  const apply = useCallback(next => {
    document.documentElement.dataset.theme = next
    try { localStorage.setItem('gitstats-theme', next) } catch { /* Storage may be blocked. */ }
    setThemeState(next)
  }, [])
  const toggle = useCallback(event => {
    const next = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark'
    const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches
    if (!document.startViewTransition || reduce) {
      const root = document.documentElement
      root.classList.add('theme-fade')
      apply(next)
      setTimeout(() => root.classList.remove('theme-fade'), 400)
      return
    }
    const rect = event?.currentTarget?.getBoundingClientRect()
    const x = rect ? rect.left + rect.width / 2 : innerWidth - 40, y = rect ? rect.top + rect.height / 2 : 32
    const radius = Math.hypot(Math.max(x, innerWidth - x), Math.max(y, innerHeight - y))
    const transition = document.startViewTransition(() => apply(next))
    transition.ready.then(() => document.documentElement.animate(
      { clipPath: [`circle(0px at ${x}px ${y}px)`, `circle(${radius}px at ${x}px ${y}px)`] },
      { duration: 520, easing: 'cubic-bezier(.16, 1, .3, 1)', pseudoElement: '::view-transition-new(root)' },
    )).catch(() => {})
  }, [apply])
  return { theme, toggle }
}

// ---- Reveal on scroll, once. Observers disconnect after revealing. ----
export function useReveal(key) {
  const ref = useRef(null)
  useEffect(() => {
    const root = ref.current
    if (!root) return
    const items = [...root.querySelectorAll('.reveal:not(.is-visible)')]
    if (!('IntersectionObserver' in window)) { items.forEach(el => el.classList.add('is-visible')); return }
    const observer = new IntersectionObserver(entries => {
      for (const entry of entries) if (entry.isIntersecting) { entry.target.classList.add('is-visible'); observer.unobserve(entry.target) }
    }, { rootMargin: '0px 0px -8% 0px' })
    items.forEach(el => observer.observe(el))
    return () => observer.disconnect()
  }, [key])
  return ref
}

// ---- Storage that never throws (private windows, blocked storage). ----
export function readStored(key, fallback) {
  try { const raw = localStorage.getItem(key); return raw ? JSON.parse(raw) : fallback } catch { return fallback }
}
export function writeStored(key, value) {
  try { localStorage.setItem(key, JSON.stringify(value)); return true } catch { return false }
}
