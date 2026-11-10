import { useEffect, useMemo, useState } from 'react'
import { Check } from 'lucide-react'
import ProfileStep from './ProfileStep'
import DesignStep from './DesignStep'
import PublishStep from './PublishStep'
import { DEFAULT_CONFIG, normalizeConfig, validUsername } from '../services/profileConfig'
import { fetchUserData } from '../services/githubApi'
import { loadEngine } from '../services/engine'
import { DEMO_DATA } from '../services/demo'
import { readStored, writeStored } from '../hooks'

const STORAGE_KEY = 'gitstats-studio-v2'
const browserOffset = () => Math.round(-new Date().getTimezoneOffset() / 15) / 4

function initialState() {
  const saved = readStored(STORAGE_KEY, null)
  const params = new URLSearchParams(location.search)
  let config
  try { config = normalizeConfig(saved?.config || { ...DEFAULT_CONFIG, options: { ...DEFAULT_CONFIG.options, timezone: browserOffset() } }) }
  catch { config = normalizeConfig(DEFAULT_CONFIG) }
  return { config, username: params.get('user') || (typeof saved?.username === 'string' ? saved.username : '') }
}

const STEPS = [
  { n: 1, label: 'Profile' },
  { n: 2, label: 'Design' },
  { n: 3, label: 'Publish' },
]

export default function Studio() {
  const [{ config, username }, setState] = useState(initialState)
  const [step, setStep] = useState(1)
  const [direction, setDirection] = useState(1)
  const [token, setToken] = useState('')
  const [data, setData] = useState(DEMO_DATA)
  const [load, setLoad] = useState({ status: 'idle', error: '' })
  const [engine, setEngine] = useState(null)
  const [engineError, setEngineError] = useState('')

  useEffect(() => { writeStored(STORAGE_KEY, { config, username }) }, [config, username])
  useEffect(() => {
    let live = true
    loadEngine().then(e => live && setEngine(e)).catch(e => live && setEngineError(e.message))
    return () => { live = false }
  }, [])

  const setConfig = update => setState(s => {
    const next = typeof update === 'function' ? update(s.config) : update
    try { return { ...s, config: normalizeConfig(next) } } catch { return s }
  })
  const setUsername = value => setState(s => ({ ...s, username: value }))
  const go = n => { setDirection(n > step ? 1 : -1); setStep(n); scrollTo({ top: 0, behavior: 'smooth' }) }

  async function loadProfile(nextToken = token) {
    const user = username.trim()
    if (!validUsername(user)) { setLoad({ status: 'error', error: 'Enter a valid GitHub username.' }); return false }
    setLoad({ status: 'loading', error: '' })
    try {
      const result = await fetchUserData(user, nextToken, { force: true })
      setData(result)
      setLoad({ status: 'done', error: '' })
      return true
    } catch (e) {
      setLoad({ status: 'error', error: e.message })
      return false
    }
  }
  const resetToSample = () => { setData(DEMO_DATA); setLoad({ status: 'idle', error: '' }) }

  const canPublish = validUsername(username.trim())
  const done = useMemo(() => ({ 1: load.status === 'done', 2: step > 2 }), [load.status, step])

  return <div className="studio">
    <div className="intro">
      <div>
        <h1>Live stat cards for your GitHub profile</h1>
        <p>Choose cards, arrange them, and publish once. GitHub then refreshes them every four hours, so your profile stays current on its own.</p>
      </div>
      <nav className="stepper" aria-label="Steps">
        {STEPS.map(s => <button key={s.n} className={`step-tab ${done[s.n] && step !== s.n ? 'done' : ''}`} aria-current={step === s.n ? 'step' : undefined} disabled={s.n === 3 && !canPublish} onClick={() => go(s.n)}>
          <span className="num">{done[s.n] && step !== s.n ? <Check size={14} /> : s.n}</span><span className="label-text">{s.label}</span>
        </button>)}
      </nav>
    </div>
    <section key={step} className={direction > 0 ? 'enter-forward' : 'enter-back'} aria-live="polite">
      {step === 1 && <ProfileStep username={username} onUsername={setUsername} token={token} onToken={setToken} data={data} load={load}
        onLoad={async t => { if (await loadProfile(t)) go(2) }} onSample={resetToSample} onNext={() => go(2)} />}
      {step === 2 && <DesignStep config={config} setConfig={setConfig} data={data} engine={engine} engineError={engineError}
        onBack={() => go(1)} onNext={() => go(3)} canPublish={canPublish} />}
      {step === 3 && <PublishStep username={username.trim()} config={config} onBack={() => go(2)} />}
    </section>
  </div>
}
