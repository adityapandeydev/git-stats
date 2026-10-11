import { ArrowRight, Download, GitBranch, LoaderCircle, KeyRound } from 'lucide-react'
export default function Navbar({ username, onUsername, onLoad, loading, onExport, onDeploy, canExport, onConnect, connected }) {
  return <header className="topbar">
    <a className="brand" href="./" aria-label="GitStats Studio home"><span className="brand-mark">gs<span>.</span></span><span>gitstats <span className="brand-studio">/ studio</span></span></a>
    <form className="profile-form" onSubmit={e => { e.preventDefault(); onLoad() }}><GitBranch size={16} /><input aria-label="GitHub username" placeholder="GitHub username" value={username} onChange={e => onUsername(e.target.value)} spellCheck="false" autoComplete="off" /><button type="submit" aria-label="Load GitHub profile" disabled={loading}>{loading ? <LoaderCircle size={15} className="spin" /> : <ArrowRight size={15} />}</button></form>
    <div className="topbar-actions"><button className="button secondary connect-button" onClick={onConnect}><KeyRound size={14} />{connected ? 'GitHub connected' : 'Connect GitHub'}</button><button className="button secondary" aria-label="Export" onClick={onExport}><Download size={14} /><span>Export</span></button><button className="button primary" onClick={onDeploy} disabled={!canExport}>Deploy profile <ArrowRight size={14} /></button></div>
  </header>
}
