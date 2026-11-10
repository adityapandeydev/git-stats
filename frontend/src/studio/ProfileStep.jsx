import { useState } from 'react'
import { ArrowRight, Check, ChevronDown, CircleAlert, KeyRound, LoaderCircle, Lock, User } from 'lucide-react'
import { CARDS } from '../services/profileConfig'

export default function ProfileStep({ username, onUsername, token, onToken, data, load, onLoad, onSample, onNext }) {
  const [tokenDraft, setTokenDraft] = useState(token)
  const loading = load.status === 'loading'
  const live = data?.source && data.source !== 'demo'
  const submit = event => {
    event.preventDefault()
    onToken(tokenDraft.trim())
    onLoad(tokenDraft.trim())
  }

  return <div className="profile-step">
    <form className="panel panel-pad profile-form" onSubmit={submit}>
      <div>
        <h2>Whose profile are you designing?</h2>
        <p className="hint" style={{ marginTop: 6 }}>Enter your GitHub username to preview cards with your own data. Your design is saved in this browser.</p>
      </div>
      <div className="inline">
        <label className="input-group">
          <span className="sr-only">GitHub username</span>
          <User size={18} />
          <input className="input input-lg" value={username} onChange={e => onUsername(e.target.value)} placeholder="your-username" autoComplete="off" spellCheck="false" autoFocus />
        </label>
        <button className="btn btn-primary btn-lg" disabled={loading || !username.trim()}>
          {loading ? <LoaderCircle size={18} className="spin" /> : <>Load profile <ArrowRight size={17} className="nudge" /></>}
        </button>
      </div>

      <details className="disclosure" open={Boolean(token) || undefined}>
        <summary><KeyRound size={16} /> Preview every card with your data <span className="tag-optional">Optional</span><ChevronDown size={16} className="chev" /></summary>
        <div className="disclosure-body">
          <p className="hint">Without a token, only Top languages and Developer DNA use your real data, because GitHub doesn't share contribution history publicly. A read-only token unlocks the rest of the preview.</p>
          <div className="field">
            <label className="label" htmlFor="read-token">Read-only token <span>kept in this tab only</span></label>
            <input id="read-token" className="input" type="password" autoComplete="off" placeholder="github_pat_…" value={tokenDraft} onChange={e => setTokenDraft(e.target.value)} />
          </div>
          <p className="hint">Create a <a href="https://github.com/settings/personal-access-tokens/new" target="_blank" rel="noreferrer">fine-grained token</a> with read access to your repositories. It's never saved, exported, or sent anywhere except GitHub. <a href="#/docs/tokens">Token guide</a></p>
        </div>
      </details>
      {load.error && <div className="notice error" role="alert"><CircleAlert size={16} /><span>{load.error} <button type="button" className="btn btn-sm btn-ghost" onClick={onSample}>Keep sample data</button></span></div>}
    </form>

    <aside className="panel panel-pad data-status" aria-label="Preview data">
      <div className="panel-title">Preview data <span className={`badge ${live ? 'live' : 'sample'}`}><span className="dot" />{live ? (data.source === 'authenticated' ? 'Your data' : 'Public data') : 'Sample data'}</span></div>
      <div className="data-row">
        {live && data.avatarUrl ? <img className="avatar" src={data.avatarUrl} alt="" /> : <div className="avatar" />}
        <div><strong>{live ? data.name : 'Sample developer'}</strong><span>{live ? `@${data.login}` : 'Load a profile to replace the sample'}</span></div>
      </div>
      <div className="coverage">
        {CARDS.map(card => {
          const real = live && data.available.includes(card.id)
          return <div key={card.id} className={real ? 'yes' : ''} title={real ? 'Your data' : 'Sample data'}>{real ? <Check size={14} /> : <Lock size={14} />}{card.name}</div>
        })}
      </div>
      <p className="hint">{live ? data.notes?.[0] : 'You can design with sample data and publish anyway. Your published cards always use your real data.'}</p>
      <div className="step-footer"><button type="button" className="btn" onClick={onNext}>Design with {live ? 'this data' : 'sample data'} <ArrowRight size={16} className="nudge" /></button></div>
    </aside>
  </div>
}
