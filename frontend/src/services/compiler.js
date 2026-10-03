/**
 * Compiles user playground state into clean Profile README HTML
 * and automated GitHub Actions workflow YAML.
 */

export function generateProfileHtml(username, activeCards, layoutMode = 'pillar-right') {
  const user = username.trim() || 'YOUR_USERNAME'
  const rawBase = `https://raw.githubusercontent.com/${user}/git-stats/main/generated`

  // Case 1: Flagship Pillar-Right (Languages on right, other cards stacked on left)
  const langCard = activeCards.find((c) => c.id === 'languages')
  const leftCards = activeCards.filter((c) => c.id !== 'languages')

  if (layoutMode === 'pillar-right' && langCard && leftCards.length > 0) {
    let out = `<div align="left">\n`
    out += `  <!-- Right Pillar: Languages -->\n`
    out += `  <img align="right" src="${rawBase}/languages.svg" width="${langCard.width || 400}" alt="Top Languages" />\n`
    out += `  \n`

    leftCards.forEach((card, idx) => {
      out += `  <!-- Card: ${card.id} -->\n`
      out += `  <img src="${rawBase}/${card.id}.svg" width="${card.width || 424}" alt="${card.id}" />\n`
      if (idx < leftCards.length - 1) {
        out += `  <br/>\n`
      }
    })
    out += `</div>`
    return out
  }

  // Case 2: Linear / Grid Flow (e.g. Milestones hero on top, followed by grid)
  let out = `<div align="center">\n`
  activeCards.forEach((card, idx) => {
    out += `  <img src="${rawBase}/${card.id}.svg" width="${card.width || 424}" alt="${card.id}" />\n`
    // Add spacing or linebreaks if width >= 800
    if (card.width >= 800 || (idx % 2 === 1 && idx < activeCards.len - 1)) {
      out += `  <br/>\n`
    }
  })
  out += `</div>`
  return out
}

