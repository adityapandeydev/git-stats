import { useLayoutEffect, useMemo, useRef, useState } from 'react'
import { Monitor, Moon, Smartphone, Sun } from 'lucide-react'
import { profilePreview } from '../services/profilePreview'
import { cardSize } from '../services/profileConfig'

// Height of the README section at a given width, so the frame never scrolls.
function estimateHeight(config, width) {
  const inner = width - 48
  let h = 48
  for (const row of config.layout) {
    const cards = row.cards.filter(Boolean)
    if (!cards.length) continue
    if (row.type === 'wide') h += inner * 180 / 840
    if (row.type === 'pair') h += inner * 0.49 * 180 / 424
    if (row.type === 'stack') {
      const [top, bottom, tall] = row.cards
      const left = [top, bottom].filter(Boolean).length * inner * 0.5 * 180 / 424
      const right = tall ? inner * 0.48 * cardSize(tall, config).height / 400 : 0
      h += Math.max(left, right)
    }
    h += 24
  }
  return Math.ceil(h)
}

export default function ReadmePreview({ config, data, engine }) {
  const [width, setWidth] = useState(830)
  const [light, setLight] = useState(false)
  const [available, setAvailable] = useState(900)
  const ref = useRef(null)
  useLayoutEffect(() => {
    const observer = new ResizeObserver(([entry]) => setAvailable(entry.contentRect.width))
    if (ref.current) observer.observe(ref.current)
    return () => observer.disconnect()
  }, [])
  const result = useMemo(() => engine ? profilePreview({ engine, config, userData: data, light }) : null, [engine, config, data, light])
  const scale = Math.min(1, available / width)
  const height = estimateHeight(config, width)

  return <div className="github-preview enter">
    <div className="preview-tools">
      <div className="segmented" role="group" aria-label="Device">
        <button aria-pressed={width >= 700} onClick={() => setWidth(830)}><Monitor size={14} /> Desktop</button>
        <button aria-pressed={width < 500} onClick={() => setWidth(375)}><Smartphone size={14} /> Phone</button>
      </div>
      <label className="range-row"><span>Width</span><input type="range" min="340" max="1000" value={width} onChange={e => setWidth(Number(e.target.value))} /><output>{width}px</output></label>
      <div className="segmented" role="group" aria-label="GitHub theme">
        <button aria-pressed={!light} onClick={() => setLight(false)}><Moon size={14} /> Dark</button>
        <button aria-pressed={light} onClick={() => setLight(true)}><Sun size={14} /> Light</button>
      </div>
    </div>
    <div ref={ref}>
      <div className={`frame-wrap ${light ? 'light' : ''}`} style={{ width: width * scale, height: height * scale }}>
        {result && <iframe title="README preview" sandbox="" srcDoc={result.document} style={{ width, height, transform: `scale(${scale})` }} />}
      </div>
    </div>
    <p className="hint">This is the exact markup your README will get. Widths are percentages, so rows shrink together instead of wrapping.{result?.failures.length ? ` ${result.failures.length} card${result.failures.length > 1 ? 's show' : ' shows'} a placeholder here because the preview has no data for ${result.failures.length > 1 ? 'them' : 'it'}; the published card uses your real data.` : ''}</p>
  </div>
}
