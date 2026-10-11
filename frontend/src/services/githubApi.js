import { validateTarget } from './compiler.js'
import { calculateStreak, calculateRhythm, calculateVelocity } from './analytics.js'
import { LANGUAGE_COLORS, DEFAULT_LANGUAGE_COLOR } from '../constants/languageColors.js'

const api = 'https://api.github.com'
const path = '.github/workflows/generate-stats.yml'
const safeColor = (value, name) => /^#[\da-f]{6}$/i.test(value || '') ? value : LANGUAGE_COLORS[name.toLowerCase()] || DEFAULT_LANGUAGE_COLOR

async function request(url, { token = '', signal, ...options } = {}) {
  const response = await fetch(url, { ...options, signal, headers: { Accept: 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28', ...(token ? { Authorization: `Bearer ${token}` } : {}), ...options.headers } })
  if (response.status === 204) return null
  const json = await response.json().catch(() => ({}))
  if (!response.ok) {
    const reset = Number(response.headers.get('x-ratelimit-reset'))
    const message = response.status === 404 ? 'GitHub could not find this profile or repository.' : response.status === 401 ? 'GitHub rejected this token.' : response.status === 403 || response.status === 429 ? `GitHub denied access or reached its rate limit.${reset ? ` Try again after ${new Date(reset * 1000).toLocaleTimeString()}.` : ''}` : json.message || `GitHub request failed (${response.status}).`
    throw Object.assign(new Error(message), { status: response.status })
  }
  return json
}

async function graphql(query, username, token, signal) {
  const json = await request(`${api}/graphql`, { token, signal, method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ query, variables: { login: username } }) })
  if (json.errors?.length) throw new Error(json.errors.map(e => e.message).join(' '))
  if (!json.data?.user) throw new Error('GitHub user not found. Organization profiles are not supported.')
  return json.data.user
}

export function aggregateLanguages(repositories) {
  const map = new Map()
  for (const repo of repositories) {
    for (const { size, node } of repo.languages?.edges || []) {
      if (!node?.name || !Number.isFinite(size) || size < 0) continue
      const current = map.get(node.name) || { name: node.name, color: safeColor(node.color, node.name), size: 0, percentage: 0 }
      current.size += size; map.set(node.name, current)
    }
  }
  return [...map.values()].sort((a, b) => b.size - a.size)
}

const profileCache = new Map()
export async function fetchUserData(username, token = '', { signal, force = false } = {}) {
  const user = validateTarget(username).username.toLowerCase()
  if (signal?.aborted) throw new DOMException('Request aborted', 'AbortError')
  const cached = profileCache.get(user)
  if (!force && cached?.token === token.trim() && Date.now() - cached.data.fetchedAt < 60000) return cached.data
  const data = await fetchFreshUserData(username, token, signal)
  if (!signal?.aborted) {
    profileCache.delete(user)
    profileCache.set(user, { token: token.trim(), data })
    if (profileCache.size > 3) profileCache.delete(profileCache.keys().next().value)
  }
  return data
}

async function fetchFreshUserData(username, token, signal) {
  const user = validateTarget(username).username
  const encoded = encodeURIComponent(user)
  if (!token.trim()) {
    const profile = await request(`${api}/users/${encoded}`, { signal })
    if (profile.type !== 'User') throw new Error('Enter a personal GitHub account, rather than an organization.')
    const repos = await request(`${api}/users/${encoded}/repos?per_page=100&sort=pushed&type=owner`, { signal })
    // Bound unauthenticated requests to avoid spending the entire 60/hour budget on one load.
    const sampled = repos.filter(r => !r.fork).slice(0, 20)
    const languages = []
    // Four at a time; failures remain visible rather than replacing results with samples.
    for (let i = 0; i < sampled.length; i += 4) {
      const batch = await Promise.all(sampled.slice(i, i + 4).map(async repo => {
        const data = await request(`${api}/repos/${encoded}/${encodeURIComponent(repo.name)}/languages`, { signal })
        return { name: repo.name, languages: { edges: Object.entries(data).map(([name, size]) => ({ size, node: { name, color: LANGUAGE_COLORS[name.toLowerCase()] } })) } }
      }))
      languages.push(...batch)
    }
    return { login: profile.login, name: profile.name || profile.login, avatarUrl: profile.avatar_url, source: 'public', fetchedAt: Date.now(), repositories: languages, languages: aggregateLanguages(languages), available: ['languages', 'radar'],
      notes: [`Public preview: language bytes from ${sampled.length} recently pushed, non-fork repositories (maximum 20). Connect a read token for contribution and PR cards.`, 'The authenticated CLI can see different repositories, depending on token access.'] }
  }
  const query = `query($login: String!) { user(login: $login) {
    login name avatarUrl createdAt
    repositories(first:100, ownerAffiliations:OWNER, isFork:false) { totalCount nodes { name stargazerCount languages(first:10,orderBy:{field:SIZE,direction:DESC}) { edges { size node { name color } } } } }
    languageRepositories: repositories(first:100, affiliations:[OWNER,ORGANIZATION_MEMBER], isFork:false,orderBy:{field:PUSHED_AT,direction:DESC}) { nodes { name languages(first:20,orderBy:{field:SIZE,direction:DESC}) { edges { size node { name color } } } } }
    historyRepositories: repositories(first:20,ownerAffiliations:OWNER,orderBy:{field:PUSHED_AT,direction:DESC}) { nodes { defaultBranchRef { target { ... on Commit { history(first:100) { nodes { committedDate author { user { login } } } } } } } } }
    pullRequests(first:30,orderBy:{field:CREATED_AT,direction:DESC}) { totalCount nodes { createdAt mergedAt additions deletions changedFiles } }
    mergedPRs: pullRequests(states:MERGED) { totalCount }
    openPRs: pullRequests(states:OPEN) { totalCount }
    closedPRs: pullRequests(states:CLOSED) { totalCount }
    closedIssues: issues(states:CLOSED) { totalCount }
    contributionsCollection { contributionYears totalCommitContributions restrictedContributionsCount totalPullRequestContributions totalIssueContributions totalRepositoriesWithContributedCommits totalPullRequestReviewContributions }
  } }`
  const u = await graphql(query, user, token.trim(), signal)
  const years = [...new Set(u.contributionsCollection.contributionYears)].sort()
  const yearCollections = []
  for (let i = 0; i < years.length; i += 5) {
    const fields = years.slice(i, i + 5).map(year => `y${Number(year)}: contributionsCollection(from:"${Number(year)}-01-01T00:00:00Z",to:"${Number(year)}-12-31T23:59:59Z") { totalCommitContributions restrictedContributionsCount contributionCalendar { weeks { contributionDays { date contributionCount } } } }`).join('\n')
    const result = await graphql(`query($login:String!) { user(login:$login) { ${fields} } }`, user, token.trim(), signal)
    yearCollections.push(...Object.values(result))
  }
  const collection = u.contributionsCollection
  const owned = u.repositories.nodes
  const metrics = {
    commits: yearCollections.length > 1 ? yearCollections.reduce((s, c) => s + c.totalCommitContributions + c.restrictedContributionsCount, 0) : collection.totalCommitContributions + collection.restrictedContributionsCount,
    total_prs: Math.max(u.pullRequests.totalCount, u.mergedPRs.totalCount, collection.totalPullRequestContributions),
    merged_prs: Math.max(u.mergedPRs.totalCount, collection.totalPullRequestContributions),
    closed_issues: Math.max(u.closedIssues.totalCount, collection.totalIssueContributions),
    contributed_repos: Math.max(collection.totalRepositoriesWithContributedCommits, u.repositories.totalCount), repos: u.repositories.totalCount,
    stars: owned.reduce((s, r) => s + r.stargazerCount, 0),
  }
  const commits = u.historyRepositories.nodes.flatMap(r => r.defaultBranchRef?.target?.history?.nodes || [])
  const languages = aggregateLanguages(u.languageRepositories.nodes)
  return { login: u.login, name: u.name || u.login, avatarUrl: u.avatarUrl, source: 'authenticated', fetchedAt: Date.now(), repositories: u.languageRepositories.nodes,
    milestoneLanguages: aggregateLanguages(owned), milestoneMetrics: { ...metrics, merged_prs: u.mergedPRs.totalCount }, languages, metrics,
    yearMetrics: { ...metrics, commits: collection.totalCommitContributions + collection.restrictedContributionsCount },
    streak: calculateStreak(u.login, yearCollections.map(c => c.contributionCalendar)),
    commits, rhythm: calculateRhythm(u.login, commits), velocity: calculateVelocity(u.login, u), available: ['languages', 'streak', 'stats', 'rhythm', 'radar', 'velocity', 'milestones'],
    notes: ['Matches native query limits: languages up to 100 repositories; rhythm up to 20 repositories × 100 commits; PR turnaround and churn from the latest 30 PRs. Results depend on token visibility.', 'Stats “this year” follows the native engine’s default contribution collection (the last 12 months). Tier percentiles are engine labels, not measured global rankings.'] }
}


export async function inspectRepository(username, token, target = {}, signal) {
  const destination = validateTarget(username, target)
  const base = `${api}/repos/${destination.owner}/${destination.repo}`
  const repository = await request(base, { token, signal })
  const branch = target.branch?.trim() || repository.default_branch
  await request(`${base}/branches/${encodeURIComponent(branch)}`, { token, signal })
  let file = null
  try { file = await request(`${base}/contents/${path}?ref=${encodeURIComponent(branch)}`, { token, signal }) }
  catch (error) { if (error.status !== 404) throw error }
  return { ...destination, branch, file, canPush: repository.permissions?.push !== false, actionsUrl: `https://github.com/${destination.owner}/${destination.repo}/actions` }
}

export async function syncWorkflowToFork({ username, pat, yamlContent, target = {} }) {
  if (!pat.trim()) throw new Error('A token is required for direct sync.')
  if (!yamlContent?.trim()) throw new Error('Generate a valid workflow before syncing.')
  const destination = await inspectRepository(username, pat.trim(), target)
  if (!destination.canPush) throw new Error('This token cannot write to the selected repository.')
  const base = `${api}/repos/${destination.owner}/${destination.repo}`
  const bytes = new TextEncoder().encode(yamlContent)
  const content = btoa(Array.from(bytes, byte => String.fromCharCode(byte)).join(''))
  await request(`${base}/contents/${path}`, { token: pat.trim(), method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ message: 'chore(stats): configure profile with GitStats Studio', branch: destination.branch, content, ...(destination.file ? { sha: destination.file.sha } : {}) }) })
  try {
    await request(`${base}/actions/workflows/generate-stats.yml/dispatches`, { token: pat.trim(), method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ ref: destination.branch }) })
    return { committed: true, dispatched: true, actionsUrl: destination.actionsUrl }
  } catch (error) {
    return { committed: true, dispatched: false, actionsUrl: destination.actionsUrl, message: `Workflow committed. Immediate dispatch failed: ${error.message} Open Actions to enable or run it.` }
  }
}
