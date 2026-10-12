import { useState } from 'react'
import { AlertCircle, ArrowUpRight, Check, Copy, ExternalLink, GitFork, KeyRound, LoaderCircle, X } from 'lucide-react'
import Dialog from './Dialog'
import TokenGuide from './TokenGuide'
import { getGitHubWebEditUrl } from '../services/compiler'
import { inspectRepository, syncWorkflowToFork } from '../services/githubApi'

export default function DeployModal({ username, yamlContent, error, target, onTarget, onClose, dataSource }) {
  const [method, setMethod] = useState('editor'), [pat, setPat] = useState(''), [busy, setBusy] = useState(false), [status, setStatus] = useState(null), [copied, setCopied] = useState(false), [fileExists, setFileExists] = useState(true), [reviewedKey, setReviewedKey] = useState('')
  const reviewKey = JSON.stringify([target, yamlContent])
  const reviewed = reviewedKey === reviewKey
  let editUrl = ''
  try { editUrl = getGitHubWebEditUrl(username, target, fileExists) } catch { /* Compiler presents validation errors. */ }
  const copy = async () => {
    try { await navigator.clipboard.writeText(yamlContent); setCopied(true) }
    catch { setStatus({ error: 'Clipboard unavailable. Use Export to download the workflow.' }) }
  }
  const sync = async () => {
    setBusy(true); setStatus(null)
    try { const result = await syncWorkflowToFork({ username, pat, yamlContent, target }); setStatus(result); setPat('') }
    catch (e) { setStatus({ error: e.message }) }
    finally { setBusy(false) }
  }
  const check = async () => {
    setBusy(true); setStatus(null)
    try { const result = await inspectRepository(username, pat, target); setFileExists(Boolean(result.file)); onTarget({ branch: result.branch }); setStatus({ checked: true, message: `Repository found. ${result.file ? 'The workflow will be updated.' : 'A new workflow will be created.'}` }) }
    catch (e) { setStatus({ error: `${e.message} Fork the engine first, or check the destination settings.` }) }
    finally { setBusy(false) }
  }
  return <Dialog onClose={() => { if (!busy) onClose() }} labelledBy="deploy-title" className="deploy-dialog"><div className="dialog-heading"><div><span className="eyebrow">FROM CANVAS TO PROFILE</span><h2 id="deploy-title">Ship your new profile.</h2></div><button className="icon-button" disabled={busy} aria-label="Close deployment" onClick={onClose}><X size={18} /></button></div><p>Studio can commit the workflow to your fork. GitHub Actions then generates and commits the SVGs; you add the README snippet to your profile.</p>
    <div className="deploy-destination"><GitFork size={19} /><div><strong>{target.owner || username}/{target.repo}</strong><small>{target.branch} / generated/</small></div><a href="https://github.com/adityapandeydev/git-stats/fork" target="_blank" rel="noreferrer">Fork engine <ArrowUpRight size={13} /></a></div>
    <div className="deploy-progress" aria-label="Deployment steps"><span><b>01 / PREPARE</b>Fork &amp; read secret</span><span><b>02 / REVIEW</b>Preview &amp; workflow</span><span><b>03 / GENERATE</b>Commit &amp; run</span><span><b>04 / EMBED</b>Profile README</span></div>
    <details className="deploy-checklist"><summary>Prepare your fork and read secret</summary><p>Use <strong>Profile preview</strong> to review your layout. Load your data to replace the sample cards.</p><p>For scheduled profile data, add a longer-lived read token as <code>GH_TOKEN</code> in your fork’s Actions secrets. The temporary Studio token is not copied there.</p><p><a href={`https://github.com/${target.owner || username}/${target.repo}/settings/secrets/actions`} target="_blank" rel="noreferrer">Open Actions secrets</a>{' · '}<a href={`https://github.com/${target.owner || username}/${target.repo}/actions`} target="_blank" rel="noreferrer">Enable or view Actions</a></p></details>
    {dataSource !== 'authenticated' && <p className="field-help">{dataSource === 'demo' ? 'Your preview currently uses sample data.' : 'Your preview does not contain all authenticated profile data.'} Actions will fetch the selected username’s data at generation time; sample values are never exported.</p>}
    <TokenGuide />
    <div className="segmented deploy-methods"><button className={method === 'editor' ? 'active' : ''} disabled={busy} onClick={() => setMethod('editor')}>Copy to GitHub</button><button className={method === 'sync' ? 'active' : ''} disabled={busy} onClick={() => setMethod('sync')}><KeyRound size={13} />Commit from Studio</button></div>
    {error && <div className="notice error" role="alert">{error}</div>}
    {method === 'editor' ? <div className="deploy-steps"><div><span>01</span><p><strong>Fork the engine</strong>Your own git-stats repository generates and stores the SVGs.</p></div><div><span>02</span><p><strong>Commit your workflow</strong>Copy the YAML, open GitHub’s editor, then paste and commit.</p></div><label className="checkbox-field"><input type="checkbox" checked={fileExists} onChange={e => setFileExists(e.target.checked)} />The workflow file already exists in my fork</label><div className="dialog-actions"><button className="button secondary" disabled={!!error} onClick={copy}>{copied ? <Check size={14} /> : <Copy size={14} />}{copied ? 'Workflow copied' : 'Copy workflow'}</button><a className={`button primary ${error ? 'disabled' : ''}`} href={editUrl || undefined} target="_blank" rel="noreferrer">Open editor <ExternalLink size={14} /></a></div></div> : <div className="direct-sync"><label className="field-label" htmlFor="deploy-token">Temporary deployment token</label><input id="deploy-token" type="password" autoComplete="off" placeholder="github_pat_…" value={pat} onChange={e => setPat(e.target.value)} /><p className="field-help">Select only your engine fork. Grant Contents, Workflows, and Actions write permissions. This token stays in memory, is cleared after a successful commit, and is never included in the workflow.</p><details className="deploy-review"><summary>Review workflow · .github/workflows/generate-stats.yml</summary><pre>{yamlContent}</pre></details><label className="checkbox-field"><input type="checkbox" checked={reviewed} disabled={busy || status?.committed} onChange={e => setReviewedKey(e.target.checked ? reviewKey : '')} />I reviewed the destination and workflow that will be committed.</label><p className="deploy-permissions">Destination: <strong>{target.owner || username}/{target.repo}</strong> · branch <strong>{target.branch}</strong>. Only <code>.github/workflows/generate-stats.yml</code> will change.</p><div className="dialog-actions"><button className="button secondary" disabled={busy || !!error || !pat.trim() || status?.committed} onClick={check}>Check repository</button><button className="button primary" disabled={busy || !pat.trim() || !!error || !reviewed || status?.committed} onClick={sync}>{busy ? <LoaderCircle size={14} className="spin" /> : <ArrowUpRight size={14} />}{busy ? 'Working…' : 'Commit & run'}</button></div></div>}
    {status && <div className={`notice ${status.error || (status.committed && !status.dispatched) ? 'error' : 'success'}`} role="status">{status.error ? <AlertCircle size={16} /> : <Check size={16} />}<span>{status.error || status.message || 'Workflow committed and generation requested.'}{status.actionsUrl && <> <a href={status.actionsUrl} target="_blank" rel="noreferrer">Open Actions</a></>}</span></div>}
    <div className="deploy-last-step"><span>04</span><p><strong>Add to your profile README</strong>Once generation succeeds, copy the README snippet from Export into your username/username repository.</p></div>
    <p className="field-help">Forks may require enabling Actions and scheduled workflows. Branch protection or organization policies may block direct commits; use your repository’s normal review process. GitHub’s image cache can delay updates.</p>
  </Dialog>
}
