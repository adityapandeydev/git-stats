import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { ArrowLeft, Check, ChevronDown, CircleAlert, Copy, Download, ExternalLink, KeyRound, LoaderCircle, RefreshCw } from 'lucide-react'
import { MARKER_END, MARKER_START, WORKFLOW_PATH, compileReadme, compileWorkflow, placedCards, publishLinks } from '../services/profileConfig'
import { checkPublicProfile, commitWorkflow } from '../services/githubApi'

const CheckMark = () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5" /></svg>
const POLL_MS = 20000, POLL_LIMIT = 30 // about ten minutes

export default function PublishStep({ username, config, onBack }) {
  const yaml = useMemo(() => compileWorkflow(config), [config])
  const links = useMemo(() => publishLinks(username, yaml), [username, yaml])
  const firstCard = placedCards(config)[0]
  const [repo, setRepo] = useState({ status: 'checking' })
  const [copied, setCopied] = useState('')
  const [live, setLive] = useState({ status: 'idle', tries: 0 })
  const [pat, setPat] = useState('')
  const [commit, setCommit] = useState({ status: 'idle', error: '' })

  const runCheck = useCallback(async signal => {
    try { setRepo({ status: 'done', ...(await checkPublicProfile(username, signal)) }) }
    catch (e) { if (e.name !== 'AbortError') setRepo({ status: 'error', error: e.message }) }
  }, [username])
  // GitHub is an external system; runCheck sets state only after its request resolves.
  // oxlint-disable-next-line react/set-state-in-effect
  useEffect(() => { const c = new AbortController(); runCheck(c.signal); return () => c.abort() }, [runCheck])
  const check = () => { setRepo({ status: 'checking' }); runCheck() }

  // Is the first card already published? Image loads need no token or CORS.
  const probe = useCallback(() => new Promise(resolve => {
    const img = new Image()
    img.onload = () => resolve(true); img.onerror = () => resolve(false)
    img.src = `${links.rawCard(firstCard)}?t=${Date.now()}`
  }), [links, firstCard])
  useEffect(() => { probe().then(ok => ok && setLive({ status: 'live', tries: 0 })) }, [probe])
  // Polling runs only while waiting for the first run, and stops by itself.
  const polling = useRef(null)
  useEffect(() => {
    if (live.status !== 'waiting') return
    polling.current = setTimeout(async () => {
      if (await probe()) setLive({ status: 'live', tries: 0 })
      else setLive(l => (l.tries + 1 >= POLL_LIMIT ? { status: 'timeout', tries: 0 } : { status: 'waiting', tries: l.tries + 1 }))
    }, POLL_MS)
    return () => clearTimeout(polling.current)
  }, [live, probe])
  const startWatching = () => setLive(l => (l.status === 'live' ? l : { status: 'waiting', tries: 0 }))

  const copy = async (text, what) => {
    try { await navigator.clipboard.writeText(text); setCopied(what); setTimeout(() => setCopied(''), 1800) }
    catch { setCopied('failed') }
  }
  const download = () => {
    const url = URL.createObjectURL(new Blob([yaml], { type: 'text/yaml' }))
    const a = document.createElement('a'); a.href = url; a.download = 'gitstats.yml'; a.click()
    setTimeout(() => URL.revokeObjectURL(url), 1000)
  }
  const commitForMe = async () => {
    setCommit({ status: 'busy', error: '' })
    try { await commitWorkflow({ username, pat, yamlContent: yaml }); setPat(''); setCommit({ status: 'done', error: '' }); startWatching(); check() }
    catch (e) { setCommit({ status: 'error', error: e.message }) }
  }

  const repoReady = repo.status === 'done' && repo.repo
  const hasWorkflow = repo.status === 'done' && repo.workflow
  const readme = `${MARKER_START}\n${compileReadme(config)}\n${MARKER_END}`

  return <div className="publish">
    <div className="panel panel-pad">
      <ol className="timeline">
        <li className={repoReady ? 'done' : ''}>
          <span className="marker">{repoReady ? <CheckMark /> : 1}</span>
          <div>
            <h3>Your profile repository</h3>
            <p>GitHub shows the README of the repository named after you, <code>{username}/{username}</code>, on your profile.</p>
            <div className="status-line" style={{ marginTop: 10 }}>
              {repo.status === 'checking' && <><LoaderCircle size={15} className="spin" /> Checking GitHub…</>}
              {repo.status === 'done' && (repo.repo ? <span className="badge live"><span className="dot" />Found</span> : <span className="badge sample"><span className="dot" />Not created yet</span>)}
              {repo.status === 'error' && <span className="hint">{repo.error}</span>}
            </div>
            <div className="actions">
              {repo.status === 'done' && !repo.repo && <a className="btn btn-primary btn-sm" href={links.createRepo} target="_blank" rel="noreferrer">Create {username}/{username} <ExternalLink size={13} /></a>}
              {repoReady && <a className="btn btn-sm" href={links.repo} target="_blank" rel="noreferrer">Open repository <ExternalLink size={13} /></a>}
              <button className="btn btn-sm btn-ghost" onClick={() => check()}><RefreshCw size={13} /> Check again</button>
            </div>
          </div>
        </li>

        <li className={hasWorkflow || commit.status === 'done' ? 'done' : ''}>
          <span className="marker">{hasWorkflow || commit.status === 'done' ? <CheckMark /> : 2}</span>
          <div>
            <h3>Add the GitStats workflow</h3>
            <p>One file. GitHub opens it pre-filled; click <strong>Commit changes</strong>. It draws your cards, adds them to your README between two markers, and refreshes them every four hours.</p>
            <div className="actions">
              {hasWorkflow
                ? <><a className="btn btn-primary btn-sm" href={links.editWorkflow} target="_blank" rel="noreferrer" onClick={startWatching}>Open existing file <ExternalLink size={13} /></a><button className="btn btn-sm" onClick={() => copy(yaml, 'workflow')}>{copied === 'workflow' ? <Check size={13} /> : <Copy size={13} />} Copy new version</button></>
                : <a className={`btn btn-primary btn-sm ${repoReady ? '' : 'is-disabled'}`} aria-disabled={!repoReady} href={repoReady ? links.newWorkflow : undefined} target="_blank" rel="noreferrer" onClick={startWatching}>Open GitHub and commit <ExternalLink size={13} /></a>}
            </div>
            {hasWorkflow && <p className="hint" style={{ marginTop: 8 }}>You already have a workflow. To change your design, replace the file's contents with the new version and commit.</p>}
            <details className="disclosure" style={{ marginTop: 14 }}>
              <summary><KeyRound size={15} /> Or let Studio commit it <span className="tag-optional">Needs a token</span><ChevronDown size={15} className="chev" /></summary>
              <div className="disclosure-body">
                <p className="hint">Use a fine-grained token limited to <code>{username}/{username}</code> with <strong>Contents</strong> and <strong>Workflows</strong> set to read and write. It's used once, kept in this tab, and cleared afterwards.</p>
                <input className="input" type="password" autoComplete="off" placeholder="github_pat_…" value={pat} onChange={e => setPat(e.target.value)} aria-label="Write token" />
                <div><button className="btn btn-sm" disabled={!pat.trim() || commit.status === 'busy' || !repoReady} onClick={commitForMe}>{commit.status === 'busy' ? <LoaderCircle size={13} className="spin" /> : <Check size={13} />} Commit workflow</button></div>
                {commit.status === 'done' && <div className="notice ok"><Check size={16} />Committed. The first run has started.</div>}
                {commit.error && <div className="notice error" role="alert"><CircleAlert size={16} />{commit.error}</div>}
              </div>
            </details>
          </div>
        </li>

        <li>
          <span className="marker">3</span>
          <div>
            <h3>Count private work <span className="tag-optional">Optional</span></h3>
            <p>Without this, cards use public data. To include private repositories and contributions, create a read-only token and save it as a repository secret named <code>GH_TOKEN</code>.</p>
            <div className="actions">
              <a className="btn btn-sm" href="https://github.com/settings/personal-access-tokens/new" target="_blank" rel="noreferrer">Create token <ExternalLink size={13} /></a>
              <a className={`btn btn-sm ${repoReady ? '' : 'is-disabled'}`} aria-disabled={!repoReady} href={repoReady ? links.secrets : undefined} target="_blank" rel="noreferrer">Add GH_TOKEN secret <ExternalLink size={13} /></a>
              <a className="btn btn-sm btn-ghost" href="#/docs/tokens">Step-by-step guide</a>
            </div>
          </div>
        </li>

        <li className={live.status === 'live' ? 'done' : ''}>
          <span className="marker">{live.status === 'live' ? <CheckMark /> : 4}</span>
          <div>
            <h3>Your cards go live</h3>
            {live.status === 'live' && <><p>Your cards are on GitHub. Your profile shows them now, and they'll refresh every four hours.</p>
              <img src={links.rawCard(firstCard)} alt="" style={{ width: '100%', maxWidth: 424, marginTop: 12, borderRadius: 6 }} />
              <div className="actions"><a className="btn btn-primary btn-sm" href={`https://github.com/${username}`} target="_blank" rel="noreferrer">View your profile <ExternalLink size={13} /></a></div></>}
            {live.status === 'waiting' && <p className="status-line"><LoaderCircle size={15} className="spin" /> Waiting for the first run. It usually takes one to two minutes.</p>}
            {live.status === 'timeout' && <p>No cards yet. Open Actions to see whether the run finished or needs attention.</p>}
            {live.status === 'idle' && <p>After you commit the workflow, the first run takes a minute or two. This step turns green when your cards appear.</p>}
            {live.status !== 'live' && <div className="actions">
              <a className="btn btn-sm" href={links.actions} target="_blank" rel="noreferrer">Open Actions <ExternalLink size={13} /></a>
              {live.status !== 'waiting' && <button className="btn btn-sm btn-ghost" onClick={startWatching}><RefreshCw size={13} /> Watch for my cards</button>}
            </div>}
          </div>
        </li>
      </ol>
      <div className="step-footer" style={{ justifyContent: 'flex-start' }}><button className="btn btn-ghost" onClick={onBack}><ArrowLeft size={16} /> Back to design</button></div>
    </div>

    <div style={{ display: 'grid', gap: 16 }}>
      <div className="code">
        <div className="code-head"><span><code>{WORKFLOW_PATH}</code></span>
          <span style={{ display: 'flex', gap: 4 }}>
            <button className="btn btn-sm btn-ghost" onClick={download}><Download size={13} /> Download</button>
            <button className="btn btn-sm" onClick={() => copy(yaml, 'workflow')}>{copied === 'workflow' ? <Check size={13} /> : <Copy size={13} />} {copied === 'workflow' ? 'Copied' : 'Copy'}</button>
          </span>
        </div>
        <pre tabIndex="0">{yaml}</pre>
      </div>
      <details className="disclosure">
        <summary>What the workflow adds to your README <ChevronDown size={15} className="chev" /></summary>
        <div className="disclosure-body">
          <p className="hint">Only the part between the two markers is ever changed. Move the block anywhere in your README; the workflow finds it. Without markers, it's added at the end.</p>
          <div className="code"><div className="code-head"><span>README.md</span><button className="btn btn-sm" onClick={() => copy(readme, 'readme')}>{copied === 'readme' ? <Check size={13} /> : <Copy size={13} />} Copy</button></div><pre tabIndex="0">{readme}</pre></div>
        </div>
      </details>
      {copied === 'failed' && <div className="notice error" role="alert"><CircleAlert size={16} />Clipboard access was blocked. Select the text, or use Download.</div>}
    </div>
  </div>
}
