# GitStats - Dynamic GitHub Stats & Language Card System

A fast, lightweight, and **100% serverless** GitHub language statistics card generator built with Go and powered by GitHub Actions.

Designed to overcome the limitations of existing stats cards with complete customization: **display 8, 10, 12, 16+ languages**, hide unwanted languages with automatic percentage recalculation, and perfectly match your profile layout dimensions with zero awkward whitespace.

<div align="center">
  <img src="https://raw.githubusercontent.com/adityapandeydev/git-stats/main/languages.svg" alt="GitStats Most Used Languages" />
</div>

---

## Features

- **Break the 6-Language Limit**: Display **8, 10, 12, 16+** languages in an auto-adjusting multi-column layout.
- **100% Serverless & Free**: Runs via GitHub Actions on a schedule and on every code push. Zero hosting costs, zero servers to maintain.
- **Private Repository Support**: Securely scans both public and private repositories via your encrypted GitHub secret token.
- **Language Hiding & Filtering**: Filter out languages you don't want (e.g. `html`, `css`, `jinja`) with automatic percentage recalculation.
- **Column-Major Layout**: Ranks flow top-to-bottom on the left column, then continue on the right column. Odd counts cleanly show one less on the right.
- **Customizable Dimensions**: Customize width and height to match the combined height of your Streak and Stats cards perfectly.
- **Multiple Layouts**:
  - `standard` (Segmented progress bar + multi-column grid)
  - `donut` (Centered radial donut chart with bottom 3-column grid)
  - `compact` (Minimal badge bar)
- **10 Curated Themes**: Tokyo Night, GitHub Dark, Catppuccin Mocha, Dracula, Nord, Synthwave, One Dark, Radical, OLED Midnight, and GitHub Light.
- **Interactive Web Studio**: Optional local/browser customizer with live real-time SVG preview and palette toggles.

---

## Quick Setup for Your GitHub Profile (3 Minutes)

### Step 1: Fork this Repository
Click the **Fork** button at the top right of this repository to create your own copy (e.g. `yourname/git-stats`).

### Step 2: Add Your GitHub Secret Token (For Private Repos)
To allow the Action to scan your private repositories and grant a 5,000 req/hr rate limit:
1. Generate a Personal Access Token on GitHub at: [github.com/settings/tokens](https://github.com/settings/tokens) *(Classic token with `repo` scope)*.
2. In your forked repository, go to: **Settings** -> **Secrets and variables** -> **Actions**.
3. Click **New repository secret**:
   - Name: `GH_TOKEN`
   - Value: Paste your GitHub Personal Access Token.

*(Note: If you only want to track public repositories, you can skip this step—the workflow will automatically use GitHub's built-in token!)*

### Step 3: Run the Workflow
1. Go to the **Actions** tab in your repository.
2. Select **Generate GitHub Language Stats** in the left sidebar.
3. Click **Run workflow** -> **Run workflow**.

The workflow will run, generate your customized `languages.svg`, and commit it directly to your `main` branch.

### Step 4: Embed into Your Profile `README.md`
In your GitHub profile repository (`username/username/README.md`), add:

```markdown
[![Most Used Languages](https://raw.githubusercontent.com/YOUR_USERNAME/git-stats/main/languages.svg)](https://github.com/YOUR_USERNAME/git-stats)
```

*(Replace `YOUR_USERNAME` with your GitHub username).*

---

## Perfect Profile Layout Alignment

If you use a **Streak Stats** card and an **Overall Stats** card stacked on the left, you can place this **Languages Card** on the right so both columns have matching heights and widths with zero awkward whitespace:

```html
<div align="center">
  <table>
    <tr>
      <!-- Left Column: Streak + Overall Stats stacked -->
      <td valign="top">
        <img src="https://github-readme-streak-stats.herokuapp.com/?user=YOUR_USERNAME&theme=tokyonight" /><br/>
        <img src="https://github-readme-stats.vercel.app/api?username=YOUR_USERNAME&show_icons=true&theme=tokyonight" />
      </td>
      <!-- Right Column: 12-Language Card filling the full combined height -->
      <td valign="top">
        <a href="https://github.com/YOUR_USERNAME/git-stats">
          <img src="https://raw.githubusercontent.com/YOUR_USERNAME/git-stats/main/languages.svg" />
        </a>
      </td>
    </tr>
  </table>
</div>
```

---

## Customizing Your Card

You can customize your card settings by editing the workflow file at `.github/workflows/generate-stats.yml`:

```yaml
- name: Generate Language Stats SVG Card
  env:
    GH_TOKEN: ${{ secrets.GH_TOKEN || secrets.GITHUB_TOKEN }}
  run: |
    go run ./cmd/server --generate \
      --username="${{ github.repository_owner }}" \
      --langs-count=12 \
      --theme="tokyonight" \
      --layout="standard" \
      --columns=2 \
      --card-width=495 \
      --card-height=405 \
      --hide="html,css" \
      --output="languages.svg"
```

### CLI Flag Reference

| Flag | Default | Description |
| :--- | :---: | :--- |
| `--username`, `-u` | `GITHUB_REPOSITORY_OWNER` | Target GitHub username |
| `--langs-count`, `-n` | `12` | Number of languages to display (e.g. 8, 10, 12, 16+) |
| `--hide` | `""` | Comma-separated languages to hide (e.g. `html,css,jinja`) |
| `--theme` | `tokyonight` | Card theme (`tokyonight`, `github_dark`, `catppuccin`, `dracula`, `nord`, etc.) |
| `--layout` | `standard` | Card layout: `standard` (bar + grid), `donut`, `compact` |
| `--columns` | `2` | Number of grid columns (`0` for auto, `1`, `2`, `3`) |
| `--card-width` | `495` | Card width in pixels |
| `--card-height` | `405` | Card height in pixels (matches 2 left cards combined) |
| `--output`, `-o` | `languages.svg` | Output file path |
| `--exclude-repo` | `""` | Comma-separated repository names to ignore |
| `--hide-title` | `false` | Hide the card header title |
| `--hide-border` | `false` | Hide the card outline border |
| `--animate` | `true` | Enable/disable SVG load animations |

---

## Built-in Themes

| Theme Name | Description |
| :--- | :--- |
| `tokyonight` | Modern dark navy developer palette (matches screenshot default) |
| `github_dark` | GitHub's native dark mode (`#0d1117`) |
| `dracula` | Classic Dracula vampire theme |
| `catppuccin` | Catppuccin Mocha cozy pastel dark palette |
| `nord` | Arctic north-bluish palette |
| `synthwave` | Vibrant 80s neon magenta & cyan |
| `onedark` | Atom One Dark theme |
| `radical` | High-contrast retro theme |
| `midnight` | Deep OLED black (`#050508`) with electric indigo |
| `github_light` | Clean GitHub light mode theme |

---

## Optional: Running the Web Studio Locally

If you'd like to use the visual customizer playground with live real-time previews:

```bash
# Clone the repository
git clone https://github.com/adityapandeydev/git-stats.git
cd git-stats

# Run the local server
go run ./cmd/server
```

Open your browser to: **`http://localhost:8080/`**

