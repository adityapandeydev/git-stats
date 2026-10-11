import { spawnSync } from 'node:child_process'
import { mkdtempSync, readFileSync, writeFileSync, unlinkSync, rmdirSync, readdirSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import assert from 'node:assert/strict'
import { DEMO_DATA } from '../src/services/demo.js'
import { THEMES } from '../src/constants/themes.js'

const root = fileURLToPath(new URL('../../', import.meta.url))
const directory = mkdtempSync(join(tmpdir(), 'gitstats-parity-'))
const executable = join(directory, process.platform === 'win32' ? 'fixture.exe' : 'fixture')
const input = join(directory, 'input.json'), output = join(directory, 'output.svg')
try {
  const build = spawnSync('zig', ['build-exe', 'src/studio_fixture.zig', '-O', 'ReleaseSafe', `-femit-bin=${executable}`], { cwd: root, stdio: 'inherit' })
  assert.equal(build.status, 0, 'Native fixture runner must compile')
  const { instance: { exports: engine } } = await WebAssembly.instantiate(readFileSync(new URL('../public/engine.wasm', import.meta.url)), {})
  const encoder = new TextEncoder(), decoder = new TextDecoder()
  let cases = 0
  for (const theme of THEMES) for (const card of ['languages', 'streak', 'stats', 'rhythm', 'radar', 'velocity', 'milestones']) {
    const json = JSON.stringify({ card, theme: theme.id, username: 'demo', width: card === 'languages' ? 400 : 424, height: card === 'languages' ? 294 : 180, languages: DEMO_DATA.languages, metrics: DEMO_DATA.metrics, streak: DEMO_DATA.streak, rhythm: DEMO_DATA.rhythm, velocity: DEMO_DATA.velocity })
    writeFileSync(input, json)
    const native = spawnSync(executable, [input, output], { cwd: root, encoding: 'utf8' })
    assert.equal(native.status, 0, native.stderr)
    const bytes = encoder.encode(json), pointer = engine.studio_alloc(bytes.length)
    new Uint8Array(engine.memory.buffer, pointer, bytes.length).set(bytes)
    try {
      const result = engine.studio_render(pointer, bytes.length)
      assert.ok(result)
      const svg = decoder.decode(new Uint8Array(engine.memory.buffer, result, engine.studio_output_len()))
      assert.equal(svg, readFileSync(output, 'utf8'), `${theme.id}/${card}: browser and native SVG differ`)
      cases++
    } finally { engine.studio_free(pointer, bytes.length) }
  }
  console.log(`${cases} native/browser comparisons passed (7 cards × ${THEMES.length} themes).`)
} finally {
  // Only direct files in our freshly created temporary directory; never recurse.
  for (const name of readdirSync(directory)) unlinkSync(join(directory, name))
  rmdirSync(directory)
}
