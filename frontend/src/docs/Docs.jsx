import { useEffect } from 'react'
import { ArrowLeft, ArrowRight } from 'lucide-react'
import { PAGES } from './pages'
import { useReveal } from '../hooks'

export default function Docs({ doc }) {
  const index = Math.max(0, PAGES.findIndex(p => p.id === doc))
  const page = PAGES[index]
  const ref = useReveal(page.id)
  useEffect(() => { scrollTo({ top: 0 }) }, [page.id])
  const prev = PAGES[index - 1], next = PAGES[index + 1]
  return <div className="docs">
    <nav className="docs-nav" aria-label="Documentation">
      <h4>Documentation</h4>
      {PAGES.map(p => <a key={p.id} href={`#/docs/${p.id}`} aria-current={p.id === page.id ? 'page' : undefined}>{p.title}</a>)}
    </nav>
    <article className="doc enter-forward" key={page.id} ref={ref}>
      <header><h1>{page.title}</h1><p>{page.summary}</p></header>
      <page.body />
      <nav className="doc-pager" aria-label="Pages">
        {prev && <a href={`#/docs/${prev.id}`}><small><ArrowLeft size={12} /> Previous</small>{prev.title}</a>}
        {next ? <a href={`#/docs/${next.id}`}><small>Next <ArrowRight size={12} /></small>{next.title}</a> : <a href="#/"><small>Ready? <ArrowRight size={12} /></small>Open Studio</a>}
      </nav>
    </article>
  </div>
}
