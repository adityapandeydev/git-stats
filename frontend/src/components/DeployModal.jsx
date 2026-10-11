import { useState } from 'react'
import { AlertCircle, ArrowUpRight, Check, Copy, ExternalLink, GitFork, KeyRound, LoaderCircle, X } from 'lucide-react'
import Dialog from './Dialog'
import { getGitHubWebEditUrl } from '../services/compiler'
import { inspectRepository, syncWorkflowToFork } from '../services/githubApi'

export default function DeployModal({ username, yamlContent, error, target, onTarget, onClose }) {
  const [method, setMethod] = useState('editor'), [pat, setPat] = useState(''), [busy, setBusy] = useState(false), [status, setStatus] = useState(null), [copied, setCopied] = useState(false), [fileExists, setFileExists] = useState(true)
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
  return <Dialog onClose={() => { if (!busy) onClose() }} labelledBy="deploy-title" className="deploy-dialog"><div className="dialog-heading"><div><span className="eyebrow">FROM CANVAS TO PROFILE</span><h2 id="deploy-title">Ship your new profile.</h2></div><button className="icon-button" disabled={busy} aria-label="Close deployment" onClick={onClose}><X size={18} /></button></div><p>Your fork runs the Zig engine on GitHub Actions. This studio remains a static website.</p>
    <div className="deploy-destination"><GitFork size={19} /><div><strong>{target.owner || username}/{target.repo}</strong><small>{target.branch} / generated/</small></div><a href="https://github.com/adityapandeydev/git-stats/fork" target="_blank" rel="noreferrer">Fork engine <ArrowUpRight size={13} /></a></div>
    <div className="segmented deploy-methods"><button className={method === 'editor' ? 'active' : ''} onClick={() => setMethod('editor')}>GitHub web editor</button><button className={method === 'sync' ? 'active' : ''} onClick={() => setMethod('sync')}><KeyRound size={13} />Direct sync</button></div>
    {error && <div className="notice error" role="alert">{error}</div>}
    {method === 'editor' ? <div className="deploy-steps"><div><span>01</span><p><strong>Fork the engine</strong>Your own git-stats repository generates and stores the SVGs.</p></div><div><span>02</span><p><strong>Commit your workflow</strong>Copy the YAML, open GitHub’s editor, then paste and commit.</p></div><label className="checkbox-field"><input type="checkbox" checked={fileExists} onChange={e => setFileExists(e.target.checked)} />The workflow file already exists in my fork</label><div className="dialog-actions"><button className="button secondary" disabled={!!error} onClick={copy}>{copied ? <Check size={14} /> : <Copy size={14} />}{copied ? 'Workflow copied' : 'Copy workflow'}</button><a className={`button primary ${error ? 'disabled' : ''}`} href={editUrl || undefined} target="_blank" rel="noreferrer">Open editor <ExternalLink size={14} /></a></div></div> : <div className="direct-sync"><label className="field-label" htmlFor="deploy-token">Fine-grained deployment token</label><input id="deploy-token" type="password" autoComplete="off" placeholder="github_pat_…" value={pat} onChange={e => setPat(e.target.value)} /><p className="field-help">Select your fork and grant Contents, Workflows, and Actions write permissions. Kept in memory only and cleared after a successful commit.</p><div className="dialog-actions"><button className="button secondary" disabled={busy || !!error} onClick={check}>Check repository</button><button className="button primary" disabled={busy || !pat.trim() || !!error} onClick={sync}>{busy ? <LoaderCircle size={14} className="spin" /> : <ArrowUpRight size={14} />}{busy ? 'Working…' : 'Commit & run'}</button></div></div>}
    {status && <div className={`notice ${status.error || (status.committed && !status.dispatched) ? 'error' : 'success'}`} role="status">{status.error ? <AlertCircle size={16} /> : <Check size={16} />}<span>{status.error || status.message || 'Workflow committed and generation requested.'}{status.actionsUrl && <> <a href={status.actionsUrl} target="_blank" rel="noreferrer">Open Actions</a></>}</span></div>}
    <div className="deploy-last-step"><span>03</span><p><strong>Add to your profile README</strong>Once generation succeeds, copy the README snippet from Export into your username/username repository.</p></div>
    <p className="field-help">Private data may need a GH_TOKEN repository secret. Forks may require enabling Actions and scheduled workflows. Updates can take time to appear through GitHub’s image cache.</p>
  </Dialog>
}
