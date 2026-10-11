import { test } from 'node:test'
import assert from 'node:assert/strict'
import { calculateStreak, calculateRhythm, calculateVelocity } from '../src/services/analytics.js'
const calendar = days => ({ weeks: [{ contributionDays: days.map(([date, contributionCount]) => ({ date, contributionCount })) }] })
test('streak deduplicates dates, fills momentum gaps and preserves yesterday grace', () => {
  const data = calculateStreak('dev', [calendar([['2026-10-08', 2], ['2026-10-09', 3], ['2026-10-10', 0]]), calendar([['2026-10-09', 3], ['2026-10-12', 99]])], new Date('2026-10-10T12:00:00Z'))
  assert.equal(data.total_contributions, 5)
  assert.equal(data.current_streak, 2)
  assert.equal(data.longest_streak, 2)
  assert.deepEqual(data.recent_14_days.slice(-3), [2, 3, 0])
})
test('missing calendar dates break streaks; empty data stays empty', () => {
  const data = calculateStreak('dev', [calendar([['2026-10-07', 1], ['2026-10-09', 1]])], new Date('2026-10-10'))
  assert.equal(data.longest_streak, 1)
  assert.equal(data.current_streak, 1)
  assert.equal(calculateStreak('dev', [], new Date('2026-10-10')).total_contributions, 0)
})
test('fractional timezone crosses midnight and ignores other known authors', () => {
  const commits = [{ committedDate: '2026-10-10T23:45:00Z', author: { user: { login: 'Dev' } } }, { committedDate: '2026-10-10T23:45:00Z', author: { user: { login: 'other' } } }]
  const rhythm = calculateRhythm('dev', commits, 5.5)
  assert.equal(rhythm.matrix[6][5], 1)
  assert.equal(rhythm.total_commits, 1)
  assert.equal(calculateRhythm('dev', []).persona_title, 'No commit activity')
})
test('no merged PRs show N/A; code churn uses sampled PRs', () => {
  assert.equal(calculateVelocity('dev', {}).turnaround_str, 'N/A')
  const velocity = calculateVelocity('dev', { pullRequests: { totalCount: 2, nodes: [{ createdAt: '2026-10-09T00:00:00Z', mergedAt: '2026-10-10T00:00:00Z', additions: 10 }] }, mergedPRs: { totalCount: 1 } })
  assert.equal(velocity.merge_rate, 50)
  assert.equal(velocity.avg_turnaround_hours, 24)
  assert.equal(velocity.total_additions, 10)
})
