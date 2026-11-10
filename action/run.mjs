// Runs inside the GitStats GitHub Action (see ../action.yml).
// Renders every card placed in the Studio config with the native engine,
// rewrites the README section between the gitstats markers and commits.
import { spawnSync } from 'node:child_process'
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, join, posix, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { cardArgs, compileReadme, normalizeConfig, placedCards, updateReadmeSection, validUsername } from '../frontend/src/services/profileConfig.js'

const env = process.env
const here = dirname(fileURLToPath(import.meta.url))
const binary = resolve(here, '..', 'zig-out', 'bin', process.platform === 'win32' ? 'git_stats.exe' : 'git_stats')
const workspace = env.GITHUB_WORKSPACE || process.cwd()

function fail(message) {
  console.log(`::error::${message}`)
  process.exit(1)
}

let config
try { config = normalizeConfig(JSON.parse(env.INPUT_CONFIG || '{}')) }
catch (error) { fail(`The config input is not valid: ${error.message}. Export it again from GitStats Studio.`) }

const username = env.GITHUB_REPOSITORY_OWNER || ''
if (!validUsername(username)) fail('Could not determine the GitHub username for this repository.')
const cards = placedCards(config)
if (!cards.length) fail('The config has no cards. Add cards in GitStats Studio and export again.')

// Paths inside the repository use forward slashes so README links work on GitHub.
const outDir = posix.normalize((env.INPUT_OUTPUT_DIR || 'gitstats').replaceAll('\\', '/')).replace(/^\.?\/+|\/+$/g, '')
if (!outDir || outDir.startsWith('..')) fail('output-dir must be a folder inside the repository.')
mkdirSync(join(workspace, outDir), { recursive: true })

const token = env.INPUT_TOKEN || env.INPUT_FALLBACK_TOKEN || ''
if (!env.INPUT_TOKEN) console.log('No GH_TOKEN secret given: using the workflow token. Cards will show public data only.')

const rendered = [], failed = []
for (const id of cards) {
  const output = `${outDir}/${id}.svg`
  console.log(`::group::Rendering ${id}`)
  const result = spawnSync(binary, cardArgs(id, config, { username, output }), { cwd: workspace, env: { ...env, GH_TOKEN: token }, stdio: 'inherit' })
  console.log('::endgroup::')
  if (result.status === 0) rendered.push(id)
  else { failed.push(id); console.log(`::warning::The ${id} card could not be generated. The previous version is kept.`) }
}
if (!rendered.length) fail('No cards could be generated. Check the log above; a missing or expired GH_TOKEN is the most common cause.')

// README: only the marked section changes; everything else is left as written.
const readmePath = join(workspace, env.INPUT_README || 'README.md')
const before = existsSync(readmePath) ? readFileSync(readmePath, 'utf8') : ''
const after = updateReadmeSection(before, compileReadme(config, id => `${outDir}/${id}.svg`))
if (after !== before) writeFileSync(readmePath, after)

if (env.INPUT_COMMIT !== 'false') {
  const git = (...args) => spawnSync('git', args, { cwd: workspace, stdio: 'inherit' })
  git('config', 'user.name', 'github-actions[bot]')
  git('config', 'user.email', '41898282+github-actions[bot]@users.noreply.github.com')
  git('add', '--', outDir, env.INPUT_README || 'README.md')
  const changed = spawnSync('git', ['diff', '--staged', '--quiet'], { cwd: workspace }).status !== 0
  if (changed) {
    if (git('commit', '-m', 'chore: update GitStats cards [skip ci]').status !== 0) fail('Could not commit the updated cards.')
    if (git('push').status !== 0) fail('Could not push the updated cards. Make sure the workflow has "permissions: contents: write".')
  } else console.log('Cards are already up to date.')
}

if (failed.length) fail(`Some cards could not be generated: ${failed.join(', ')}.`)
console.log(`Updated ${rendered.length} card${rendered.length === 1 ? '' : 's'}.`)
