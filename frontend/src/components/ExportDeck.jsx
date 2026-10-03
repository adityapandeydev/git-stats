import React, { useState } from 'react'
import { Copy, Check, Download, ExternalLink, Code2, FileCode } from 'lucide-react'
import { getGitHubWebEditUrl } from '../services/compiler'

export default function ExportDeck({
  htmlCode,
  yamlCode,
  username,
}) {
  const [activeTab, setActiveTab] = useState('html') // 'html' | 'yaml'
  const [copied, setCopied] = useState(false)

  const activeContent = activeTab === 'html' ? htmlCode : yamlCode

  const handleCopy = () => {
    navigator.clipboard.writeText(activeContent)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  const handleDownload = () => {
    const filename = activeTab === 'html' ? 'profile-stats.html' : 'generate-stats.yml'
    const blob = new Blob([activeContent], { type: 'text/plain;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = filename
    link.click()
    URL.revokeObjectURL(url)
  }

  const webEditUrl = getGitHubWebEditUrl(username)

  return (
    <div className="glass-panel rounded-xl p-4 flex flex-col gap-3">
      {/* Deck Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-2 border-b border-[#24283b]">
        {/* Tabs */}
        <div className="flex items-center gap-1.5 bg-[#161826] p-1 rounded-lg border border-[#24283b]">
          <button
            onClick={() => setActiveTab('html')}
            className={`flex items-center gap-1.5 px-3 py-1 rounded text-xs font-semibold transition-all cursor-pointer ${
              activeTab === 'html'
                ? 'bg-[#7aa2f7] text-[#090a0f] shadow-sm'
                : 'text-[#7982a9] hover:text-white'
            }`}
          >
            <Code2 className="w-3.5 h-3.5" />
            <span>Profile HTML</span>
          </button>

          <button
            onClick={() => setActiveTab('yaml')}
            className={`flex items-center gap-1.5 px-3 py-1 rounded text-xs font-semibold transition-all cursor-pointer ${
              activeTab === 'yaml'
                ? 'bg-[#7aa2f7] text-[#090a0f] shadow-sm'
                : 'text-[#7982a9] hover:text-white'
            }`}
          >
            <FileCode className="w-3.5 h-3.5" />
            <span>Workflow YAML</span>
          </button>
        </div>

        {/* Action Buttons (Zero emojis, 100% SVG icons) */}
        <div className="flex items-center gap-2">
          {activeTab === 'yaml' && (
            <a
              href={webEditUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg border border-[#24283b] hover:border-[#7aa2f7]/50 bg-[#161826] text-[11px] font-semibold text-[#c0caf5] transition-all hover:text-white cursor-pointer"
              title="Open directly in GitHub's in-browser editor"
            >
              <ExternalLink className="w-3 h-3 text-[#7aa2f7]" />
              <span className="hidden sm:inline">Edit in GitHub</span>
            </a>
          )}

          <button
            onClick={handleDownload}
            className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg border border-[#24283b] hover:border-[#7aa2f7]/50 bg-[#161826] text-[11px] font-semibold text-[#c0caf5] transition-all hover:text-white cursor-pointer"
            title="Download file"
          >
            <Download className="w-3 h-3 text-[#7aa2f7]" />
            <span className="hidden sm:inline">Download</span>
          </button>

          <button
            onClick={handleCopy}
            className={`flex items-center gap-1.5 px-3 py-1 rounded-lg text-xs font-bold transition-all cursor-pointer ${
              copied
                ? 'bg-[#73daca] text-[#090a0f]'
                : 'bg-[#7aa2f7] hover:bg-[#70a5fd] text-[#090a0f] shadow-sm active:scale-95'
            }`}
          >
            {copied ? (
              <>
                <Check className="w-3.5 h-3.5" strokeWidth={3} />
                <span>Copied!</span>
              </>
            ) : (
              <>
                <Copy className="w-3.5 h-3.5" />
                <span>Copy Code</span>
              </>
            )}
          </button>
        </div>
      </div>

      {/* Code Display Area */}
      <div className="relative">
        <pre className="w-full max-h-60 overflow-x-auto overflow-y-auto p-3.5 rounded-lg bg-[#0e1017] border border-[#24283b] font-mono text-[11px] text-[#c0caf5] leading-relaxed select-all">
          {activeContent}
        </pre>
      </div>
      <p className="text-[10px] text-[#7982a9] italic">
        {activeTab === 'html'
          ? 'Paste this snippet directly into your personal username/README.md on GitHub.'
          : 'Place this YAML into .github/workflows/generate-stats.yml in your forked git-stats repository.'}
      </p>
    </div>
  )
}
