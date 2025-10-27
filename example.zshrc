#!/usr/bin/env zsh
# Example .zshrc using Pluck

# Set plugin directory
ZPLUGINDIR=${ZDOTDIR:-~/.config/zsh}/plugins

# Source Pluck
source $ZPLUGINDIR/pluck/pluck.zsh

# Define your plugins
repos=(
  # ============================================
  # Oh My Zsh Plugins (sparse checkout)
  # ============================================
  'OMZP::git'              # Git aliases and functions
  'OMZP::sudo'             # ESC ESC to prefix with sudo
  'OMZP::docker'           # Docker aliases
  'OMZP::kubectl'          # Kubernetes aliases
  'OMZP::extract'          # Extract any archive type
  'OMZP::colored-man-pages' # Colorized man pages

  # ============================================
  # Oh My Zsh Theme
  # ============================================
  'OMZT::robbyrussell'     # Classic OMZ theme

  # ============================================
  # Oh My Zsh Libraries
  # ============================================
  'OMZL::clipboard'        # clipcopy/clippaste functions
  'OMZL::git'              # Git helper functions

  # ============================================
  # Prezto Modules
  # ============================================
  'PZT::editor'            # Key bindings and editor config
  'PZT::directory'         # Directory navigation

  # ============================================
  # Regular GitHub Plugins
  # ============================================
  'zsh-users/zsh-completions'           # Additional completions
  'zsh-users/zsh-autosuggestions'       # Fish-like suggestions
  'zsh-users/zsh-syntax-highlighting'   # Syntax highlighting (load last!)

  # ============================================
  # Pinned Versions (optional)
  # ============================================
  # Pin to specific commits for stability:
  # 'zsh-users/zsh-syntax-highlighting@5eb677bb'
  # 'OMZP::git@abc123'
)

# Load all plugins
plugin-load $repos

# Initialize completion system (required for completions to work)
autoload -Uz compinit && compinit

# Your additional configuration below
# --------------------------------------------

# Example: Set editor
export EDITOR=vim

# Example: Custom aliases
alias ll='ls -lah'
alias gs='git status'

# Example: History settings
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
