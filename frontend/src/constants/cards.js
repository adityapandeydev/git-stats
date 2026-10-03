export const CARD_DEFINITIONS = [
  {
    id: 'milestones',
    name: 'Career Milestones',
    flag: '--milestones',
    description: 'All 6 achievement trophies with rank crown (Supports Hero 840px and Standard 424px).',
    defaultWidth: 840,
    defaultHeight: 180,
    minWidth: 424,
    maxWidth: 840,
    isHeroCapable: true,
    canFloatRight: false,
  },
  {
    id: 'streak',
    name: 'Commit Streak',
    flag: '--streak',
    description: 'Active streak, flame aura, longest streak, and 14-day momentum sparkline.',
    defaultWidth: 424,
    defaultHeight: 180,
    minWidth: 424,
    maxWidth: 840,
    supportsSparkline: true,
    isHeroCapable: true,
    canFloatRight: false,
  },
  {
    id: 'stats',
    name: 'Developer Stats',
    flag: '--stats',
    description: 'Radial rating ring, grade percentile, commits, PRs, stars, and repos.',
    defaultWidth: 424,
    defaultHeight: 180,
    minWidth: 424,
    maxWidth: 840,
    supportsTimeframe: true,
    isHeroCapable: true,
    canFloatRight: false,
  },
  {
    id: 'rhythm',
    name: 'Commit Rhythm',
    flag: '--rhythm',
    description: '24h × 7d punchcard heatmap, circadian split, peak window, and persona badge.',
    defaultWidth: 424,
    defaultHeight: 180,
    minWidth: 424,
    maxWidth: 840,
    isHeroCapable: true,
    canFloatRight: false,
  },
  {
    id: 'radar',
    name: 'Developer DNA',
    flag: '--radar',
    description: '5-Axis polyglot radar mapping Systems, Backend, Frontend, DevOps, and Data.',
    defaultWidth: 424,
    defaultHeight: 180,
    minWidth: 424,
    maxWidth: 424,
    isHeroCapable: false,
    canFloatRight: false,
  },
  {
    id: 'velocity',
    name: 'PR Velocity',
    flag: '--velocity',
    description: 'Turnaround speedometer, merge distribution, code shipped volume, and velocity index.',
    defaultWidth: 424,
    defaultHeight: 180,
    minWidth: 424,
    maxWidth: 424,
    isHeroCapable: false,
    canFloatRight: false,
  },
  {
    id: 'languages',
    name: 'Top Languages',
    flag: '--generate',
    description: 'Language breakdown with auto-recalculated percentages and dynamic card height.',
    defaultWidth: 400,
    defaultHeight: 294,
    minWidth: 400,
    maxWidth: 400,
    supportsCount: true,
    defaultLangsCount: 12,
    isHeroCapable: false,
    canFloatRight: true,
  },
]

export const DEFAULT_ACTIVE_CARDS = [
  { id: 'milestones', width: 840, height: 180, isHero: true },
  { id: 'streak', width: 424, height: 180, sparkline: true, isHero: false },
  { id: 'stats', width: 424, height: 180, timeframe: 'all-time', isHero: false },
  { id: 'languages', width: 400, height: 294, langsCount: 12, isHero: false },
]

export function getCardDef(id) {
  return CARD_DEFINITIONS.find((c) => c.id === id)
}

export function computeLanguagesHeight(langsCount) {
  const rows = Math.max(1, Math.ceil(langsCount / 2))
  return 124 + (rows - 1) * 34
}
