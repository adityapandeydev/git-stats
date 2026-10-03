import React, { useState, useEffect, useMemo } from 'react'
import Navbar from './components/Navbar'
import CardCatalog from './components/CardCatalog'
import ProfileCanvas from './components/ProfileCanvas'
import ExportDeck from './components/ExportDeck'
import DeployModal from './components/DeployModal'
import {
  DEFAULT_ACTIVE_CARDS,
  CARD_DEFINITIONS,
  getCardDef,
  computeLanguagesHeight,
} from './constants/cards'
import { generateProfileHtml, generateWorkflowYaml } from './services/compiler'
import { fetchUserData } from './services/githubApi'

export default function App() {
  const [username, setUsername] = useState('octocat')
  const [themeId, setThemeId] = useState('tokyonight')
  const [activeCards, setActiveCards] = useState(DEFAULT_ACTIVE_CARDS)
  const [layoutMode, setLayoutMode] = useState('pillar-right') // 'pillar-right' | 'flow'
  const [userData, setUserData] = useState(null)
  const [isLiveLoading, setIsLiveLoading] = useState(false)
  const [isDeployModalOpen, setIsDeployModalOpen] = useState(false)

  // Fetch user data on initial mount and when user requests refresh
  const loadUserData = async (userToFetch) => {
    setIsLiveLoading(true)
    try {
      const pat = sessionStorage.getItem('gitstats_temp_pat') || ''
      const data = await fetchUserData(userToFetch, pat)
      setUserData(data)
    } finally {
      setIsLiveLoading(false)
    }
  }

  useEffect(() => {
    // Check if username passed via URL query param: ?user=...
    const params = new URLSearchParams(window.location.search)
    const urlUser = params.get('user') || params.get('u')
    if (urlUser) {
      setUsername(urlUser)
      loadUserData(urlUser)
    } else {
      loadUserData('octocat')
    }
  }, [])

  // Card Management Handlers
  const handleToggleCard = (cardId) => {
    const exists = activeCards.some((c) => c.id === cardId)
    if (exists) {
      setActiveCards((prev) => prev.filter((c) => c.id !== cardId))
    } else {
      const def = getCardDef(cardId)
      const count = def.supportsCount ? def.defaultLangsCount : undefined
      const newCard = {
        id: cardId,
        width: def.defaultWidth,
        height: cardId === 'languages' ? computeLanguagesHeight(count) : def.defaultHeight,
        isHero: def.defaultWidth >= 700,
        ...(def.supportsCount ? { langsCount: count } : {}),
        ...(def.supportsSparkline ? { sparkline: true } : {}),
      }
      setActiveCards((prev) => [...prev, newCard])
    }
  }

  const handleUpdateCardProp = (cardId, prop, value) => {
    setActiveCards((prev) =>
      prev.map((c) => {
        if (c.id !== cardId) return c
        const updated = { ...c, [prop]: value }
        if (cardId === 'languages' && prop === 'langsCount') {
          updated.height = computeLanguagesHeight(value)
        }
        if (prop === 'width') {
          updated.isHero = Number(value) >= 700
        }
        return updated
      })
    )
  }

  const handleMoveCard = (index, delta) => {
    const newIndex = index + delta
    if (newIndex < 0 || newIndex >= activeCards.length) return
    const updated = [...activeCards]
    const [moved] = updated.splice(index, 1)
    updated.splice(newIndex, 0, moved)
    setActiveCards(updated)
  }

  const handleReorderCards = (newActiveCards) => {
    setActiveCards(newActiveCards)
  }

  // Reactive Compilations
  const htmlCode = useMemo(() => {
    return generateProfileHtml(username, activeCards, layoutMode)
  }, [username, activeCards, layoutMode])

  const yamlCode = useMemo(() => {
    return generateWorkflowYaml(username, activeCards, themeId)
  }, [username, activeCards, themeId])

  return (
    <div className="min-h-screen flex flex-col bg-[#090a0f] text-[#c0caf5]">
      {/* Sticky Header */}
      <Navbar
        username={username}
        setUsername={setUsername}
        themeId={themeId}
        setThemeId={setThemeId}
        isLiveLoading={isLiveLoading}
        onRefreshData={() => loadUserData(username)}
        onOpenDeploy={() => setIsDeployModalOpen(true)}
      />

      {/* Main Studio Workspace */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-4 lg:p-8 flex flex-col lg:flex-row gap-6 items-start">
        {/* Left Side: Card Catalog & Dimension Controls */}
        <div className="w-full lg:w-80 shrink-0 sticky lg:top-24">
          <CardCatalog
            activeCards={activeCards}
            onToggleCard={handleToggleCard}
            onUpdateCardProp={handleUpdateCardProp}
            onMoveCard={handleMoveCard}
          />
        </div>

        {/* Right Side: Profile Canvas Viewport & Export Deck */}
        <div className="flex-1 w-full flex flex-col gap-6">
          <ProfileCanvas
            activeCards={activeCards}
            layoutMode={layoutMode}
            setLayoutMode={setLayoutMode}
            themeId={themeId}
            userData={userData}
            onReorderCards={handleReorderCards}
            onUpdateCardProp={handleUpdateCardProp}
            onToggleCard={handleToggleCard}
          />

          <ExportDeck
            htmlCode={htmlCode}
            yamlCode={yamlCode}
            username={username}
          />
        </div>
      </main>

      {/* Deploy & Sync Modal */}
      <DeployModal
        isOpen={isDeployModalOpen}
        onClose={() => setIsDeployModalOpen(false)}
        username={username}
        yamlContent={yamlCode}
      />
    </div>
  )
}
