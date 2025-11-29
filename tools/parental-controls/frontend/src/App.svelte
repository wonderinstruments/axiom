<script>
  import { onMount, onDestroy } from 'svelte';
  import { AuthenticateSudo, IsAuthenticated, ReadNixConfig, SaveNixConfig, Quit } from '../wailsjs/go/main/App';
  import { EventsOn, EventsOff } from '../wailsjs/runtime/runtime';

  let authenticated = false;
  let password = '';
  let loginError = '';
  let config = null;
  let editableConfig = null;
  let loading = false;
  let error = '';
  let saving = false;
  let saveStatus = '';
  let rebuildOutput = '';
  let isDirty = false;

  // Disable right-click context menu
  let disableContextMenu;

  // Simple in-page menu state
  let menuOpen = '';
  function toggleMenu(id) {
    menuOpen = menuOpen === id ? '' : id;
  }
  function closeMenu() {
    menuOpen = '';
  }
  async function onMenuAction(action) {
    if (action === 'quit') {
      await Quit();
    } else if (action === 'load-current') {
      if (!loading && authenticated) {
        await loadConfig();
      }
    }
    closeMenu();
  }

  onMount(async () => {
    try {
      authenticated = await IsAuthenticated();
      if (authenticated) {
        await loadConfig();
      }
    } catch (err) {
      console.error('Error checking auth:', err);
    }

    // Listen for rebuild output events
    EventsOn('rebuild-output', (output) => {
      rebuildOutput = output;
      console.log('[rebuild-output]', output);
    });

    // Disable right-click native context menu
    disableContextMenu = (e) => {
      e.preventDefault();
    };
    document.addEventListener('contextmenu', disableContextMenu);

    // Menu: Config -> Load Current
    EventsOn('menu-load-current', async () => {
      if (!loading && authenticated) {
        await loadConfig();
      }
    });
  });

  onDestroy(() => {
    EventsOff('rebuild-output');
    EventsOff('menu-load-current');
    if (disableContextMenu) {
      document.removeEventListener('contextmenu', disableContextMenu);
    }
  });

  async function handleLogin() {
    loginError = '';
    loading = true;
    try {
      await AuthenticateSudo(password);
      authenticated = true;
      password = ''; // Clear password
      await loadConfig();
    } catch (err) {
      loginError = 'Authentication failed. Please check your password.';
      console.error('Login error:', err);
    } finally {
      loading = false;
    }
  }

  async function loadConfig() {
    loading = true;
    error = '';
    try {
      config = await ReadNixConfig();
      editableConfig = JSON.parse(JSON.stringify(config)); // Deep clone
      isDirty = false;
    } catch (err) {
      error = `Failed to load config: ${err}`;
      console.error('Config load error:', err);
    } finally {
      loading = false;
    }
  }

  function handleKeyPress(e) {
    if (e.key === 'Enter') {
      handleLogin();
    }
  }

  function toggleConfig(path) {
    // Parse the path and toggle the value in editableConfig
    const parts = path.split('.');
    let obj = editableConfig;
    
    for (let i = 0; i < parts.length - 1; i++) {
      obj = obj[parts[i]];
    }
    
    const lastKey = parts[parts.length - 1];
    obj[lastKey] = !obj[lastKey];
    
    // Trigger reactivity
    editableConfig = editableConfig;
    
    // Check if dirty
    isDirty = JSON.stringify(config) !== JSON.stringify(editableConfig);
  }

  async function saveChanges() {
    saving = true;
    error = '';
    rebuildOutput = '';
    saveStatus = 'Saving configuration...';
    try {
      console.log('Starting save process...');
      await SaveNixConfig(editableConfig);
      console.log('Save completed successfully');
      config = JSON.parse(JSON.stringify(editableConfig));
      isDirty = false;
      saveStatus = 'Changes applied successfully!';
      setTimeout(() => { 
        saveStatus = ''; 
        rebuildOutput = '';
      }, 3000);
    } catch (err) {
      error = `Failed to save config: ${err}`;
      console.error('Save error:', err);
      saveStatus = '';
      rebuildOutput = '';
    } finally {
      saving = false;
    }
  }

  let activeSection = 'general';

  // Parse config into sections
  function parseConfigSections(config) {
    if (!config || !config.axiom || !config.axiom.admin) {
      return { sections: [], items: {} };
    }

    const admin = config.axiom.admin;
    const sections = [];
    const items = {};

    // General section - all direct properties except nested objects
    const generalItems = [];
    for (let key in admin) {
      const value = admin[key];
      if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
        // Check if this has nested items with .enable or if it's a direct item
        let hasNestedEnables = false;
        for (let itemKey in value) {
          if (typeof value[itemKey] === 'object' && value[itemKey].enable !== undefined) {
            hasNestedEnables = true;
            break;
          }
        }
        
        if (hasNestedEnables) {
          // This is a nested section (like games)
          const sectionName = key;
          const sectionItems = [];
          
          // Extract items from nested section
          for (let itemKey in value) {
            const itemValue = value[itemKey];
            if (typeof itemValue === 'object' && itemValue.enable !== undefined) {
              sectionItems.push({
                name: itemKey,
                enabled: itemValue.enable,
                path: `axiom.admin.${key}.${itemKey}.enable`
              });
            }
          }
          
          if (sectionItems.length > 0) {
            sections.push({ id: sectionName, name: sectionName });
            items[sectionName] = sectionItems;
          }
        } else if (value.enable !== undefined) {
          // Direct item with enable property
          generalItems.push({
            name: key,
            enabled: value.enable,
            path: `axiom.admin.${key}.enable`
          });
        }
      }
    }

    if (generalItems.length > 0) {
      sections.unshift({ id: 'general', name: 'general' });
      items['general'] = generalItems;
    }

    return { sections, items };
  }

  function formatName(name) {
    return name
      .split('-')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  }

  $: ({ sections, items } = parseConfigSections(editableConfig));
  $: if (sections.length > 0 && !activeSection) {
    activeSection = sections[0].id;
  }
