# GitStats Studio

[Back to GitStats](../README.md) · [Native CLI](../docs/cli.md)

A static React/Vite workspace for designing GitHub profile layouts. The UI is JavaScript/JSX, and its preview engine compiles the same Zig SVG renderers as the native CLI into WebAssembly. There is no hosted rendering API or OAuth sign-in flow.

## Run locally

Use **Node 24**. From the repository root in PowerShell:

```powershell
cd frontend
npm ci
npm run dev
```

Open the localhost URL Vite prints, normally **http://localhost:5173/**. `npm run dev` uses the checked-in `public/engine.wasm`; ordinary React/CSS edits do not require Zig. After changing a native renderer, install **Zig 0.16.0**, run `npm run engine`, and refresh the page.

To check the production bundle:

```powershell
npm run build
npm run preview
```

Open the URL printed by preview, normally **http://localhost:4173/**. Build rebuilds the WebAssembly engine before creating `dist/`, so Zig is required for this step. Visitors to a deployed Studio need only a browser.

## Design and preview

- Drag grip handles in the card layers or canvas; up/down controls are available too.
- **Pillar right** places languages beside standard cards and heroes above them. **Flow** packs cards into sequential rows.
- Choose eight native themes, card widths, corner radii, language limits/exclusions, streak momentum, stats scope, and rhythm timezone.
- Numeric fields allow unfinished edits. Enter or leaving the field commits the value; invalid or out-of-range input shows a correction message.
- Open **Profile preview** to see the exported HTML with local SVGs in an isolated frame, without editing controls. Desktop/mobile widths, light/dark backgrounds, fit/actual size, and a large preview are available.

The preview matches the generated snippet's image dimensions and ordering. Other README content, GitHub's available width, and future GitHub styles can affect final wrapping. Defaults retain 4.5px corners; `0` gives square corners. Layout settings are saved on this device, while tokens stay in tab memory.

## Preview data and limits

The initial canvas explicitly uses **sample data**. Enter a username for public languages, or use **Connect GitHub** for authenticated metrics. Missing authentication and failed requests do not silently become sample data.

The browser flow is GitHub API → JavaScript analytics → Zig WebAssembly → SVG. The engine has no OS, network, or WASI imports. SVG cards are displayed in isolated image elements, and the README preview uses a sandboxed frame.

Sampling mirrors the native engine: up to 100 language repositories, commit history from 20 repositories with 100 commits each, and turnaround/churn from the latest 30 PRs. Public language loading samples at most 20 non-fork repositories. Access depends on token visibility and organization policy. Percentile tiers are heuristic labels. Native `this-year` uses a rolling contribution collection rather than January-to-today totals.

Language colors come from the bundled GitHub Linguist snapshot; builds do not download a color palette. Empty accounts retain zero activity.

## Tokens and deployment

Fork the current engine and enable Actions before deploying a layout. Set the owner, repository, and branch under **Export destination**.

| Token | Purpose | Lifetime and scope |
| --- | --- | --- |
| Read-only preview token | Connect GitHub for authenticated metrics | Access only the repositories needed for preview |
| Optional deployment PAT | Commit the workflow and request a run | Temporary fine-grained token, restricted to the engine fork; Contents, Workflows, and Actions write permissions |
| Actions secret `GH_TOKEN` | Fetch data on the schedule | Separate, longer-lived read token with access to the repositories included in your stats; set an expiration and renew it |

Fine-grained PAT permissions apply equally to every selected repository. Keep the deployment PAT separate from a broader private-data preview token. Studio does not create the `GH_TOKEN` secret. See GitHub's [Contents API permissions](https://docs.github.com/en/rest/repos/contents#create-or-update-file-contents), [workflow dispatch permissions](https://docs.github.com/en/rest/actions/workflows#create-a-workflow-dispatch-event), and [PAT guide](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens).

Two deployment paths are available:

1. **Manual:** copy/download the YAML from Export, then commit it using the GitHub web editor. No Studio write token is needed.
2. **Direct sync:** select **Deploy profile → Commit from Studio**, review the destination and YAML, and supply the deployment PAT. Studio commits only `.github/workflows/generate-stats.yml` and requests a run. A successful commit with a failed dispatch is reported separately.

Actions then compiles the **native** engine, fetches data, and commits selected SVGs to `generated/`. It uses its own repository token for those commits; your read secret does not need write access. Studio-generated workflows use `GH_TOKEN` when present and otherwise the workflow token. Restricted/private data may require the separate read secret.

After generation succeeds, copy **Export → Profile README** into `username/username/README.md`. Studio does not edit that separate repository. Branch rules or organization policies can block direct sync, in which case use the repository's usual review process. GitHub's image cache can delay updates.

Studio exports use `--strict-data`, `--svg-icons`, and `--animate=false`. Existing native workflows retain their configured flags and fallback behavior. Unified bento CLI layouts remain available separately.

## GitHub Pages

The tracked [.github/workflows/deploy-pages.yml](../.github/workflows/deploy-pages.yml) builds and deploys Studio. It responds to changes under `frontend/**` and `src/**` on `main`, and supports manual runs. Vite's relative asset base supports repository subpaths, including the WebAssembly file.

1. Push the code and Pages workflow to your repository.
2. Open **Settings → Pages → Build and deployment → Source**, then select **GitHub Actions** ([GitHub guide](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)).
3. Run **Actions → Deploy GitStats Studio to GitHub Pages → Run workflow**.
4. Open the deployed URL shown by the `github-pages` environment.

A `configure-pages` **Not Found** error commonly means Pages has not been enabled or repository policy/plan does not permit it. Check Pages settings and rerun the workflow. Pages deployment needs no PAT or `GH_TOKEN`. The existing workflow uses Node 24, Zig 0.16.0, and the standard Pages upload/deploy actions.

The Pages workflow publishes the Studio, while `generate-stats.yml` publishes profile images. They are independent.

## Verification

From `frontend/`:

```powershell
npm run lint
npm run build
npm test
npm run test:parity
cd ..
zig build -Doptimize=ReleaseFast
zig build test
```

[Project checks](../.github/workflows/checks.yml) runs these checks for code changes and pull requests. Parity compares all seven cards across eight themes, byte-for-byte, between native and browser engines. API tests use mocked requests; checks never commit to GitHub or require credentials. Real authenticated data and direct sync should be tested with your own token and a disposable fork.

To refresh documentation examples after a renderer change, run `npm run engine` followed by `npm run previews` from `frontend/`. This uses deterministic sample data and changes only the standalone non-language showcase SVGs; it does not overwrite `generated/`, language examples, or bento artifacts.
