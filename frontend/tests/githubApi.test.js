import test from 'node:test'
import assert from 'node:assert/strict'
import { aggregateLanguages, fetchUserData, syncWorkflowToFork } from '../src/services/githubApi.js'

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

test('sync updates the chosen branch with its SHA and reports dispatch failure separately', async t => {
  const calls = mockFetch(t, [[200, { default_branch: 'main', permissions: { push: true } }], [200, {}], [200, { sha: 'branch-specific-sha' }], [200, {}], [403, {}]])
  const result = await syncWorkflowToFork({ username: 'octocat', pat: 'test-token', yamlContent: 'name: Profile\n', target: { owner: 'example', repo: 'cards', branch: 'profile/test' } })
  assert.equal(result.committed, true)
  assert.equal(result.dispatched, false)
  assert.match(calls[2].url, /ref=profile%2Ftest$/)
  assert.equal(calls[3].body.sha, 'branch-specific-sha')
  assert.equal(calls[3].body.branch, 'profile/test')
  assert.equal(atob(calls[3].body.content), 'name: Profile\n')
  assert.deepEqual(calls[4].body, { ref: 'profile/test' })
})

test('sync creates missing files and refuses read-only destinations before writing', async t => {
  const calls = mockFetch(t, [[200, { permissions: { push: false } }], [200, {}], [404, {}], [200, { permissions: { push: true } }], [200, {}], [404, {}], [201, {}], [204, null]])
  const args = { username: 'octocat', pat: 'test-token', yamlContent: 'name: Test', target: { branch: 'main' } }
  await assert.rejects(syncWorkflowToFork(args), /cannot write/)
  assert.equal(calls.some(c => c.method === 'PUT'), false)
  assert.equal((await syncWorkflowToFork(args)).dispatched, true)
  assert.equal('sha' in calls.find(c => c.method === 'PUT').body, false)
})

test('language aggregation rejects invalid colors, negative bytes, and missing names', () => {
  const result = aggregateLanguages([{ languages: { edges: [{ size: 20, node: { name: 'Zig', color: 'url(evil)' } }, { size: -1, node: { name: 'Rust' } }, { size: 5, node: {} }] } }])
  assert.deepEqual(result, [{ name: 'Zig', size: 20, percentage: 0, color: '#7aa2f7' }])
})
