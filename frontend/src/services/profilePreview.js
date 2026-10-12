import { generateProfileHtml } from './compiler.js'
import { cardRequest } from './cardRequest.js'
import { renderNative } from './engine.js'
import { cardRadius, getCardDef } from '../constants/cards.js'

function placeholder(card, message) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${card.width}" height="${card.height}" viewBox="0 0 ${card.width} ${card.height}"><rect width="100%" height="100%" rx="${cardRadius(card)}" fill="#1a1b27" stroke="#30363d"/><text x="50%" y="46%" text-anchor="middle" font-family="Arial,sans-serif" font-size="13" fill="#c0caf5">${getCardDef(card.id).name}</text><text x="50%" y="58%" text-anchor="middle" font-family="Arial,sans-serif" font-size="11" fill="#909bbd">${message}</text></svg>`
}

// The exported HTML determines ordering, floats, whitespace and line breaks.
// Only the image sources change: local native SVGs replace remote file URLs.
export function profilePreview({ engine, username, cards, layoutMode, themeId, userData, target, light = false }) {
  const failures = []
  const markup = generateProfileHtml(username, cards, layoutMode, target, card => {
    let svg
    if (!userData?.available.includes(card.id)) {
      svg = placeholder(card, userData ? 'Connect GitHub to preview this card' : 'Waiting for profile data')
      failures.push(card.id)
    } else {
      try { svg = renderNative(engine, cardRequest(card, themeId, userData)) }
      catch {
        svg = placeholder(card, 'Preview unavailable; review your data connection')
        failures.push(card.id)
      }
    }
    return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`
  })
  const document = `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src data:; style-src 'unsafe-inline'"><style>
html{color-scheme:${light ? 'light' : 'dark'};background:${light ? '#ffffff' : '#0d1117'}}body{margin:0;padding:24px;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;font-size:16px;line-height:1.5;color:${light ? '#1f2328' : '#e6edf3'}}.markdown-body{overflow-wrap:break-word;display:flow-root}.markdown-body img{max-width:100%;box-sizing:content-box;background-color:${light ? '#ffffff' : '#0d1117'};height:auto}.markdown-body img[align=right]{padding-left:20px}.markdown-body img[align=left]{padding-right:20px}.markdown-body::after{display:table;clear:both;content:""}@media(max-width:500px){body{padding:16px}}
</style></head><body><article class="markdown-body">${markup}</article></body></html>`
  return { document, failures }
}
