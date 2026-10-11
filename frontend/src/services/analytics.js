const dayMs = 86400000
const dateKey = date => date.toISOString().slice(0, 10)
const human = key => key ? new Date(`${key}T00:00:00Z`).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric', timeZone: 'UTC' }) : 'No activity'

export function calculateStreak(username, calendars, now = new Date()) {
  const today = dateKey(now)
  const counts = new Map()
  for (const day of calendars.flatMap(c => c.weeks?.flatMap(w => w.contributionDays) || [])) {
    if (day.date <= today) counts.set(day.date, Math.max(counts.get(day.date) || 0, day.contributionCount || 0))
  }
  const days = [...counts].sort(([a], [b]) => a.localeCompare(b))
  let longest = 0, run = 0, runStart = '', longestStart = '', longestEnd = '', previous = ''
  for (const [date, count] of days) {
    if (previous && Date.parse(date) - Date.parse(previous) !== dayMs) run = 0
    if (count) {
      if (!run) runStart = date
      run++
      if (run > longest) { longest = run; longestStart = runStart; longestEnd = date }
    } else run = 0
    previous = date
  }
  let end = new Date(`${today}T00:00:00Z`)
  if (!counts.get(today)) end = new Date(end.getTime() - dayMs)
  let current = 0
  let cursor = end
  while (counts.get(dateKey(cursor))) { current++; cursor = new Date(cursor.getTime() - dayMs) }
  const recent = Array.from({ length: 14 }, (_, i) => counts.get(dateKey(new Date(Date.parse(`${today}T00:00:00Z`) - (13 - i) * dayMs))) || 0)
  const active = days.filter(([, count]) => count > 0)
  return {
    username, total_contributions: days.reduce((sum, [, c]) => sum + c, 0),
    first_contribution_date: human(active[0]?.[0]), latest_contribution_date: human(active.at(-1)?.[0]),
    current_streak: current, current_streak_start: current ? human(dateKey(new Date(cursor.getTime() + dayMs))) : 'No activity',
    current_streak_end: current ? human(dateKey(end)) : 'No activity', is_streak_active: current > 0,
    longest_streak: longest, longest_streak_start: human(longestStart), longest_streak_end: human(longestEnd),
    recent_14_days: recent, max_14_day_count: Math.max(...recent), total_14_day_count: recent.reduce((s, c) => s + c, 0),
  }
}

export function calculateRhythm(username, commits, timezone = 5.5) {
  const matrix = Array.from({ length: 7 }, () => Array(24).fill(0))
  let night = 0, weekend = 0, total = 0, peak = 0, peakHour = 0, peakDay = 0
  for (const commit of commits) {
    const author = commit.author?.user?.login
    if (author && author.toLowerCase() !== username.toLowerCase()) continue
    const d = new Date(Date.parse(commit.committedDate) + timezone * 3600000)
    if (!Number.isFinite(d.getTime())) continue
    const day = (d.getUTCDay() + 6) % 7, hour = d.getUTCHours()
    const count = ++matrix[day][hour]
    total++
    if (hour >= 20 || hour < 5) night++
    if (day >= 5) weekend++
    if (count > peak) { peak = count; peakHour = hour; peakDay = day }
  }
  let best = 0, start = 0
  for (let h = 0; h < 24; h++) {
    const sum = matrix.reduce((s, row) => s + Array.from({ length: 4 }, (_, i) => row[(h + i) % 24]).reduce((a, b) => a + b, 0), 0)
    if (sum > best) { best = sum; start = h }
  }
  const persona = night / Math.max(1, total) >= .4 || peakHour >= 21 || peakHour <= 4 ? ['Night Owl', '#bb9af7'] : peakHour <= 10 ? ['Early Bird', '#e0af68'] : weekend / Math.max(1, total) >= .4 ? ['Weekend Warrior', '#f7768e'] : ['Day Architect', '#70a5fd']
  return { username, matrix, total_commits: total, night_commits: night, day_commits: total - night, weekend_commits: weekend, peak_hour: peakHour, peak_day: peakDay, peak_count: peak,
    persona_title: total ? persona[0] : 'No commit activity', persona_icon: '', persona_color: persona[1], peak_window_str: total ? `${String(start).padStart(2, '0')}:00 – ${String((start + 4) % 24).padStart(2, '0')}:00` : 'No activity' }
}

export function calculateVelocity(username, user) {
  const prs = user.pullRequests?.nodes || []
  const merged = user.mergedPRs?.totalCount || 0, open = user.openPRs?.totalCount || 0, closed = user.closedPRs?.totalCount || 0
  const total = user.pullRequests?.totalCount || merged + open + closed
  const hours = prs.filter(p => p.mergedAt && Date.parse(p.mergedAt) >= Date.parse(p.createdAt)).map(p => (Date.parse(p.mergedAt) - Date.parse(p.createdAt)) / 3600000)
  const average = hours.length ? hours.reduce((a, b) => a + b, 0) / hours.length : 24
  const rate = total ? merged / total * 100 : 0
  const reviews = user.contributionsCollection?.totalPullRequestReviewContributions || 0
  const speed = !hours.length ? 0 : average <= 12 ? 30 : average <= 24 ? 28 : average <= 48 ? 24 : average <= 96 ? 18 : average <= 168 ? 14 : 10
  const score = Math.trunc(Math.min(100, Math.max(0, rate * .4 + speed + Math.min(15, merged / 25 * 15) + Math.min(15, reviews))))
  return { username, total_prs: total, merged_prs: merged, open_prs: open, closed_prs: closed, merge_rate: rate,
    avg_turnaround_hours: average, turnaround_str: hours.length ? average < 1 ? '< 1h' : average < 24 ? `${average.toFixed(1)}h` : `${(average / 24).toFixed(1)}d` : 'N/A',
    total_additions: prs.reduce((s, p) => s + (p.additions || 0), 0), total_deletions: prs.reduce((s, p) => s + (p.deletions || 0), 0),
    changed_files: prs.reduce((s, p) => s + (p.changedFiles || 0), 0), reviews_completed: reviews, velocity_score: score,
    tier: { name: '', icon: '', color: '', percentile: '' } }
}
