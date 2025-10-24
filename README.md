# Pluck - Plugin Loader Using Curated Kits

**Tagline:** *Don't install frameworks. Pluck what you need.*

---

**A simple, fast, minimalist Zsh plugin manager with Oh My Zsh and Prezto support - without the bloat.**

Use OMZ and Prezto plugins without installing the full frameworks. Pluck only downloads what you actually use via sparse checkout, keeping your setup lean and fast.

Based on [mattmc3/zsh_unplugged](https://github.com/mattmc3/zsh_unplugged) with added sparse-checkout magic for framework plugins.

## Why Pluck?

**Oh My Zsh is great, but heavy.** Installing the full OMZ framework means:
- ~1000+ files you'll never use
- Hundreds of plugins you don't need
- Slow shell startup times
- Megabytes of unnecessary disk usage

**Pluck fixes this.** Use any OMZ or Prezto plugin without the bloat:
- 🍒 **Sparse checkout** - Only downloads the exact plugins you request
- 🍒 **~230 lines of code** - Simple enough to understand completely
- 🍒 **Zero config** - Just list the plugins you want
- 🍒 **Fast** - No framework overhead, instant startup
- 🍒 **Compatible** - Works with OMZ, Prezto, and regular GitHub plugins

> **"Your shell, your picks."**

## Features

- **Minimalist**: ~230 lines of clean, readable code
- **Anti-bloat**: Sparse checkout means you only download what you use
- **Oh My Zsh Support**: Use `OMZP::` for plugins, `OMZT::` for themes, and `OMZL::` for libs
- **Prezto Support**: Use `PZT::` for modules and `PZTC::` for contrib modules
- **Version Pinning**: Pin plugins to specific commit SHAs
- **Auto-detection**: Automatically finds and sources init files
- **Deferred Loading**: Optional support for `zsh-defer`

## Installation

1. Create a plugins directory:
```zsh
mkdir -p ${ZDOTDIR:-~/.config/zsh}/plugins
```

2. Clone this repo:
```zsh
git clone https://github.com/yourusername/zsh_unplugged \
  ${ZDOTDIR:-~/.config/zsh}/plugins/zsh_unplugged
```

3. Add to your `.zshrc`:
```zsh
ZPLUGINDIR=${ZDOTDIR:-~/.config/zsh}/plugins
source $ZPLUGINDIR/zsh_unplugged/zsh_unplugged.zsh

# Initialize completion system (if not already done)
autoload -Uz compinit && compinit
```

**Note:** The completion system (`compinit`) must be initialized for plugin completions to work. If you already have `compinit` in your `.zshrc`, you can skip this step.

## Usage

### Basic Example

```zsh
repos=(
  # Regular GitHub plugins
  'zsh-users/zsh-completions'
  'zsh-users/zsh-autosuggestions'
  'zsh-users/zsh-syntax-highlighting'

  # Oh My Zsh plugins
  'OMZP::git'
  'OMZP::sudo'
  'OMZP::kubectl'

  # Oh My Zsh theme
  'OMZT::robbyrussell'

  # Oh My Zsh libs
  'OMZL::git'
  'OMZL::clipboard'

  # Prezto modules
  'PZT::git'
  'PZT::editor'
  'PZT::prompt'

  # Prezto contrib modules
  'PZTC::kubernetes'
  'PZTC::zoxide'
)

plugin-load $repos
```

### Oh My Zsh Plugin Syntax

Use the `OMZP::` prefix for plugins, `OMZT::` for themes, and `OMZL::` for libs:

```zsh
repos=(
  # Oh My Zsh plugins (individual mirrors)
  'OMZP::git'              # https://github.com/ohmyzsh/git
  'OMZP::docker'           # https://github.com/ohmyzsh/docker
  'OMZP::sudo'             # https://github.com/ohmyzsh/sudo

  # Oh My Zsh themes (individual mirrors)
  'OMZT::agnoster'         # https://github.com/ohmyzsh/agnoster

  # Oh My Zsh libs (from main ohmyzsh repo)
  'OMZL::git'              # https://github.com/ohmyzsh/ohmyzsh (lib/git.zsh)
  'OMZL::clipboard'        # https://github.com/ohmyzsh/ohmyzsh (lib/clipboard.zsh)
  'OMZL::history'          # https://github.com/ohmyzsh/ohmyzsh (lib/history.zsh)
)
```

**Note**:
- All Oh My Zsh components use the main `ohmyzsh/ohmyzsh` monorepo with sparse checkout
- Only the specific plugins/themes/libs you request are downloaded (minimal disk usage)
- The repo is cloned once, then individual files/directories are checked out on-demand

### Prezto Module Syntax

Use the `PZT::` prefix for Prezto modules and `PZTC::` for contrib modules:

```zsh
repos=(
  # Prezto core modules
  'PZT::git'           # https://github.com/sorin-ionescu/prezto (modules/git)
  'PZT::editor'        # https://github.com/sorin-ionescu/prezto (modules/editor)
  'PZT::prompt'        # https://github.com/sorin-ionescu/prezto (modules/prompt)
  'PZT::syntax-highlighting'

  # Prezto contrib modules
  'PZTC::kubernetes'   # https://github.com/belak/prezto-contrib (modules/kubernetes)
  'PZTC::zoxide'       # https://github.com/belak/prezto-contrib (modules/zoxide)
)
```

The plugin manager clones the full Prezto repo once and loads individual modules from it. Each module's `init.zsh` is sourced, and the `functions/` directory is added to `fpath`.

### Pinning to Specific Commits

Pin any plugin (regular, Oh My Zsh, or Prezto) to a specific commit SHA:

```zsh
repos=(
  # Pin regular plugins
  'zsh-users/zsh-syntax-highlighting@5eb677bb0fa9a3e60f0eff031dc13926e093df92'

  # Pin Oh My Zsh plugins and libs
  'OMZP::git@abc123def456'
  'OMZL::clipboard@def456abc789'

  # Pin Prezto modules (pins the entire repo)
  'PZT::git@def789'
  'PZTC::kubernetes@abc123'
)
```

### Popular Oh My Zsh Plugins

Here are some popular Oh My Zsh plugins you can use:

| Plugin | Prefix | Description |
|--------|--------|-------------|
| git | `OMZP::git` | Git aliases and functions |
| sudo | `OMZP::sudo` | Prefix command with sudo (ESC ESC) |
| kubectl | `OMZP::kubectl` | Kubectl aliases |
| docker | `OMZP::docker` | Docker aliases |
| docker-compose | `OMZP::docker-compose` | Docker Compose aliases |
| npm | `OMZP::npm` | NPM aliases |
| yarn | `OMZP::yarn` | Yarn aliases |
| extract | `OMZP::extract` | Extract various archive types |
| z | `OMZP::z` | Jump around directories |
| colored-man-pages | `OMZP::colored-man-pages` | Colorize man pages |

### Popular Oh My Zsh Themes

| Theme | Prefix | Description |
|-------|--------|-------------|
| robbyrussell | `OMZT::robbyrussell` | Default Oh My Zsh theme |
| agnoster | `OMZT::agnoster` | Popular powerline theme |
| powerlevel10k | `OMZT::powerlevel10k` | Advanced customizable theme |

### Popular Oh My Zsh Libs

Here are some useful Oh My Zsh library files you can load individually:

| Lib | Prefix | Description |
|-----|--------|-------------|
| git | `OMZL::git` | Git helper functions |
| clipboard | `OMZL::clipboard` | Clipboard operations (clipcopy, clippaste) |
| history | `OMZL::history` | History configuration |
| directories | `OMZL::directories` | Directory navigation utilities |
| key-bindings | `OMZL::key-bindings` | Keyboard shortcuts |
| completion | `OMZL::completion` | Completion system setup |
| theme-and-appearance | `OMZL::theme-and-appearance` | Theme utilities |
| spectrum | `OMZL::spectrum` | Color utilities |
| grep | `OMZL::grep` | Grep enhancements |
| functions | `OMZL::functions` | Core shell functions |

### Popular Prezto Modules

Here are some popular Prezto modules you can use:

| Module | Prefix | Description |
|--------|--------|-------------|
| git | `PZT::git` | Git aliases and functions |
| editor | `PZT::editor` | Key bindings (emacs/vi mode) |
| prompt | `PZT::prompt` | Prompt themes |
| completion | `PZT::completion` | Tab completion |
| syntax-highlighting | `PZT::syntax-highlighting` | Fish-like syntax highlighting |
| autosuggestions | `PZT::autosuggestions` | Fish-like autosuggestions |
| history | `PZT::history` | History settings |
| directory | `PZT::directory` | Directory navigation |
| docker | `PZT::docker` | Docker aliases |
| homebrew | `PZT::homebrew` | Homebrew aliases (macOS) |

### Popular Prezto Contrib Modules

| Module | Prefix | Description |
|--------|--------|-------------|
| kubernetes | `PZTC::kubernetes` | Kubernetes aliases and completions |
| zoxide | `PZTC::zoxide` | Smarter cd command |
| direnv | `PZTC::direnv` | Directory-specific environment variables |
| nvm-auto-use | `PZTC::nvm-auto-use` | Automatically use correct Node version |

## File Type Support

The plugin manager intelligently handles different file structures across frameworks:

| File Type | Extension/Dir | Purpose | Handled |
|-----------|---------------|---------|---------|
| **Prezto Modules** | `init.zsh` | Prezto module initialization | ✓ Sourced (highest priority) |
| **Prezto Functions** | `functions/` | Prezto autoloadable functions | ✓ Added to fpath |
| **OMZ Plugins** | `.plugin.zsh` | Oh My Zsh plugin files | ✓ Sourced |
| **Themes** | `.zsh-theme` | Prompt themes (OMZ) | ✓ Sourced |
| **Completions** | `_command` | Tab completions (via fpath) | ✓ Auto-loaded |
| **Libraries** | `.zsh` | Generic Zsh libraries | ✓ Sourced |
| **Shell Scripts** | `.sh` | Shell scripts | ✓ Sourced |
| **Completion Dirs** | `completions/` | Completion subdirectories | ✓ Added to fpath |

### How It Works

1. **Framework Detection**: Detects if a plugin uses special prefixes:
   - `OMZP::`/`OMZT::`/`OMZL::` for Oh My Zsh
   - `PZT::`/`PZTC::` for Prezto
   - Otherwise treats as regular GitHub repo

2. **URL Conversion**: Converts prefixes to GitHub URLs:
   - `OMZP::git` → `ohmyzsh/ohmyzsh` (sparse checkout `plugins/git/`)
   - `OMZT::agnoster` → `ohmyzsh/ohmyzsh` (sparse checkout `themes/agnoster.zsh-theme`)
   - `OMZL::clipboard` → `ohmyzsh/ohmyzsh` (sparse checkout `lib/clipboard.zsh`)
   - `PZT::git` → `sorin-ionescu/prezto` (full clone, loads `modules/git`)
   - `PZTC::kubernetes` → `belak/prezto-contrib` (full clone, loads `modules/kubernetes`)

3. **Cloning**:
   - Regular plugins: Clones individual repo with `--depth 1`
   - OMZ (all types): Clones ohmyzsh/ohmyzsh once with `--filter=blob:none`, sparse checkout on-demand
   - Prezto modules: Clones full framework once with `--depth 1`, references specific module

4. **Fpath Setup**:
   - Adds plugin/module directory to `fpath`
   - Adds `completions/` subdirectory (if present)
   - Adds `functions/` subdirectory (for Prezto modules)

5. **Init File Detection**: Searches for files in order of preference:
   - `init.zsh` (highest priority - Prezto standard)
   - `.plugin.zsh` (Oh My Zsh plugin format)
   - `.zsh-theme` (theme files)
   - `.zsh` (generic Zsh files/libraries)
   - `.sh` (shell scripts)

6. **Sourcing**: Sources the init file with optional deferred loading

7. **Completion-Only**: If no sourceable file is found, the plugin is still added to `fpath` (useful for completion-only plugins)

## Advanced Usage

### Completion-Only Plugins

Some plugins only provide completions without any aliases or functions. The plugin manager handles these automatically:

```zsh
repos=(
  'OMZP::rustup'    # Only provides _rustup completion
  'OMZP::cargo'     # Only provides _cargo completion
)
```

Even if no `.plugin.zsh` file exists, the directory is added to `fpath` so completions work.

### Plugins with Completions Subdirectory

Some plugins (like `docker`) have a separate `completions/` directory:

```
docker/
├── docker.plugin.zsh
└── completions/
    └── _docker
```

The plugin manager automatically adds both the plugin directory AND the `completions/` subdirectory to `fpath`.

### Multiple File Types

If a plugin contains multiple file types, the priority order is:
1. `.plugin.zsh` (highest)
2. `.zsh-theme`
3. `.zsh`
4. `.sh` (lowest)

The first matching file found is sourced.

## Complete Example

See [example.zsh](example.zsh) for a complete configuration example.

## Credits

- Original `zsh_unplugged` by [mattmc3](https://github.com/mattmc3/zsh_unplugged)
- Oh My Zsh support enhancement

## License

MIT License (see [LICENSE](LICENSE))