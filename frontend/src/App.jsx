import { useEffect, useState } from 'react'
import { BookOpen, Moon, Sun } from 'lucide-react'
import Studio from './studio/Studio'
import Docs from './docs/Docs'
import { useRoute, useTheme } from './hooks'
import { GitHubMark, Mark } from './components/Brand'

// Plays once per tab session, then unmounts.
function Boot() {
  const [show, setShow] = useState(() => {
    try { return !sessionStorage.getItem('gitstats-booted') && !matchMedia('(prefers-reduced-motion: reduce)').matches } catch { return false }
  })
  useEffect(() => {
    if (!show) return
    try { sessionStorage.setItem('gitstats-booted', '1') } catch { /* Storage may be blocked. */ }
    const timer = setTimeout(() => setShow(false), 1450)
    return () => clearTimeout(timer)
  }, [show])
  if (!show) return null
  return <div className="boot" aria-hidden="true"><div className="boot-mark"><Mark size={46} /><span className="boot-word">GitStats</span></div></div>
}

export default function App() {
  const route = useRoute()
  const { theme, toggle } = useTheme()
  return <>
    <Boot />
    <header className="header">
      <a className="brand" href="#/"><Mark /> GitStats <small>Studio</small></a>
      <nav className="nav" aria-label="Main">
        <a href="#/" aria-current={route.page === 'studio' ? 'page' : undefined}>Studio</a>
        <a href="#/docs" aria-current={route.page === 'docs' ? 'page' : undefined}><span>Docs</span></a>
      </nav>
      <div className="header-actions">
        <a className="btn btn-ghost btn-sm" href="https://github.com/adityapandeydev/git-stats" target="_blank" rel="noreferrer"><GitHubMark /><span className="github-label">GitHub</span></a>
        <button className="btn btn-sm icon-btn theme-toggle" onClick={toggle} aria-label={theme === 'dark' ? 'Switch to light theme' : 'Switch to dark theme'} title="Toggle theme">
          <Sun className="sun" size={16} /><Moon className="moon" size={16} />
        </button>
      </div>
    </header>
    <main>
      {/* Studio stays mounted so a loaded profile and token survive a visit to
          the docs. Showing it again replays its entrance animation once. */}
      <div className="enter" hidden={route.page !== 'studio'}><Studio /></div>
      {route.page === 'docs' && <div className="enter"><Docs doc={route.doc} /></div>}
    </main>
    <footer className="footer">
      <span>GitStats · Cards are rendered by the same Zig engine on GitHub and in your browser.</span>
      <span><a href="#/docs/getting-started"><BookOpen size={13} style={{ verticalAlign: '-2px' }} /> Docs</a> · <a href="https://github.com/adityapandeydev/git-stats/blob/main/LICENSE" target="_blank" rel="noreferrer">MIT license</a></span>
    </footer>
  </>
}
