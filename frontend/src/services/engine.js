let loading
const encoder = new TextEncoder()
const decoder = new TextDecoder()

export function loadEngine() {
  if (!loading) loading = fetch(`${import.meta.env.BASE_URL}engine.wasm`).then(async response => {
    if (!response.ok) throw new Error('The preview engine could not load. Rebuild with npm run engine.')
    const { instance } = await WebAssembly.instantiate(await response.arrayBuffer(), {})
    return instance.exports
  }).catch(error => { loading = null; throw error })
  return loading
}

export function renderNative(engine, request) {
  const bytes = encoder.encode(JSON.stringify(request))
  const pointer = engine.studio_alloc(bytes.length)
  if (!pointer) throw new Error('Preview engine ran out of memory.')
  try {
    new Uint8Array(engine.memory.buffer, pointer, bytes.length).set(bytes)
    const result = engine.studio_render(pointer, bytes.length)
    if (!result) throw new Error('The preview engine could not render this data.')
    return decoder.decode(new Uint8Array(engine.memory.buffer, result, engine.studio_output_len()))
  } finally { engine.studio_free(pointer, bytes.length) }
}
