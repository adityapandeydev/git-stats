import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import './generate-icons.js'
import './generate-card-icons.js'
import './generate-colors.js'
const root = fileURLToPath(new URL('../../', import.meta.url))
const result = spawnSync('zig', ['build-exe', 'src/studio.zig', '-target', 'wasm32-freestanding', '-fno-entry', '-rdynamic', '--export-memory', '-O', 'ReleaseSmall', '-femit-bin=frontend/public/engine.wasm'], { cwd: root, stdio: 'inherit' })
if (result.error) console.error('Zig 0.16.0 is required to rebuild the browser engine:', result.error.message)
process.exit(result.status ?? 1)
