import test from 'node:test'
import assert from 'node:assert/strict'
import { aggregateLanguages, commitWorkflow, fetchUserData } from '../src/services/githubApi.js'

function mockFetch(t, responses) {
  const calls = []
  t.mock.method(globalThis, 'fetch', async (url, options = {}) => {
    calls.push({ url, ...options, body: options.body && JSON.parse(options.body) })
    assert.ok(responses.length, `Unexpected request: ${url}`)
    const [status, body] = responses.shift()
    return new Response(status === 204 ? null : JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } })
  })
  return calls
}

test('public data reports availability honestly and aggregates byte counts', async t => {
  const calls = mockFetch(t, [[200, { type: 'User', login: 'octocat' }], [200, [{ name: 'one', fork: false }, { name: 'fork', fork: true }]], [200, { Zig: 20, Rust: 10 }]])
  const data = await fetchUserData('octocat')
  assert.deepEqual(data.available, ['languages', 'radar'])
  assert.equal(data.metrics, undefined)
  assert.equal(data.languages[0].size, 20)
  assert.equal(calls.length, 3)
  assert.equal(await fetchUserData('octocat'), data, 'Repeated public loads use the short memory cache')
  assert.equal(calls.length, 3)
})

test('empty authenticated accounts preserve zeros across every card', async t => {
  const totalCount = 0
  mockFetch(t, [[200, { data: { user: {
    login: 'new-user', repositories: { totalCount, nodes: [] }, languageRepositories: { nodes: [] }, historyRepositories: { nodes: [] },
    pullRequests: { totalCount, nodes: [] }, mergedPRs: { totalCount }, openPRs: { totalCount }, closedPRs: { totalCount }, closedIssues: { totalCount },
    contributionsCollection: { contributionYears: [], totalCommitContributions: 0, restrictedContributionsCount: 0, totalPullRequestContributions: 0, totalIssueContributions: 0, totalRepositoriesWithContributedCommits: 0, totalPullRequestReviewContributions: 0 },
  } } }]])
  const data = await fetchUserData('new-user', 'test-read-token')
  assert.equal(data.available.length, 7)
  assert.equal(data.metrics.commits, 0)
  assert.equal(data.streak.total_contributions, 0)
  assert.equal(data.rhythm.total_commits, 0)
  assert.equal(data.rhythm.persona_title, 'No commit activity')
  assert.equal(data.velocity.turnaround_str, 'N/A')
  assert.equal(data.velocity.velocity_score, 0)
  assert.deepEqual(data.languages, [])
})

test('rejected tokens and GraphQL errors never substitute demo data', async t => {
  mockFetch(t, [[401, {}], [200, { errors: [{ message: 'Token cannot read this field' }] }]])
  await assert.rejects(fetchUserData('octocat', 'test-token'), /rejected this token/)
  await assert.rejects(fetchUserData('octocat', 'test-token'), /cannot read this field/)
})

test('commit updates the profile repository workflow on its default branch', async t => {
  const calls = mockFetch(t, [[200, { default_branch: 'trunk', permissions: { push: true } }], [200, { sha: 'existing-sha' }], [200, {}], [403, {}]])
  const result = await commitWorkflow({ username: 'octocat', pat: 'test-token', yamlContent: 'name: Profile\n' })
  assert.equal(result.committed, true)
  assert.match(calls[0].url, /\/repos\/octocat\/octocat$/)
  assert.match(calls[1].url, /\/contents\/\.github\/workflows\/gitstats\.yml\?ref=trunk$/)
  assert.equal(calls[2].method, 'PUT')
  assert.equal(calls[2].body.sha, 'existing-sha')
  assert.equal(calls[2].body.branch, 'trunk')
  assert.equal(atob(calls[2].body.content), 'name: Profile\n')
  assert.deepEqual(calls[3].body, { ref: 'trunk' }, 'A failed dispatch is not fatal; the push trigger runs it')
})

test('commit creates a missing workflow and refuses read-only tokens before writing', async t => {
  const calls = mockFetch(t, [[200, { default_branch: 'main', permissions: { push: false } }], [404, {}], [200, { default_branch: 'main', permissions: { push: true } }], [404, {}], [201, {}], [204, null]])
  const args = { username: 'octocat', pat: 'test-token', yamlContent: 'name: Test' }
  await assert.rejects(commitWorkflow(args), /cannot write/)
  assert.equal(calls.some(c => c.method === 'PUT'), false)
  assert.equal((await commitWorkflow(args)).committed, true)
  assert.equal('sha' in calls.find(c => c.method === 'PUT').body, false)
})

test('language aggregation rejects invalid colors, negative bytes, and missing names', () => {
  const result = aggregateLanguages([{ languages: { edges: [{ size: 20, node: { name: 'Zig', color: 'url(evil)' } }, { size: -1, node: { name: 'Rust' } }, { size: 5, node: {} }] } }])
  assert.deepEqual(result, [{ name: 'Zig', size: 20, percentage: 0, color: '#ec915c' }])
})

test('public language colors come from GitHub Linguist, including languages absent from the native aliases', () => {
  const result = aggregateLanguages([{ languages: { edges: ['Jupyter Notebook', 'Haskell', 'Shell', 'QML', 'Unknown'].map(name => ({ size: 1, node: { name } })) } }])
  assert.deepEqual(result.map(l => l.color), ['#DA5B0B', '#5e5086', '#89e051', '#44a51c', '#586069'])
})

test('workflow permission failure never dispatches or reports a successful commit', async t => {
  const calls = mockFetch(t, [[200, { default_branch: 'main', permissions: { push: true } }], [200, { sha: 'old' }], [403, {}]])
  await assert.rejects(commitWorkflow({ username: 'octocat', pat: 'test-token', yamlContent: 'name: Test' }), /Contents and Workflows write/)
  assert.equal(calls.some(c => c.url.includes('/dispatches')), false)
})

test('a concurrent workflow update has an actionable error and never dispatches', async t => {
  const calls = mockFetch(t, [[200, { default_branch: 'main', permissions: { push: true } }], [200, { sha: 'old' }], [409, {}]])
  await assert.rejects(commitWorkflow({ username: 'octocat', pat: 'test-token', yamlContent: 'name: Test' }), /changed while/)
  assert.equal(calls.some(c => c.url.includes('/dispatches')), false)
})
