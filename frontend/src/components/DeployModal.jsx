import React, { useState } from 'react'
import { X, GitFork, KeyRound, ExternalLink, CheckCircle2, AlertCircle, Loader2, ShieldCheck } from 'lucide-react'
import { syncWorkflowToFork } from '../services/githubApi'
import { getGitHubWebEditUrl } from '../services/compiler'

export default function DeployModal({
  isOpen,
  onClose,
  username,
  yamlContent,
}) {
  if (!isOpen) return null

  const [pat, setPat] = useState(() => sessionStorage.getItem('gitstats_temp_pat') || '')
  const [syncStatus, setSyncStatus] = useState('idle') // 'idle' | 'syncing' | 'success' | 'error'
  const [errorMessage, setErrorMessage] = useState('')

  const handleSync = async () => {
    if (!username.trim()) {
      setErrorMessage('Please provide your GitHub username.')
      setSyncStatus('error')
      return
    }
    if (!pat.trim()) {
      setErrorMessage('Please enter your Personal Access Token (PAT).')
      setSyncStatus('error')
      return
    }

    try {
      setSyncStatus('syncing')
      setErrorMessage('')
      // Store temporarily in session
      sessionStorage.setItem('gitstats_temp_pat', pat.trim())

      await syncWorkflowToFork({
        username: username.trim(),
        pat: pat.trim(),
        yamlContent,
      })

      setSyncStatus('success')
    } catch (err) {
      setSyncStatus('error')
      setErrorMessage(err.message || 'Failed to sync workflow.')
    }
  }

  const webEditUrl = getGitHubWebEditUrl(username)

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-fade-in">
      <div className="glass-panel w-full max-w-xl rounded-2xl p-6 border border-[#24283b] shadow-2xl relative flex flex-col gap-5 max-h-[90vh] overflow-y-auto">
        {/* Modal Header */}
        <div className="flex items-center justify-between pb-3 border-b border-[#24283b]">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-[#7aa2f7]/15 border border-[#7aa2f7]/30 flex items-center justify-center">
              <GitFork className="w-4 h-4 text-[#7aa2f7]" />
            </div>
            <div>
              <h2 className="text-sm font-bold text-white tracking-tight">Deploy to Your Fork</h2>
              <p className="text-[11px] text-[#7982a9]">Choose your preferred method to apply your layout</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded-lg text-[#7982a9] hover:text-white hover:bg-[#1f2335] transition-colors cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Path A: 1-Click Fork Sync */}
        <div className="rounded-xl p-4 bg-[#121420]/80 border border-[#24283b] flex flex-col gap-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="w-5 h-5 rounded-full bg-[#7aa2f7] text-[#090a0f] text-[11px] font-extrabold flex items-center justify-center">
                A
              </span>
              <h3 className="text-xs font-bold text-white tracking-tight">1-Click Direct Sync</h3>
            </div>
            <span className="text-[10px] font-semibold text-[#73daca] bg-[#73daca]/10 px-2 py-0.5 rounded-full border border-[#73daca]/20">
              Zero Terminal
            </span>
          </div>

          <p className="text-[11px] text-[#7982a9] leading-relaxed">
            Provide a temporary fine-grained Personal Access Token with <code className="text-[#c0caf5]">contents:write</code> & <code className="text-[#c0caf5]">actions:write</code> on your <code className="text-[#c0caf5]">git-stats</code> fork.
          </p>

          <div className="relative">
            <KeyRound className="w-4 h-4 text-[#565f89] absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="password"
              value={pat}
              onChange={(e) => setPat(e.target.value)}
              placeholder="github_pat_..."
              className="w-full glass-input text-xs text-white rounded-lg pl-9 pr-3 py-2 font-mono placeholder-[#565f89]"
            />
          </div>

          <div className="flex items-center justify-between pt-1">
            <div className="flex items-center gap-1.5 text-[10px] text-[#7982a9]">
              <ShieldCheck className="w-3.5 h-3.5 text-[#73daca]" />
              <span>Token remains in your browser session only. Never stored remotely.</span>
            </div>

            <button
              onClick={handleSync}
              disabled={syncStatus === 'syncing'}
              className="flex items-center gap-2 px-3.5 py-1.5 rounded-lg bg-[#7aa2f7] hover:bg-[#70a5fd] disabled:opacity-50 text-[#090a0f] text-xs font-bold transition-all shadow-md active:scale-95 cursor-pointer"
            >
              {syncStatus === 'syncing' ? (
                <>
                  <Loader2 className="w-3.5 h-3.5 animate-spin" />
                  <span>Syncing...</span>
                </>
              ) : (
                <>
                  <GitFork className="w-3.5 h-3.5" />
                  <span>Sync to Fork</span>
                </>
              )}
            </button>
          </div>

          {/* Sync Status Banner */}
          {syncStatus === 'success' && (
            <div className="mt-2 p-2.5 rounded-lg bg-[#73daca]/10 border border-[#73daca]/30 text-xs text-[#73daca] flex items-center gap-2">
              <CheckCircle2 className="w-4 h-4 shrink-0" />
              <span>Workflow successfully committed and GitHub Actions bot triggered!</span>
            </div>
          )}
          {syncStatus === 'error' && (
            <div className="mt-2 p-2.5 rounded-lg bg-[#f7768e]/10 border border-[#f7768e]/30 text-xs text-[#f7768e] flex items-center gap-2">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{errorMessage}</span>
            </div>
          )}
        </div>

        {/* Path B: Zero-Token Web Editor */}
        <div className="rounded-xl p-4 bg-[#121420]/80 border border-[#24283b] flex flex-col gap-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="w-5 h-5 rounded-full bg-[#565f89] text-white text-[11px] font-extrabold flex items-center justify-center">
                B
              </span>
              <h3 className="text-xs font-bold text-white tracking-tight">Zero-Token Web Editor</h3>
            </div>
            <span className="text-[10px] font-semibold text-[#7982a9] bg-[#24283b] px-2 py-0.5 rounded-full">
              No Token Required
            </span>
          </div>

          <p className="text-[11px] text-[#7982a9] leading-relaxed">
            If you don't want to enter a token, you can paste the YAML straight into GitHub's web file editor:
          </p>

          <ol className="text-[11px] text-[#c0caf5] space-y-1 list-decimal list-inside bg-[#0e1017] p-3 rounded-lg border border-[#24283b]">
            <li>Copy the <strong>Workflow YAML</strong> from the code deck below.</li>
            <li>Click the link below to open the workflow file in your fork.</li>
            <li>Paste the YAML and click <strong>Commit changes</strong>.</li>
          </ol>

          <div className="flex justify-end pt-1">
            <a
              href={webEditUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-[#24283b] hover:border-[#7aa2f7]/50 bg-[#161826] text-xs font-semibold text-[#c0caf5] hover:text-white transition-all cursor-pointer"
            >
              <ExternalLink className="w-3.5 h-3.5 text-[#7aa2f7]" />
              <span>Open in GitHub Web Editor</span>
            </a>
          </div>
        </div>
      </div>
    </div>
  )
}
