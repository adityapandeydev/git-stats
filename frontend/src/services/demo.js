import { calculateRhythm, calculateStreak, calculateVelocity } from './analytics.js'

// Deterministic sample, explicitly labeled in the workspace; never substituted for live metrics.
const now = new Date('2026-10-11T12:00:00Z')
const contributionDays = Array.from({ length: 366 }, (_, i) => ({ date: new Date(now.getTime() - (365 - i) * 86400000).toISOString().slice(0, 10), contributionCount: i > 323 || i % 73 > 4 ? (i * 7 % 17) + 1 : 0 }))
const commits = Array.from({ length: 200 }, (_, i) => ({ committedDate: new Date(now.getTime() - i * 1700000).toISOString(), author: { user: { login: 'demo' } } }))
const languages = [['Zig', '#ec915c', 28500], ['Rust', '#dea584', 18200], ['Go', '#00ADD8', 14800], ['TypeScript', '#3178c6', 11100], ['Python', '#3572a5', 7400], ['C', '#555555', 5200], ['C++', '#f34b7d', 4100], ['JavaScript', '#f1e05a', 3200], ['HTML', '#e34c26', 2100], ['CSS', '#563d7c', 1800], ['Shell', '#89e051', 1200], ['Lua', '#000080', 900], ['Dockerfile', '#384d54', 600], ['Swift', '#F05138', 400], ['Kotlin', '#A97BFF', 300], ['Ruby', '#701516', 200]].map(([name, color, size]) => ({ name, color, size, percentage: 0 }))
export const DEMO_DATA = {
  login: 'demo', name: 'Sample developer', source: 'demo', fetchedAt: null,
  languages, commits, streak: calculateStreak('demo', [{ weeks: [{ contributionDays }] }], now),
  rhythm: calculateRhythm('demo', commits),
  metrics: { commits: 2840, total_prs: 72, merged_prs: 64, closed_issues: 18, stars: 520, contributed_repos: 32, repos: 32 },
  yearMetrics: { commits: 480, total_prs: 72, merged_prs: 64, closed_issues: 18, stars: 520, contributed_repos: 32, repos: 32 },
  velocity: calculateVelocity('demo', { pullRequests: { totalCount: 72, nodes: [{ createdAt: '2026-10-10T00:00:00Z', mergedAt: '2026-10-10T18:30:00Z', additions: 42800, deletions: 14300, changedFiles: 186 }] }, mergedPRs: { totalCount: 64 }, openPRs: { totalCount: 5 }, closedPRs: { totalCount: 3 }, contributionsCollection: { totalPullRequestReviewContributions: 24 } }),
  available: ['languages', 'streak', 'stats', 'rhythm', 'radar', 'velocity', 'milestones'],
  notes: ['Sample data for exploring the design. Load a GitHub profile to use real data.'],
}
