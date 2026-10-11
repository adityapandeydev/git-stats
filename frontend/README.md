# GitStats Studio

A static React workspace for arranging GitStats cards, previewing native SVGs, and exporting a GitHub Actions workflow and profile README snippet. Authored source is JavaScript/JSX only.

## Develop

Install Zig **0.16.0** and Node **22.12+** (or Node 24). From PowerShell:

```powershell
cd frontend
npm ci
npm run dev
```

`npm run dev` uses the checked-in `public/engine.wasm`; Zig compilation is unnecessary for ordinary React/CSS edits. Run `npm run engine` after changing a Zig renderer during development. `npm run build` rebuilds the WebAssembly engine before Vite produces `dist/`. The engine has no operating system, network, or WASI imports; GitHub data fetching stays in browser JavaScript. SVGs are isolated in image elements.

The flow is: GitHub API → JavaScript data preparation → native Zig renderer running as WebAssembly in the browser → SVG preview. Exporting creates CLI commands for GitHub Actions, which compiles a separate native executable to generate the published SVG files. Browsers and visitors to the deployed studio do not need Zig installed.

**Connect GitHub** in the top bar opens the read-token form. Authentication currently uses a personal access token, with no OAuth sign-in flow. Preview tokens are separate from deployment tokens and Actions secrets. Public language colors come from the bundled GitHub Linguist snapshot in `src/constants/linguist-colors.json`; builds need no network request to retrieve the palette.

## Preview data

The initial canvas uses explicitly labelled sample data. Load a username for public language data; connect a read token for contribution, stats, rhythm, velocity, and milestone cards. Missing authentication and failed requests never silently become sample metrics. Tokens stay in tab memory, while layout settings are saved locally. Closing the tab discards tokens.

Authenticated sampling mirrors the native engine: up to 100 language repositories, commit history from 20 repositories with 100 commits each, and turnaround/churn from the latest 30 PRs. Token visibility affects results. Tier percentiles are native heuristic labels. The native `this-year` option means the default rolling contribution collection, not January to today. Public language sampling is bounded to 20 non-fork repositories to conserve the unauthenticated API budget.

## Customize and export

Drag grip handles in either card layers or canvas. Up/down controls provide an alternative. Pillar right pins languages beside standard cards, with hero cards above both columns. Flow packs cards into rows. Language counts range from 6–16 and taller cards distribute extra space between rows. Themes and per-card options feed both the preview renderer and workflow compiler.

Export produces individual SVG commands and README image markup. Mobile preview stacks individual images; GitHub controls actual README wrapping. Unified native bento CLI layouts remain available separately and retain their existing behavior.

Choose the repository owner, name, and branch under **Export destination**. Fork the updated engine first: generated workflows use the additive `--svg-icons` and `--strict-data` flags introduced with Studio. Existing CLI defaults and production workflows remain unchanged.

Deployment offers two paths:

- **GitHub web editor:** copy/download YAML, open the existing file or new-file editor, then commit it yourself.
- **Direct sync:** a fine-grained token needs Contents, Workflows, and Actions write permissions on the destination fork. Studio reads the selected branch's file SHA, commits the workflow, and requests a run. A dispatch failure is reported separately from a successful commit. No fork is created automatically. Enable Actions in the fork if GitHub requires it.

Generation uses `GH_TOKEN` if supplied as a repository secret, otherwise the workflow token. Add a suitable read token secret when broader/private profile data is needed. Copy the README snippet into the separate `username/username` repository after generation succeeds. GitHub's image cache can delay visible updates.

## GitHub Pages

Vite uses a relative asset base, so the app and WebAssembly work under `/git-stats/`. Set Pages' build source to GitHub Actions. A Pages workflow should check out the repository, install Node and Zig 0.16.0, run `npm ci` then `npm run build` in `frontend/`, upload `frontend/dist` with `actions/upload-pages-artifact`, and deploy with `actions/deploy-pages`. Grant `pages: write` and `id-token: write`, and use the `github-pages` environment. Trigger it for frontend changes **and `src/**` changes**, since native renderers are bundled into Studio.

The local ignored `.github/workflows/deploy-pages.yml` includes Node 24, Zig 0.16.0, and native-source triggers, but remains untracked. The same configuration is available in `frontend/deploy-pages.example.yml`. Publish the workflow separately when ready. No hosted runtime backend is required.

## Verify

```powershell
npm run lint
npm test
npm run build
npm run test:parity
cd ..
zig build
zig build test
```

Parity checks compare native and browser SVG output byte-for-byte for all seven cards in all eight themes. API deployment tests use mocked requests and never write to GitHub. Browser checks cover drag handles, quick controls, exports, repeated modal opening, and responsive panels. Real authenticated GitHub data and a production write should be verified with your own token and disposable fork before deployment.

### Card corners and streak layout

Every card has a **Corner radius** control in Card settings. The default remains **4.5 px**, matching existing CLI workflows. Set `0` for square corners; custom values persist in your draft and export as `--border-radius=<value>`.

The streak card uses a dedicated current-streak column, stacked contribution and longest-streak metrics, single-line date ranges, and an optional 14-day momentum chart. Empty accounts display clear activity labels. The Studio and CLI share this renderer.