export function generateWorkflowYaml(username, activeCards, theme = 'tokyonight', hideLangs = 'jupyter notebook,qml,javascript,html,css,tex') {
  let stepIndex = 2
  let stepsYaml = ''

  activeCards.forEach((card) => {
    const cardId = card.id
    if (cardId === 'languages') {
      const count = card.langsCount || 12
      const w = card.width || 400
      const h = card.height || 364
      stepsYaml += `          # ${stepIndex}. Generate Languages Card\n`
      stepsYaml += `          ./zig-out/bin/git_stats --generate \\\n`
      stepsYaml += `            --username="\${{ github.repository_owner }}" \\\n`
      stepsYaml += `            --langs-count=${count} \\\n`
      stepsYaml += `            --theme="${theme}" \\\n`
      stepsYaml += `            --layout="standard" \\\n`
      stepsYaml += `            --columns=2 \\\n`
      stepsYaml += `            --card-width=${w} \\\n`
      stepsYaml += `            --card-height=${h} \\\n`
      stepsYaml += `            --border-radius=4.5 \\\n`
      if (hideLangs) {
        stepsYaml += `            --hide="${hideLangs}" \\\n`
      }
      stepsYaml += `            --output="generated/languages.svg"\n\n`
    } else if (cardId === 'streak') {
      const w = card.width || 424
      const h = card.height || 180
      stepsYaml += `          # ${stepIndex}. Generate Streak Card\n`
      stepsYaml += `          ./zig-out/bin/git_stats --streak \\\n`
      stepsYaml += `            --username="\${{ github.repository_owner }}" \\\n`
      stepsYaml += `            --theme="${theme}" \\\n`
      stepsYaml += `            --card-width=${w} \\\n`
      stepsYaml += `            --card-height=${h} \\\n`
      stepsYaml += `            --border-radius=4.5 \\\n`
      stepsYaml += `            --output="generated/streak.svg"\n\n`
    } else if (cardId === 'stats') {
      const w = card.width || 424
      const h = card.height || 180
      const timeframe = card.timeframe || 'all-time'
      stepsYaml += `          # ${stepIndex}. Generate Developer Stats Card\n`
      stepsYaml += `          ./zig-out/bin/git_stats --stats \\\n`
      stepsYaml += `            --username="\${{ github.repository_owner }}" \\\n`
      stepsYaml += `            --theme="${theme}" \\\n`
      stepsYaml += `            --timeframe="${timeframe}" \\\n`
      stepsYaml += `            --card-width=${w} \\\n`
      stepsYaml += `            --card-height=${h} \\\n`
      stepsYaml += `            --border-radius=4.5 \\\n`
      stepsYaml += `            --output="generated/stats.svg"\n\n`
    } else if (cardId === 'rhythm') {
      const w = card.width || 424
      const h = card.height || 180
      stepsYaml += `          # ${stepIndex}. Generate Commit Rhythm Card\n`
      stepsYaml += `          ./zig-out/bin/git_stats --rhythm \\\n`
      stepsYaml += `            --username="\${{ github.repository_owner }}" \\\n`
      stepsYaml += `            --theme="${theme}" \\\n`
      stepsYaml += `            --card-width=${w} \\\n`
      stepsYaml += `            --card-height=${h} \\\n`
      stepsYaml += `            --border-radius=4.5 \\\n`
      stepsYaml += `            --output="generated/rhythm.svg"\n\n`
    } else if (cardId === 'radar') {
      const w = card.width || 424
      const h = card.height || 180
      stepsYaml += `          # ${stepIndex}. Generate Developer DNA Radar Card\n`
      stepsYaml += `          ./zig-out/bin/git_stats --radar \\\n`
      stepsYaml += `            --username="\${{ github.repository_owner }}" \\\n`
      stepsYaml += `            --theme="${theme}" \\\n`
      stepsYaml += `            --card-width=${w} \\\n`
      stepsYaml += `            --card-height=${h} \\\n`
      stepsYaml += `            --border-radius=4.5 \\\n`
      stepsYaml += `            --output="generated/radar.svg"\n\n`
    } else if (cardId === 'velocity') {
      const w = card.width || 424
      const h = card.height || 180
      stepsYaml += `          # ${stepIndex}. Generate PR Velocity Card\n`
      stepsYaml += `          ./zig-out/bin/git_stats --velocity \\\n`
      stepsYaml += `            --username="\${{ github.repository_owner }}" \\\n`
      stepsYaml += `            --theme="${theme}" \\\n`
      stepsYaml += `            --card-width=${w} \\\n`
      stepsYaml += `            --card-height=${h} \\\n`
      stepsYaml += `            --border-radius=4.5 \\\n`
      stepsYaml += `            --output="generated/velocity.svg"\n\n`
    } else if (cardId === 'milestones') {
      const w = card.width || 840
      const h = card.height || 180
      stepsYaml += `          # ${stepIndex}. Generate Career Milestones Card\n`
      stepsYaml += `          ./zig-out/bin/git_stats --milestones \\\n`
      stepsYaml += `            --username="\${{ github.repository_owner }}" \\\n`
      stepsYaml += `            --theme="${theme}" \\\n`
      stepsYaml += `            --card-width=${w} \\\n`
      stepsYaml += `            --card-height=${h} \\\n`
      stepsYaml += `            --border-radius=4.5 \\\n`
      stepsYaml += `            --output="generated/milestones.svg"\n\n`
    }
    stepIndex += 1
  })

  return `name: Generate Stats Cards

on:
  schedule:
    # Runs every 4 hours
    - cron: '0 */4 * * *'
  workflow_dispatch:
  push:
    branches:
      - main
    paths:
      - '.github/workflows/generate-stats.yml'

permissions:
  contents: write

jobs:
  generate:
    name: Generate GitStats Profile Cards
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Set up Zig
        uses: mlugg/setup-zig@v2
        with:
          version: "0.16.0"

      - name: Build and Generate Profile Stats SVG Cards
        env:
          # Uses GH_TOKEN repository secret if provided
          GH_TOKEN: \${{ secrets.GH_TOKEN }}
        run: |
          # 1. Build release binary
          zig build -Doptimize=ReleaseFast

${stepsYaml.trimEnd()}

      - name: Commit and Push Updated Cards
        run: |
          git config --local user.email "github-actions[bot]@users.noreply.github.com"
          git config --local user.name "github-actions[bot]"
          git add -f generated/*.svg
          git diff --staged --quiet || (git commit -m "chore(stats): update profile statistics cards [skip ci]" && git push)
`
}

export function getGitHubWebEditUrl(username) {
  const user = username.trim() || 'YOUR_USERNAME'
  return `https://github.com/${user}/git-stats/edit/main/.github/workflows/generate-stats.yml`
}
