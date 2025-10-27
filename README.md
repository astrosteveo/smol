# Pluck

**Plugin Loader Using Curated Kits**

*Don't install frameworks. Pluck what you need.*

---

A minimal Zsh plugin manager (~270 lines) that lets you use Oh My Zsh and Prezto plugins without installing the full frameworks.

## Why?

**Oh My Zsh is 14 MB. Prezto is 6 MB. Your plugins? Maybe 50 KB.**

Pluck uses sparse checkout to download only the plugins you actually use:
- 🎯 **Targeted downloads** - Only the plugins you request
- 🪶 **Lightweight** - ~270 lines of readable code
- ⚡ **Fast** - No framework overhead
- 🔧 **Simple** - One function, no magic

Based on [mattmc3/zsh_unplugged](https://github.com/mattmc3/zsh_unplugged).

## Installation

```zsh
# Create plugins directory
mkdir -p ${ZDOTDIR:-~/.config/zsh}/plugins

# Clone Pluck
git clone https://github.com/yourusername/pluck \
  ${ZDOTDIR:-~/.config/zsh}/plugins/pluck
```

## Usage

Add to your `.zshrc`:

```zsh
# Set plugin directory
ZPLUGINDIR=${ZDOTDIR:-~/.config/zsh}/plugins

# Source Pluck
source $ZPLUGINDIR/pluck/pluck.zsh

# Define plugins
repos=(
  # Regular GitHub plugins
  'zsh-users/zsh-syntax-highlighting'
  'zsh-users/zsh-autosuggestions'

  # Oh My Zsh plugins (sparse checkout)
  'OMZP::git'
  'OMZP::docker'
  'OMZP::sudo'

  # Oh My Zsh themes
  'OMZT::robbyrussell'

  # Oh My Zsh libs
  'OMZL::clipboard'
  'OMZL::git'

  # Prezto modules
  'PZT::git'
  'PZT::editor'

  # Prezto contrib
  'PZTC::kubernetes'

  # Pin to specific commit
  'zsh-users/zsh-completions@0.35.0'
  'OMZP::kubectl@abc123'
)

# Load all plugins
plugin-load $repos

# Initialize completions (required)
autoload -Uz compinit && compinit
```

## Plugin Formats

### Regular GitHub Repos
```zsh
'user/repo'              # Latest version
'user/repo@commit-sha'   # Pinned version
```

### Oh My Zsh
```zsh
'OMZP::git'              # Plugin from plugins/git
'OMZT::robbyrussell'     # Theme from themes/
'OMZL::clipboard'        # Library from lib/
'OMZP::docker@abc123'    # Pinned version
```

**Note:** OMZ uses sparse checkout - only downloads the specific plugin/theme/lib you request.

### Prezto
```zsh
'PZT::git'               # Module from modules/git
'PZTC::kubernetes'       # Contrib module
'PZT::editor@def456'     # Pinned version
```

**Note:** Prezto clones the full framework (needed for module structure).

## How It Works

1. **Parse** - Detects plugin type from prefix (OMZP/OMZT/OMZL/PZT/PZTC)
2. **Clone** - Uses sparse checkout for OMZ, shallow clone for others
3. **Path** - Adds plugin directories to `fpath` for completions
4. **Source** - Finds and sources init files automatically

## File Detection Priority

Pluck automatically finds init files in this order:

1. `init.zsh` - Prezto standard
2. `*.plugin.zsh` - Oh My Zsh plugin
3. `*.zsh-theme` - Theme file
4. `*.zsh` - Generic Zsh file
5. `*.sh` - Shell script

## Management

```zsh
# Update a plugin
rm -rf $ZPLUGINDIR/plugin-name
# Restart shell or re-source .zshrc

# List installed plugins
ls $ZPLUGINDIR

# Remove a plugin
rm -rf $ZPLUGINDIR/plugin-name

# Update Oh My Zsh base
rm -rf $ZPLUGINDIR/ohmyzsh
# Will re-clone on next shell start
```

## Features

- ✅ Oh My Zsh plugins without the framework
- ✅ Prezto modules without the framework
- ✅ Regular GitHub plugins
- ✅ Sparse checkout (minimal disk usage)
- ✅ Version pinning (commit SHA)
- ✅ Auto-detection of init files
- ✅ Completion support
- ✅ Optional deferred loading (with `zsh-defer`)

## What Pluck Doesn't Do

- ❌ No update command (just delete and reload)
- ❌ No plugin listing (use `ls`)
- ❌ No dependency management
- ❌ No fancy features

Pluck is intentionally minimal. If you need more features, check out [Antidote](https://github.com/mattmc3/antidote).

## Comparison

| Feature | Oh My Zsh | Prezto | Antidote | Pluck |
|---------|-----------|---------|----------|-------|
| Size | ~14 MB | ~6 MB | ~1800 LOC | ~270 LOC |
| OMZ Plugins | ✅ (all) | ❌ | ✅ | ✅ (sparse) |
| Prezto Modules | ❌ | ✅ (all) | ✅ | ✅ |
| Update Command | ✅ | ✅ | ✅ | ❌ |
| Disk Usage | Heavy | Heavy | Light | Minimal |

## Credits

- Based on [zsh_unplugged](https://github.com/mattmc3/zsh_unplugged) by mattmc3
- Inspired by the anti-framework philosophy

## License

MIT
