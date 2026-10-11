import { readFileSync, writeFileSync } from 'node:fs'
const native = readFileSync(new URL('../../src/github/colors.zig', import.meta.url), 'utf8')
const entries = [...native.matchAll(/\.\{ "([^"]+)", "(#[\da-f]+)" \}/gi)].map(([, name, color]) => [name, color])
if (entries.length < 50) throw new Error('Native language palette could not be read')
const snapshot = JSON.parse(readFileSync(new URL('../src/constants/linguist-colors.json', import.meta.url), 'utf8').replace(/^\uFEFF/, ''))
if (Object.keys(snapshot.colors).length < 500) throw new Error('The GitHub Linguist snapshot is incomplete')
const colors = { ...Object.fromEntries(entries), ...snapshot.colors }
writeFileSync(new URL('../src/constants/languageColors.js', import.meta.url), `// Generated from the GitHub Linguist snapshot, with native aliases.\nexport const LANGUAGE_COLORS = ${JSON.stringify(colors, null, 2)}\nexport const DEFAULT_LANGUAGE_COLOR = '#586069'\n`)
