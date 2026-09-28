// GitStats Studio - Customizer Logic & Live Preview

(function () {
  'use strict';

  // Global Application State
  const state = {
    username: 'demo',
    token: '',
    langsCount: 8,
    hiddenLangs: new Set(),
    manualHide: '',
    layout: 'standard',
    columns: 0,
    cardWidth: 450,
    theme: 'tokyonight',
    customTitle: '',
    hideTitle: false,
    animate: true,
    hideBorder: false,
    excludeRepo: '',
    colorOverrides: {
      title: '',
      text: '',
      bg: '',
      border: ''
    },
    activeTab: 'markdown',
    detectedLanguages: [],
    availableThemes: []
  };

  // DOM Elements
  const usernameInput = document.getElementById('username-input');
  const tokenInput = document.getElementById('token-input');
  const btnFetchLangs = document.getElementById('btn-fetch-langs');
  const langsCountSlider = document.getElementById('langs-count-slider');
  const langsCountVal = document.getElementById('langs-count-val');
  const langChipsMatrix = document.getElementById('lang-chips-matrix');
  const hideInputManual = document.getElementById('hide-input-manual');
  const chipHideMarkup = document.getElementById('chip-hide-markup');
  const chipClearHidden = document.getElementById('chip-clear-hidden');
  const excludeRepoInput = document.getElementById('exclude-repo-input');
  const layoutPillGroup = document.getElementById('layout-pill-group');
  const columnsSelect = document.getElementById('columns-select');
  const cardWidthSlider = document.getElementById('card-width-slider');
  const cardWidthVal = document.getElementById('card-width-val');
  const customTitleInput = document.getElementById('custom-title-input');
  const toggleHideTitle = document.getElementById('toggle-hide-title');
  const toggleAnimate = document.getElementById('toggle-animate');
  const toggleHideBorder = document.getElementById('toggle-hide-border');
  const themeGrid = document.getElementById('theme-grid');
  const svgContainer = document.getElementById('svg-container');
  const previewStage = document.getElementById('preview-stage');
  const snippetCode = document.getElementById('snippet-code');
  const codeLangLabel = document.getElementById('code-lang-label');
  const btnCopyCode = document.getElementById('btn-copy-code');
  const btnDownloadSvg = document.getElementById('btn-download-svg');
  const btnOpenNewTab = document.getElementById('btn-open-new-tab');
  const toastNotification = document.getElementById('toast-notification');
  const metaLangCount = document.getElementById('meta-lang-count');
  const metaTheme = document.getElementById('meta-theme');

  // Color Pickers
  const colorTitle = document.getElementById('color-title');
  const hexTitle = document.getElementById('hex-title');
  const colorText = document.getElementById('color-text');
  const hexText = document.getElementById('hex-text');
  const colorBg = document.getElementById('color-bg');
  const hexBg = document.getElementById('hex-bg');
  const colorBorder = document.getElementById('color-border');
  const hexBorder = document.getElementById('hex-border');
  const btnResetColors = document.getElementById('btn-reset-colors');

  // Debounce helper
  let updateTimeout = null;
  function triggerPreviewUpdate(delay = 100) {
    clearTimeout(updateTimeout);
    updateTimeout = setTimeout(updatePreview, delay);
  }

  // Build API Query URL
  function buildApiUrl(isAbsolute = false) {
    const params = new URLSearchParams();
    params.set('username', state.username || 'demo');

    if (state.langsCount !== 8) {
      params.set('langs_count', state.langsCount);
    }

    // Combine hidden set and manual hide
    const allHidden = new Set(state.hiddenLangs);
    if (state.manualHide.trim()) {
      state.manualHide.split(',').forEach(item => {
        const c = item.trim().toLowerCase();
        if (c) allHidden.add(c);
      });
    }

    if (allHidden.size > 0) {
      params.set('hide', Array.from(allHidden).join(','));
    }

    if (state.layout !== 'standard') {
      params.set('layout', state.layout);
    }

    if (state.columns > 0) {
      params.set('columns', state.columns);
    }

    if (state.cardWidth !== 450) {
      params.set('card_width', state.cardWidth);
    }

    if (state.theme !== 'tokyonight') {
      params.set('theme', state.theme);
    }

    if (state.customTitle.trim()) {
      params.set('title', state.customTitle.trim());
    }

    if (state.hideTitle) {
      params.set('hide_title', 'true');
    }

    if (!state.animate) {
      params.set('animation', 'false');
    }

    if (state.hideBorder) {
      params.set('hide_border', 'true');
    }

    if (state.excludeRepo.trim()) {
      params.set('exclude_repo', state.excludeRepo.trim());
    }

    // Color overrides
    if (state.colorOverrides.title) params.set('title_color', state.colorOverrides.title.replace('#', ''));
    if (state.colorOverrides.text) params.set('text_color', state.colorOverrides.text.replace('#', ''));
    if (state.colorOverrides.bg) params.set('bg_color', state.colorOverrides.bg.replace('#', ''));
    if (state.colorOverrides.border) params.set('border_color', state.colorOverrides.border.replace('#', ''));

    const base = isAbsolute ? window.location.origin : '';
    return `${base}/api/top-langs?${params.toString()}`;
  }

  // Update Live Preview
  let currentSvgRaw = '';
  async function updatePreview() {
    const url = buildApiUrl(false);
    btnOpenNewTab.href = buildApiUrl(true);

    try {
      const resp = await fetch(url);
      if (!resp.ok && resp.status !== 200) {
        throw new Error(`HTTP ${resp.status}`);
      }
      const svgText = await resp.text();
      currentSvgRaw = svgText;
      svgContainer.innerHTML = svgText;

      // Update metadata display
      metaLangCount.textContent = `${state.langsCount} languages`;
      metaTheme.textContent = state.theme;

      // Update code snippets
      updateCodeSnippet();
    } catch (err) {
      console.error('Preview error:', err);
    }
  }

  // Update Code Snippet Box
  function updateCodeSnippet() {
    const fullUrl = buildApiUrl(true);
    let code = '';

    if (state.activeTab === 'markdown') {
      code = `[![Most Used Languages](${fullUrl})](https://github.com/${state.username || 'username'})`;
      codeLangLabel.textContent = 'Markdown';
    } else if (state.activeTab === 'html') {
      code = `<a href="https://github.com/${state.username || 'username'}">\n  <img src="${fullUrl}" alt="Most Used Languages" />\n</a>`;
      codeLangLabel.textContent = 'HTML';
    } else {
      code = fullUrl;
      codeLangLabel.textContent = 'Direct URL';
    }

    snippetCode.textContent = code;
  }

  // Fetch Languages for User
  async function fetchUserLanguages() {
    const user = usernameInput.value.trim() || 'demo';
    state.username = user;

    btnFetchLangs.disabled = true;
    const btnText = btnFetchLangs.querySelector('.btn-text');
    const btnLoader = btnFetchLangs.querySelector('.btn-loader');
    btnText.style.display = 'none';
    btnLoader.style.display = 'inline-block';

    try {
      const params = new URLSearchParams();
      params.set('username', user);
      if (state.token) params.set('token', state.token);
      if (state.excludeRepo) params.set('exclude_repo', state.excludeRepo);

      const resp = await fetch(`/api/languages?${params.toString()}`);
      if (!resp.ok) {
        throw new Error('Failed to fetch languages');
      }

      const data = await resp.json();
      state.detectedLanguages = data.languages || [];
      renderLanguageChips();
      triggerPreviewUpdate(50);
    } catch (err) {
      console.error('Error fetching user languages:', err);
      showToast('Could not load languages for user. Check username or rate limit.');
    } finally {
      btnFetchLangs.disabled = false;
      btnText.style.display = 'inline';
      btnLoader.style.display = 'none';
    }
  }

  // Render Language Chips Matrix
  function renderLanguageChips() {
    if (!state.detectedLanguages || state.detectedLanguages.length === 0) {
      langChipsMatrix.innerHTML = `<span class="chips-loading">No languages found.</span>`;
      return;
    }

    langChipsMatrix.innerHTML = '';
    state.detectedLanguages.forEach(lang => {
      const isHidden = state.hiddenLangs.has(lang.name.toLowerCase());
      const chip = document.createElement('button');
      chip.type = 'button';
      chip.className = `lang-chip-item ${isHidden ? 'is-hidden' : ''}`;
      chip.title = `Click to ${isHidden ? 'show' : 'hide'} ${lang.name} (${lang.percentage.toFixed(1)}%)`;
      chip.innerHTML = `
        <span class="lang-dot" style="background-color: ${lang.color || '#586069'}"></span>
        <span>${lang.name}</span>
        <span style="opacity: 0.7; font-size: 0.7rem;">${lang.percentage.toFixed(1)}%</span>
      `;

      chip.addEventListener('click', () => {
        const key = lang.name.toLowerCase();
        if (state.hiddenLangs.has(key)) {
          state.hiddenLangs.delete(key);
        } else {
          state.hiddenLangs.add(key);
        }
        renderLanguageChips();
        triggerPreviewUpdate();
      });

      langChipsMatrix.appendChild(chip);
    });
  }

  // Load Preset Themes from API
  async function loadThemes() {
    try {
      const resp = await fetch('/api/themes');
      if (!resp.ok) throw new Error('Failed to load themes');
      state.availableThemes = await resp.json();
      renderThemeGrid();
    } catch (err) {
      console.error('Failed to load themes:', err);
    }
  }

  // Render Theme Grid
  function renderThemeGrid() {
    themeGrid.innerHTML = '';
    state.availableThemes.forEach(t => {
      const card = document.createElement('div');
      card.className = `theme-card ${state.theme === t.name ? 'active' : ''}`;
      card.innerHTML = `
        <div class="theme-card-preview" style="background-color: ${t.bg_color}; border-color: ${t.border_color};">
          <div class="theme-preview-dots">
            <span class="theme-preview-dot" style="background-color: ${t.title_color}"></span>
            <span class="theme-preview-dot" style="background-color: ${t.accent_color}"></span>
            <span class="theme-preview-dot" style="background-color: ${t.text_color}"></span>
          </div>
          <div class="theme-preview-line" style="background-color: ${t.title_color}"></div>
        </div>
        <span class="theme-card-name">${t.label || t.name}</span>
      `;

      card.addEventListener('click', () => {
        state.theme = t.name;
        // Sync color pickers to theme defaults
        colorTitle.value = t.title_color;
        hexTitle.value = t.title_color;
        colorText.value = t.text_color;
        hexText.value = t.text_color;
        colorBg.value = t.bg_color;
        hexBg.value = t.bg_color;
        colorBorder.value = t.border_color;
        hexBorder.value = t.border_color;
        state.colorOverrides = { title: '', text: '', bg: '', border: '' };

        document.querySelectorAll('.theme-card').forEach(c => c.classList.remove('active'));
        card.classList.add('active');
        triggerPreviewUpdate();
      });

      themeGrid.appendChild(card);
    });
  }

  // Show Toast
  let toastTimer = null;
  function showToast(message) {
    clearTimeout(toastTimer);
    toastNotification.textContent = message;
    toastNotification.classList.add('show');
    toastTimer = setTimeout(() => {
      toastNotification.classList.remove('show');
    }, 2500);
  }

  // Event Listeners Setup
  function initListeners() {
    // Username input
    usernameInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        fetchUserLanguages();
      }
    });

    btnFetchLangs.addEventListener('click', fetchUserLanguages);

    tokenInput.addEventListener('input', (e) => {
      state.token = e.target.value.trim();
    });

    // Languages count slider
    langsCountSlider.addEventListener('input', (e) => {
      state.langsCount = parseInt(e.target.value, 10);
      langsCountVal.textContent = state.langsCount;
      triggerPreviewUpdate();
    });

    // Manual hide input
    hideInputManual.addEventListener('input', (e) => {
      state.manualHide = e.target.value;
      triggerPreviewUpdate(300);
    });

    // Quick hide HTML/CSS/MD
    chipHideMarkup.addEventListener('click', () => {
      ['html', 'css', 'scss', 'markdown'].forEach(l => state.hiddenLangs.add(l));
      renderLanguageChips();
      triggerPreviewUpdate();
    });

    // Clear hidden
    chipClearHidden.addEventListener('click', () => {
      state.hiddenLangs.clear();
      state.manualHide = '';
      hideInputManual.value = '';
      renderLanguageChips();
      triggerPreviewUpdate();
    });

    // Exclude repo
    excludeRepoInput.addEventListener('input', (e) => {
      state.excludeRepo = e.target.value;
      triggerPreviewUpdate(350);
    });

    // Layout radio pills
    layoutPillGroup.querySelectorAll('.radio-pill').forEach(pill => {
      pill.addEventListener('click', () => {
        layoutPillGroup.querySelectorAll('.radio-pill').forEach(p => p.classList.remove('active'));
        pill.classList.add('active');
        const input = pill.querySelector('input');
        input.checked = true;
        state.layout = input.value;

        // Toggle columns visibility if donut or compact
        const colGroup = document.getElementById('col-group');
        if (state.layout === 'standard') {
          colGroup.style.display = 'block';
        } else {
          colGroup.style.display = 'none';
        }

        triggerPreviewUpdate();
      });
    });

    // Columns select
    columnsSelect.addEventListener('change', (e) => {
      state.columns = parseInt(e.target.value, 10);
      triggerPreviewUpdate();
    });

    // Card width slider
    cardWidthSlider.addEventListener('input', (e) => {
      state.cardWidth = parseInt(e.target.value, 10);
      cardWidthVal.textContent = `${state.cardWidth}px`;
      triggerPreviewUpdate();
    });

    // Custom title
    customTitleInput.addEventListener('input', (e) => {
      state.customTitle = e.target.value;
      triggerPreviewUpdate(300);
    });

    // Toggles
    toggleHideTitle.addEventListener('change', (e) => {
      state.hideTitle = e.target.checked;
      triggerPreviewUpdate();
    });

    toggleAnimate.addEventListener('change', (e) => {
      state.animate = e.target.checked;
      triggerPreviewUpdate();
    });

    toggleHideBorder.addEventListener('change', (e) => {
      state.hideBorder = e.target.checked;
      triggerPreviewUpdate();
    });

    // Canvas background options
    document.querySelectorAll('.canvas-bg-switcher .bg-opt').forEach(opt => {
      opt.style.backgroundColor = opt.dataset.canvas;
      opt.addEventListener('click', () => {
        document.querySelectorAll('.canvas-bg-switcher .bg-opt').forEach(b => b.classList.remove('active'));
        opt.classList.add('active');
        previewStage.style.backgroundColor = opt.dataset.canvas;
      });
    });

    // Embed Tabs
    document.querySelectorAll('.tab-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        state.activeTab = btn.dataset.tab;
        updateCodeSnippet();
      });
    });

    // Copy Code button
    btnCopyCode.addEventListener('click', async () => {
      const code = snippetCode.textContent;
      try {
        await navigator.clipboard.writeText(code);
        showToast('Copied to clipboard!');
      } catch (err) {
        showToast('Failed to copy. Please select and copy manually.');
      }
    });

    // Download SVG
    btnDownloadSvg.addEventListener('click', () => {
      if (!currentSvgRaw) return;
      const blob = new Blob([currentSvgRaw], { type: 'image/svg+xml;charset=utf-8' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${state.username || 'github'}-languages.svg`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      showToast('Downloaded SVG card!');
    });

    // Custom Color Overrides
    function bindColorInput(picker, hexInput, key) {
      picker.addEventListener('input', (e) => {
        hexInput.value = e.target.value;
        state.colorOverrides[key] = e.target.value;
        triggerPreviewUpdate();
      });
      hexInput.addEventListener('input', (e) => {
        let val = e.target.value.trim();
        if (!val.startsWith('#')) val = '#' + val;
        if (/^#[0-9A-Fa-f]{6}$/.test(val)) {
          picker.value = val;
          state.colorOverrides[key] = val;
          triggerPreviewUpdate();
        }
      });
    }

    bindColorInput(colorTitle, hexTitle, 'title');
    bindColorInput(colorText, hexText, 'text');
    bindColorInput(colorBg, hexBg, 'bg');
    bindColorInput(colorBorder, hexBorder, 'border');

    btnResetColors.addEventListener('click', () => {
      state.colorOverrides = { title: '', text: '', bg: '', border: '' };
      const currentT = state.availableThemes.find(t => t.name === state.theme) || {};
      if (currentT.title_color) {
        colorTitle.value = currentT.title_color;
        hexTitle.value = currentT.title_color;
        colorText.value = currentT.text_color;
        hexText.value = currentT.text_color;
        colorBg.value = currentT.bg_color;
        hexBg.value = currentT.bg_color;
        colorBorder.value = currentT.border_color;
        hexBorder.value = currentT.border_color;
      }
      triggerPreviewUpdate();
      showToast('Reset colors to theme defaults.');
    });
  }

  // Initialization
  async function init() {
    initListeners();
    await loadThemes();
    await fetchUserLanguages();
  }

  init();
})();
