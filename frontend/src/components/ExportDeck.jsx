import { useState } from 'react'
import { Check, Code2, Copy, Download, FileCode2, X } from 'lucide-react'
import Dialog from './Dialog'
export default function ExportDeck({ htmlCode, yamlCode, error, onClose }) {
  const [tab, setTab] = useState('html'), [copied, setCopied] = useState(false), [copyError, setCopyError] = useState('')
  const content = tab === 'html' ? htmlCode : yamlCode
  const copy = async () => {
    try { await navigator.clipboard.writeText(content); setCopied(true); setCopyError('') }
    catch { setCopyError('Clipboard access is unavailable. Select the code or download the file.') }
  }
  const download = () => {
    const url = URL.createObjectURL(new Blob([content], { type: 'text/plain;charset=utf-8' }))
    const a = document.createElement('a'); a.href = url; a.download = tab === 'html' ? 'profile-stats.md' : 'generate-stats.yml'; a.click(); setTimeout(() => URL.revokeObjectURL(url), 1000)
  }
  return <Dialog onClose={onClose} labelledBy="export-title" className="export-dialog"><div className="dialog-heading"><div><span className="eyebrow">TAKE IT WITH YOU</span><h2 id="export-title">Your profile, compiled.</h2></div><button className="icon-button" aria-label="Close export" onClick={onClose}><X size={18} /></button></div><p>The exact configuration from your canvas, ready for GitHub.</p>
    <div className="export-toolbar"><div className="segmented" role="tablist" aria-label="Export format"><button role="tab" aria-selected={tab === 'html'} className={tab === 'html' ? 'active' : ''} onClick={() => { setTab('html'); setCopied(false) }}><Code2 size={14} />Profile README</button><button role="tab" aria-selected={tab === 'yaml'} className={tab === 'yaml' ? 'active' : ''} onClick={() => { setTab('yaml'); setCopied(false) }}><FileCode2 size={14} />Actions workflow</button></div><span className="file-extension">{tab === 'html' ? '.md' : '.yml'}</span></div>
    {error ? <div className="notice error" role="alert">{error}</div> : <pre className="code-view" tabIndex="0" aria-label="Generated code">{content.split('\n').map((line, i) => <div className="code-line" key={i}><span aria-hidden="true">{i + 1}</span><code>{line || ' '}</code></div>)}</pre>}
    <p className="field-help">{tab === 'html' ? 'Paste into username/username/README.md after your SVG generation workflow succeeds. Profile preview renders this same markup with local SVGs. GitHub controls wrapping at the available README width.' : 'Commit as .github/workflows/generate-stats.yml in your engine fork. Uses Zig 0.16.0, runs every four hours, and only stages your selected SVG files.'}</p>
    {copyError && <p className="notice error" role="alert">{copyError}</p>}<div className="dialog-actions"><button className="button secondary" disabled={!content} onClick={download}><Download size={14} />Download</button><button className="button primary" disabled={!content} onClick={copy}>{copied ? <Check size={14} /> : <Copy size={14} />}{copied ? 'Copied' : 'Copy code'}</button></div>
  </Dialog>
}
