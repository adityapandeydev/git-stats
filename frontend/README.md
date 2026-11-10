# GitStats Studio

[Back to GitStats](../README.md) · [CLI reference](../docs/cli.md)

Studio is the website where people design their GitStats layout and publish it. It's a static React + Vite site: no backend, no sign-in. Card previews come from the same Zig renderers as the GitHub Action, compiled to WebAssembly, so what you see is what gets published.

## Run locally

Use **Node 24**:

```powershell
cd frontend
npm ci
npm run dev
```

Open the URL Vite prints, normally **http://localhost:5173/**. `npm run dev` uses the checked-in `public/engine.wasm`, so UI work doesn't need Zig. After changing a renderer in `src/renderer/`, install **Zig 0.16.0**, run `npm run engine`, and refresh.

## How it's organised

| Path | What it does |
| --- | --- |
| `src/App.jsx` | Shell: boot animation, header, theme switch, `#/` and `#/docs/…` routes |
| `src/studio/` | The three steps: `ProfileStep`, `DesignStep` (palette, canvas, settings), `ReadmePreview`, `PublishStep` |
| `src/docs/` | The in-site documentation |
| `src/services/profileConfig.js` | **Shared with the GitHub Action.** Card catalogue, row types, config validation, CLI arguments, README and workflow compilers |
| `src/services/layoutOps.js` | Pure canvas edits: place, swap, remove, add and move rows |
| `src/services/githubApi.js` | GitHub API: preview data, public repository checks, optional commit |
| `src/services/cardRequest.js`, `engine.js` | Turn a config and profile data into a WebAssembly render |
| `src/index.css` | The whole design system: tokens for dark and light, motion, layout |

### Motion rules

All animations run once and stop: the boot sequence (once per tab session), step and page slides, button feedback, the theme switch (a circular reveal using View Transitions, or a colour fade where unsupported) and scroll reveals (each observer disconnects after showing its element). The only looping animation is the loading spinner, which exists only while something is loading. `prefers-reduced-motion` turns all of it off.

## Data and tokens

- Without a token, Studio loads public language data for any username (up to 20 recently pushed repositories), so Top languages and Developer DNA preview with real data. Other cards show labelled sample data.
- An optional read-only token, kept in tab memory only, previews every card with real data.
- Publishing needs no token: Studio opens GitHub's new-file page with the workflow pre-filled. An optional write token lets Studio commit it instead.
- Layouts are saved in `localStorage`. Tokens are never saved, exported or written into the workflow.

## Deploy to GitHub Pages

[`.github/workflows/deploy-pages.yml`](../.github/workflows/deploy-pages.yml) builds and deploys Studio on pushes to `main` that touch `frontend/` or `src/`.

1. **Settings → Pages → Build and deployment → Source:** choose **GitHub Actions**.
2. Run **Actions → Deploy GitStats Studio to GitHub Pages**, or push a change.

The build compiles the WebAssembly engine first, so it needs Zig (the workflow installs it). Vite's relative base path works on repository subpaths.

## Verification

From `frontend/`:

```powershell
npm run lint
npm run build
npm test
npm run test:parity
```

and from the repository root: `zig build -Doptimize=ReleaseFast` and `zig build test`. [Project checks](../.github/workflows/checks.yml) runs all of these on every change. Parity compares every card in every theme, byte for byte, between the native and browser engines. API tests use mocked requests and never need credentials.

After a renderer change, run `npm run engine` and then `npm run previews` to refresh the sample images in `preview/`.
