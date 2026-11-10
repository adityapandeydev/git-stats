import { ENGINE_REPO, ACTION_REF, WORKFLOW_PATH } from '../services/profileConfig'
import { CardGallery, Callout, Section } from './DocParts'

export const PAGES = [
  {
    id: 'getting-started',
    title: 'Get started',
    summary: 'Put live stat cards on your GitHub profile in about five minutes. No installs and no servers.',
    body: () => <>
      <Section title="How it works">
        <p>Your GitHub profile shows the README of a special repository named after you, for example <code>octocat/octocat</code>. GitStats adds one workflow file to that repository. On a schedule, the workflow draws your cards, saves them as images in the repository and updates a marked section of your README.</p>
        <p>You design the layout here in Studio. GitHub does the rest, every four hours.</p>
      </Section>
      <Section title="Three steps">
        <ol className="steps-list">
          <li><div><strong>Profile.</strong> Enter your GitHub username. Studio previews your cards with your data. Without a token, only languages and Developer DNA can use real data; the others show samples until you publish.</div></li>
          <li><div><strong>Design.</strong> Drag cards into rows, pick a theme and adjust card settings. Switch to <em>On GitHub</em> to see the exact result at desktop and phone widths.</div></li>
          <li><div><strong>Publish.</strong> Studio opens GitHub with the workflow file already filled in. Click <em>Commit changes</em>. Your cards appear a minute or two later.</div></li>
        </ol>
        <Callout>Don't have a profile repository yet? Create a public repository with exactly your username as its name. Studio's Publish step links straight to it.</Callout>
      </Section>
      <Section title="What changes in your repository">
        <table><thead><tr><th>File</th><th>What it is</th></tr></thead><tbody>
          <tr><td><code>{WORKFLOW_PATH}</code></td><td>The workflow you commit once. It holds your layout and settings.</td></tr>
          <tr><td><code>gitstats/*.svg</code></td><td>Your cards, regenerated on every run.</td></tr>
          <tr><td><code>README.md</code></td><td>Only the part between <code>{'<!-- gitstats:start -->'}</code> and <code>{'<!-- gitstats:end -->'}</code>. Everything else stays as you wrote it.</td></tr>
        </tbody></table>
      </Section>
    </>,
  },
  {
    id: 'cards',
    title: 'Cards',
    summary: 'Seven cards, each drawn from your GitHub activity. The examples below use sample data.',
    body: () => <>
      <CardGallery />
      <Section title="Where the numbers come from">
        <table><thead><tr><th>Card</th><th>Source</th></tr></thead><tbody>
          <tr><td>Contribution streak</td><td>Your contribution calendar, every year since you joined.</td></tr>
          <tr><td>Developer stats</td><td>Commits, merged pull requests, closed issues, stars and repositories. The score out of 1000 is the sum of the four parts shown on the card.</td></tr>
          <tr><td>Top languages</td><td>Code size per language across up to 100 of your repositories, excluding forks.</td></tr>
          <tr><td>Developer DNA</td><td>The same language data, grouped into five domains. Languages used in two domains are split, for example Python counts half Backend and half Data &amp; AI. The strongest domain reaches the outer ring.</td></tr>
          <tr><td>Commit rhythm</td><td>Up to 100 recent commits from each of your 20 most recently pushed repositories, in your timezone.</td></tr>
          <tr><td>Pull requests</td><td>Lifetime merged, open and closed counts. Merge time, lines and files come from your latest 30 pull requests.</td></tr>
          <tr><td>Milestones</td><td>Six achievements with five tiers each, from Bronze to Diamond.</td></tr>
        </tbody></table>
        <Callout>Hidden languages and skipped repositories apply to both Top languages and Developer DNA, so the two cards always describe the same code.</Callout>
      </Section>
    </>,
  },
  {
    id: 'layout',
    title: 'Layout and themes',
    summary: 'Rows keep your profile tidy on every screen, from a wide monitor to a phone.',
    body: () => <>
      <Section title="Row types">
        <table><thead><tr><th>Row</th><th>Holds</th></tr></thead><tbody>
          <tr><td>Two cards</td><td>Any two standard cards, side by side.</td></tr>
          <tr><td>Full width</td><td>Streak, rhythm or milestones, drawn 840 px wide.</td></tr>
          <tr><td>Stacked + languages</td><td>Two cards stacked on the left and Top languages on the right. The languages card is sized to match the stack.</td></tr>
        </tbody></table>
        <p style={{ marginTop: 12 }}>GitHub removes CSS from READMEs, so GitStats lays out cards with percentage widths. Rows shrink together instead of wrapping onto new lines, whatever the screen size.</p>
      </Section>
      <Section title="Changing your design later">
        <ol className="steps-list">
          <li><div>Open Studio. Your last design is still saved in this browser.</div></li>
          <li><div>Make your changes, then go to <strong>Publish</strong>.</div></li>
          <li><div>Choose <strong>Open existing file</strong>, replace its contents with the new version and commit. The next run uses the new design.</div></li>
        </ol>
      </Section>
      <Section title="Themes">
        <p>Every card uses the same theme. Dark themes suit GitHub's dark mode; GitHub Light suits light mode. Accent colours adjust automatically on light themes so small text stays readable.</p>
      </Section>
    </>,
  },
  {
    id: 'tokens',
    title: 'Tokens and private work',
    summary: 'You need no token to get started. Add one only if you want private contributions counted.',
    body: () => <>
      <Section title="Which token goes where">
        <table><thead><tr><th>Purpose</th><th>Where</th><th>Needed?</th></tr></thead><tbody>
          <tr><td>Generate your cards</td><td>Nothing to set up. The workflow uses GitHub's built-in token.</td><td>No</td></tr>
          <tr><td>Count private work</td><td>A repository secret named <code>GH_TOKEN</code> in your profile repository.</td><td>Optional</td></tr>
          <tr><td>Preview every card in Studio</td><td>Studio's Profile step. Kept in the browser tab only.</td><td>Optional</td></tr>
          <tr><td>Let Studio commit for you</td><td>Studio's Publish step, used once.</td><td>Optional</td></tr>
        </tbody></table>
      </Section>
      <Section title="Add GH_TOKEN for private contributions">
        <ol className="steps-list">
          <li><div>Open <a href="https://github.com/settings/personal-access-tokens/new" target="_blank" rel="noreferrer">GitHub → Settings → Fine-grained tokens</a> and create a token.</div></li>
          <li><div>Under <strong>Repository access</strong>, choose the repositories whose work you want counted, or all repositories.</div></li>
          <li><div>Under <strong>Permissions</strong>, set <strong>Contents</strong> and <strong>Metadata</strong> to read-only. Add <strong>Pull requests</strong> and <strong>Issues</strong> read-only for the pull request and stats cards.</div></li>
          <li><div>Copy the token. In your profile repository open <strong>Settings → Secrets and variables → Actions</strong>, click <strong>New repository secret</strong>, name it <code>GH_TOKEN</code> and paste the token.</div></li>
          <li><div>Run the workflow from the <strong>Actions</strong> tab, or wait for the next scheduled run.</div></li>
        </ol>
        <Callout>Set an expiry date on the token and renew the secret before it expires. If it expires, runs fail with an authentication error until you replace it.</Callout>
      </Section>
      <Section title="Privacy">
        <p>Studio talks only to GitHub. Tokens you enter in Studio stay in the open tab and are never saved, exported or written into the workflow. Your design is stored in your browser's local storage.</p>
      </Section>
    </>,
  },
  {
    id: 'troubleshooting',
    title: 'Troubleshooting',
    summary: 'The common problems, and how to fix them.',
    body: () => <>
      <Section title="My cards don't appear">
        <ul>
          <li>Open the <strong>Actions</strong> tab of your profile repository and check the latest <em>GitStats</em> run. The log names the card that failed and why.</li>
          <li>Make sure the repository name matches your username exactly and the repository is public.</li>
          <li>If the run says it can't push, check that the workflow still has <code>permissions: contents: write</code>.</li>
        </ul>
      </Section>
      <Section title="My cards stopped updating">
        <p>GitHub pauses scheduled workflows in repositories with no activity for 60 days. Open <strong>Actions</strong>, select <em>GitStats</em> and enable it again, or run it manually. An expired <code>GH_TOKEN</code> also stops updates; replace the secret.</p>
      </Section>
      <Section title="Numbers look different from GitHub's">
        <p>Without <code>GH_TOKEN</code>, private work is not counted. Rhythm and pull request timing use recent samples, not your entire history; the cards say so. GitHub also caches images for a few minutes, so a fresh run can take a moment to show.</p>
      </Section>
      <Section title="Remove GitStats">
        <p>Delete <code>{WORKFLOW_PATH}</code>, the <code>gitstats</code> folder and the marked section of your README.</p>
      </Section>
    </>,
  },
  {
    id: 'advanced',
    title: 'Advanced',
    summary: 'Action inputs, the command-line engine, and running your own copy.',
    body: () => <>
      <Section title="Action inputs">
        <p>The workflow calls <code>{ENGINE_REPO}@{ACTION_REF}</code>. You can edit these inputs in the workflow file directly.</p>
        <table><thead><tr><th>Input</th><th>Default</th><th>Description</th></tr></thead><tbody>
          <tr><td>config</td><td>required</td><td>Layout and settings exported by Studio (JSON).</td></tr>
          <tr><td>token</td><td>empty</td><td>Token for private data, usually <code>{'${{ secrets.GH_TOKEN }}'}</code>.</td></tr>
          <tr><td>readme</td><td>README.md</td><td>File whose marked section is updated.</td></tr>
          <tr><td>output-dir</td><td>gitstats</td><td>Folder for the card images.</td></tr>
          <tr><td>commit</td><td>true</td><td>Set to false to generate files without committing.</td></tr>
        </tbody></table>
      </Section>
      <Section title="Command-line engine">
        <p>Every card comes from a native Zig program. You can run it yourself:</p>
        <pre>{`zig build -Doptimize=ReleaseFast
GH_TOKEN=... ./zig-out/bin/git_stats --stats --username=octocat --output=stats.svg`}</pre>
        <p>All flags are listed in the <a href="https://github.com/adityapandeydev/git-stats/blob/main/docs/cli.md" target="_blank" rel="noreferrer">CLI reference</a>. Workflows that call the CLI directly, including ones exported by earlier versions of Studio, keep working.</p>
      </Section>
      <Section title="Host your own Studio">
        <p>Studio is a static site. Fork the repository, enable GitHub Pages with the included workflow, and change <code>ENGINE_REPO</code> in <code>frontend/src/services/profileConfig.js</code> if your workflows should use your fork's action.</p>
      </Section>
    </>,
  },
]
