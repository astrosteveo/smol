#!/usr/bin/env zsh
# Example configuration using zsh_unplugged with Oh My Zsh support

# Set plugin directory
ZPLUGINDIR=${ZDOTDIR:-~/.config/zsh}/plugins

# Source the plugin manager
source $ZPLUGINDIR/zsh_unplugged/zsh_unplugged.zsh

# Define your plugins
# The plugin manager automatically handles:
# - .plugin.zsh files (plugins)
# - .zsh-theme files (themes)
# - .zsh files (libraries)
# - _completions files (added via fpath)
# - completions/ subdirectories
repos=(
  # ============================================
  # Oh My Zsh Plugins (using OMZP:: prefix)
  # ============================================
  'OMZP::git'              # Git aliases and functions
  'OMZP::sudo'             # Prefix command with sudo using ESC ESC
  'OMZP::kubectl'          # Kubectl aliases
  'OMZP::docker'           # Docker aliases
  'OMZP::docker-compose'   # Docker Compose aliases
  'OMZP::npm'              # NPM aliases
  'OMZP::yarn'             # Yarn aliases
  'OMZP::extract'          # Extract various archive types
  'OMZP::z'                # Jump around directories
  'OMZP::colored-man-pages' # Colorize man pages

  # ============================================
  # Oh My Zsh Themes (using OMZT:: prefix)
  # ============================================
  # Uncomment one of these:
  # 'OMZT::robbyrussell'   # Default Oh My Zsh theme
  # 'OMZT::agnoster'       # Popular powerline theme
  # 'OMZT::powerlevel10k'  # Advanced theme with lots of features

  # ============================================
  # Oh My Zsh Libs (using OMZL:: prefix)
  # ============================================
  'OMZL::git'            # Git helper functions
  'OMZL::clipboard'      # Clipboard operations
  'OMZL::history'        # History configuration
  'OMZL::directories'    # Directory navigation

  # ============================================
  # Prezto Modules (using PZT:: prefix)
  # ============================================
  'PZT::git'             # Git aliases and functions
  'PZT::editor'          # Key bindings configuration
  'PZT::prompt'          # Prompt themes
  'PZT::completion'      # Tab completion
  'PZT::syntax-highlighting'  # Syntax highlighting
  'PZT::autosuggestions' # Fish-like autosuggestions
  'PZT::history'         # History configuration
  'PZT::directory'       # Directory navigation

  # ============================================
  # Prezto Contrib Modules (using PZTC:: prefix)
  # ============================================
  'PZTC::kubernetes'     # Kubernetes aliases
  'PZTC::zoxide'         # Smarter cd command

  # ============================================
  # Regular GitHub Plugins
  # ============================================
  'zsh-users/zsh-completions'           # Additional completions
  'zsh-users/zsh-autosuggestions'       # Fish-like autosuggestions
  'zsh-users/zsh-syntax-highlighting'   # Syntax highlighting (load last)

  # Modern CLI tools
  'ajeetdsouza/zoxide'                  # Smarter cd command

  # ============================================
  # Pinned to Specific Commits (for stability)
  # ============================================
  # 'zsh-users/zsh-syntax-highlighting@5eb677bb0fa9a3e60f0eff031dc13926e093df92'
  # 'zsh-users/zsh-autosuggestions@85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5'

  # ============================================
  # Oh My Zsh Plugins Pinned to Commits
  # ============================================
  # You can also pin Oh My Zsh plugins if needed:
  # 'OMZP::git@abc123'
)

# Load all plugins
plugin-load $repos

# Your additional Zsh configuration goes here
# ...
