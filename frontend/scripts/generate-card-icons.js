// Lucide (ISC): named SVG paths shared by native and WebAssembly card renderers.
import * as icons from 'lucide-react'
import { createElement } from 'react'
import { renderToStaticMarkup } from 'react-dom/server'
import { writeFileSync } from 'node:fs'
const names = { commit: 'GitCommitHorizontal', pr: 'GitPullRequest', star: 'Star', book: 'BookOpen', sunrise: 'Sunrise', sun: 'Sun', moon: 'Moon', timer: 'Timer', flame: 'Flame', layers: 'Layers', repo: 'FolderGit2' }
const entries = Object.entries(names).map(([key, name]) => {
  const svg = renderToStaticMarkup(createElement(icons[name]))
  return `        .${key} => ${JSON.stringify(svg.slice(svg.indexOf('>') + 1, svg.lastIndexOf('</svg>')))},`
})
writeFileSync(new URL('../../src/renderer/card_icons.zig', import.meta.url), `// Generated from lucide-react by frontend/scripts/generate-card-icons.js. ISC license.\npub const Icon = enum { ${Object.keys(names).join(', ')} };\npub fn paths(icon: Icon) []const u8 {\n    return switch (icon) {\n${entries.join('\n')}\n    };\n}\n`)
