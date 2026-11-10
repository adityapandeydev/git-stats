import { cardById, cardSize, compileReadme } from './profileConfig.js'
import { cardRequest } from './cardRequest.js'
import { renderNative } from './engine.js'

function placeholder(id, config, message) {
  const { width, height } = cardSize(id, config)
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}"><rect x=".5" y=".5" width="${width - 1}" height="${height - 1}" rx="${config.radius}" fill="#1a1b27" stroke="#30363d"/><text x="50%" y="46%" text-anchor="middle" font-family="Arial,sans-serif" font-size="14" fill="#c0caf5">${cardById(id).name}</text><text x="50%" y="58%" text-anchor="middle" font-family="Arial,sans-serif" font-size="11" fill="#7982a9">${message}</text></svg>`
}

/** Render a card to SVG, or a labelled placeholder when its data is unavailable. */
export function renderCard(engine, id, config, userData) {
  if (!userData?.available.includes(id)) return { svg: placeholder(id, config, userData ? 'Add a token to preview this card' : 'Waiting for profile data'), placeholder: true }
  try { return { svg: renderNative(engine, cardRequest(id, config, userData)), placeholder: false } }
  catch { return { svg: placeholder(id, config, 'Preview unavailable'), placeholder: true } }
}

// The exported markup decides order, floats and widths; only image sources
// change, from repository paths to local SVGs.
export function profilePreview({ engine, config, userData, light = false }) {
  const failures = []
  const markup = compileReadme(config, id => {
    const { svg, placeholder: missing } = renderCard(engine, id, config, userData)
    if (missing) failures.push(id)
    return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`
  })
  const document = `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src data:; style-src 'unsafe-inline'"><style>
html{color-scheme:${light ? 'light' : 'dark'};background:${light ? '#ffffff' : '#0d1117'}}body{margin:0;padding:24px;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;font-size:16px;line-height:1.5;color:${light ? '#1f2328' : '#e6edf3'}}.markdown-body{overflow-wrap:break-word;display:flow-root}.markdown-body p{margin:0 0 16px}.markdown-body img{max-width:100%;box-sizing:content-box}
</style></head><body><article class="markdown-body">${markup}</article></body></html>`
  return { document, failures }
}