</script>

<main>
  <div class="container">
    <header class="app-menu" on:mouseleave={closeMenu}>
      <div class="menu-bar">
        <div class="menu-item">
          <button class="menu-button" on:click={() => toggleMenu('file')}>File</button>
          {#if menuOpen === 'file'}
            <div class="dropdown">
              <button class="dropdown-item" on:click={() => onMenuAction('quit')}>Quit</button>
            </div>
          {/if}
        </div>
        <div class="menu-item">
          <button class="menu-button" on:click={() => toggleMenu('config')}>Config</button>
          {#if menuOpen === 'config'}
            <div class="dropdown">
              <button class="dropdown-item" on:click={() => onMenuAction('load-current')} disabled={!authenticated || loading}>
                Load Current
              </button>
            </div>
          {/if}
        </div>
      </div>
    </header>

    {#if !authenticated}
      <div class="login-card">
        <h1>Parental Controls</h1>
        <p>Enter your sudo password to manage settings</p>
        
        <div class="login-form">
          <input
            type="password"
            bind:value={password}
            on:keypress={handleKeyPress}
            placeholder="Sudo password"
            disabled={loading}
            autofocus
          />
          <button on:click={handleLogin} disabled={loading || !password}>
            {loading ? 'Authenticating...' : 'Login'}
          </button>
        </div>
        
        {#if loginError}
          <div class="error">{loginError}</div>
        {/if}
      </div>
    {:else}
      <div class="config-view">
        <aside class="sidebar">
          <nav>
            {#each sections as section}
              <button 
                class="nav-item" 
                class:active={activeSection === section.id}
                on:click={() => activeSection = section.id}
              >
                {formatName(section.name)}
              </button>
            {/each}
          </nav>
        </aside>
        
        <main class="content">
          {#if loading}
            <div class="loading">Loading configuration...</div>
          {:else if error}
            <div class="error">{error}</div>
          {:else if editableConfig && items[activeSection]}
            <div class="section-content">
              <h2 class="section-title">{formatName(activeSection)}</h2>
              <div class="items-grid" role="list">
                {#each items[activeSection] as item}
                  <div class="config-item" role="listitem">
                    <label class="item-label">
                      <span class="item-name">{formatName(item.name)}</span>
                      <input 
                        type="checkbox" 
                        class="item-toggle"
                        checked={item.enabled} 
                        on:change={() => toggleConfig(item.path)}
                      />
                    </label>
                  </div>
                {/each}
              </div>
            </div>
          {/if}
        </main>
      </div>
      
      {#if isDirty || saveStatus || rebuildOutput}
        <div class="save-banner">
          <div class="banner-content">
            <div class="banner-text-container">
              <span class="banner-text">
                {#if saveStatus}
                  {saveStatus}
                {:else}
                  You have unsaved changes
                {/if}
              </span>
              {#if rebuildOutput && saving}
                <span class="rebuild-output">{rebuildOutput}</span>
              {/if}
            </div>
            {#if isDirty}
              <button class="apply-btn" on:click={saveChanges} disabled={saving}>
                {saving ? 'Applying...' : 'Apply Changes'}
              </button>
            {/if}
          </div>
        </div>
      {/if}
    {/if}
  </div>
</main>

<style>
  main {
    min-height: 100vh;
    display: flex;
    background: #f5f7fb;
  }

  .container {
    width: 100vw;
    height: 100vh;
    display: flex;
    flex-direction: column;
    align-items: stretch;
  }

  .login-card {
    background: white;
    padding: 3rem;
    border-radius: 12px;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
    text-align: center;
  }

  h1 {
    color: #333;
    margin-bottom: 0.5rem;
    font-size: 2rem;
  }

  .login-card p {
    color: #666;
    margin-bottom: 2rem;
  }

  .login-form {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  input[type="password"],
  input[type="text"] {
    padding: 0.75rem 1rem;
    border: 2px solid #e0e0e0;
    border-radius: 6px;
    font-size: 1rem;
    transition: border-color 0.3s;
  }

  input[type="password"]:focus,
  input[type="text"]:focus {
    outline: none;
    border-color: #667eea;
  }

  button {
    padding: 0.6rem 1.2rem;
    background: #6366f1;
    color: white;
    border: none;
    border-radius: 6px;
    font-size: 0.95rem;
    font-weight: 600;
    cursor: pointer;
    transition: transform 0.2s, box-shadow 0.2s, background 0.2s;
  }

  button:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(99, 102, 241, 0.25);
    background: #4f46e5;
  }

  button:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .error {
    color: #e53e3e;
    background: #fff5f5;
    padding: 0.75rem;
    border-radius: 6px;
    margin-top: 1rem;
    border: 1px solid #fc8181;
  }

  .loading {
    text-align: center;
    color: #666;
    padding: 2rem;
  }

  .config-view {
    background: white;
    display: flex;
    width: 100%;
    flex: 1 1 auto; /* fill remaining space under menu */
    height: auto;
    overflow: hidden;
  }

  .sidebar {
    width: 220px;
    background: #f8f9fc;
    border-right: 1px solid #e5e7eb;
    padding: 1rem 0.5rem;
    flex-shrink: 0;
  }

  .sidebar nav {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }

  .nav-item {
    background: none;
    border: none;
    padding: 0.75rem 1rem;
    text-align: left;
    color: #374151;
    font-size: 0.975rem;
    cursor: pointer;
    transition: background 0.15s ease, color 0.15s ease, border-color 0.15s ease;
    border-left: 4px solid transparent;
    font-weight: 500;
    border-radius: 6px 0 0 6px;
  }

  .nav-item:hover {
    background: #eef2ff;
    color: #111827;
    border-left-color: #a5b4fc;
  }

  .nav-item.active {
    background: #e0e7ff;
    color: #111827;
    border-left-color: #6366f1;
    font-weight: 600;
  }

  .content {
    flex: 1 1 auto;
    min-width: 0; /* allow flex child to use full width */
    padding: 2rem 3rem;
    overflow-y: auto;
    background: #ffffff;
    display: flex;
    flex-direction: column;
    align-items: stretch; /* ensure children stretch full width */
  }

  .section-content {
    width: 100%;
    max-width: 100%;
    margin: 0;
  }

  .section-title {
    color: #111827;
    font-size: 1.5rem;
    margin: 0 0 1rem 0;
    text-transform: capitalize;
    font-weight: 700;
    letter-spacing: -0.01em;
  }

  .items-grid {
    display: flex;
    flex-direction: column;
    gap: 0;
    width: 100%;
  }

  .config-item {
    background: transparent;
    border-bottom: 1px solid #e5e7eb;
    padding: 0.75rem 0;
    transition: background 0.15s ease-in-out;
  }

  .config-item:hover {
    background: #f9fafb;
  }

  .config-item:first-child {
    border-top: 1px solid #e2e8f0;
  }

  .item-label {
    display: grid;
    grid-template-columns: 1fr 28px; /* name grows, checkbox fixed and right-aligned */
    column-gap: 1rem;
    align-items: center;
    cursor: pointer;
    width: 100%;
    padding: 0;
  }

  .item-name {
    font-weight: 500;
    color: #1f2937;
    font-size: 1rem;
    text-align: left;
    justify-self: start;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .item-label input[type="checkbox"], .item-toggle {
    width: 24px;
    height: 24px;
    cursor: pointer;
    justify-self: end;
    accent-color: #6366f1;
  }

  .save-banner {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    background: #ffffff;
    border-top: 1px solid #e5e7eb;
    box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.06);
    z-index: 1000;
  }

  .banner-content {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem 1.5rem;
  }

  .banner-text-container {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .banner-text {
    color: #111827;
    font-weight: 600;
    font-size: 1rem;
  }

  .rebuild-output {
    color: #6b7280;
    font-size: 0.875rem;
    font-family: monospace;
    max-width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .apply-btn {
    background: #111827;
    color: #ffffff;
    padding: 0.6rem 1.4rem;
    border: none;
    border-radius: 6px;
    font-size: 0.95rem;
    font-weight: 600;
    cursor: pointer;
    transition: transform 0.2s, box-shadow 0.2s, background 0.2s;
  }

  .apply-btn:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(17, 24, 39, 0.2);
    background: #0f172a;
  }

  .apply-btn:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }
  /* In-page menu */
  .app-menu {
    background: #ffffff;
    border-bottom: 1px solid #e5e7eb;
    padding: 0 0.5rem;
  }
  .menu-bar {
    height: 40px;
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }
  .menu-item {
    position: relative;
  }
  .menu-button {
    background: transparent;
    border: none;
    color: #374151;
    font-size: 0.95rem;
    padding: 0.25rem 0.5rem;
    border-radius: 4px;
    cursor: pointer;
  }
  .menu-button:hover {
    background: #eef2ff;
    color: #111827;
  }
  .dropdown {
    position: absolute;
    top: 100%;
    left: 0;
    background: #ffffff;
    border: 1px solid #e5e7eb;
    box-shadow: 0 8px 24px rgba(0,0,0,0.08);
    border-radius: 6px;
    margin-top: 6px;
    min-width: 180px;
    z-index: 50;
    padding: 0.25rem;
  }
  .dropdown-item {
    width: 100%;
    text-align: left;
    background: transparent;
    border: none;
    padding: 0.5rem 0.5rem;
    border-radius: 4px;
    color: #1f2937;
    font-size: 0.95rem;
    cursor: pointer;
  }
  .dropdown-item:hover:enabled {
    background: #f3f4f6;
  }
  .dropdown-item:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
</style>
