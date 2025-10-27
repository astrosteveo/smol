#!/usr/bin/env zsh
# Pluck - Plugin Loader Using Curated Kits
#
# A minimal Zsh plugin manager that lets you use Oh My Zsh and Prezto plugins
# without installing the full frameworks. Built on the philosophy of zsh_unplugged
# by mattmc3 (https://github.com/mattmc3/zsh_unplugged)
#
# Usage:
#   ZPLUGINDIR=${ZDOTDIR:-~/.config/zsh}/plugins
#   source $ZPLUGINDIR/pluck/pluck.zsh
#
#   repos=(
#     # Regular GitHub plugins
#     'zsh-users/zsh-syntax-highlighting'
#     'zsh-users/zsh-autosuggestions'
#
#     # Oh My Zsh plugins (sparse checkout)
#     'OMZP::git'
#     'OMZP::docker'
#
#     # Oh My Zsh themes
#     'OMZT::robbyrussell'
#
#     # Oh My Zsh libs
#     'OMZL::clipboard'
#
#     # Prezto modules
#     'PZT::git'
#     'PZT::editor'
#
#     # Prezto contrib
#     'PZTC::kubernetes'
#
#     # Version pinning (works with any type)
#     'zsh-users/zsh-completions@0.35.0'
#     'OMZP::kubectl@abc123'
#   )
#   plugin-load $repos
#

##? Clone a plugin, detect its type, find init files, and source it.
##? Supports Oh My Zsh (OMZP/OMZT/OMZL), Prezto (PZT/PZTC), and regular repos.
##? Handles sparse checkout for Oh My Zsh to minimize disk usage.
function plugin-load {
  local plugin plugin_type plugin_name repo commitsha plugdir initfile initfiles
  local omz_base prezto_base sparse_path
  : ${ZPLUGINDIR:=${ZDOTDIR:-~/.config/zsh}/plugins}

  for plugin in $@; do
    # Reset variables for each plugin
    plugin_type=""
    plugin_name=""
    repo=""
    commitsha=""
    plugdir=""
    initfile=""
    sparse_path=""

    # ============================================================================
    # PARSE PHASE: Determine plugin type and extract name/repo/sha
    # ============================================================================

    case "$plugin" in
      OMZP::*)
        plugin_type="omz-plugin"
        plugin_name="${plugin#OMZP::}"
        repo="ohmyzsh/ohmyzsh"
        ;;
      OMZT::*)
        plugin_type="omz-theme"
        plugin_name="${plugin#OMZT::}"
        repo="ohmyzsh/ohmyzsh"
        ;;
      OMZL::*)
        plugin_type="omz-lib"
        plugin_name="${plugin#OMZL::}"
        repo="ohmyzsh/ohmyzsh"
        ;;
      PZT::*)
        plugin_type="prezto-mod"
        plugin_name="${plugin#PZT::}"
        repo="sorin-ionescu/prezto"
        ;;
      PZTC::*)
        plugin_type="prezto-contrib"
        plugin_name="${plugin#PZTC::}"
        repo="belak/prezto-contrib"
        ;;
      *)
        plugin_type="regular"
        repo="$plugin"
        ;;
    esac

    # Extract commit SHA if present (format: name@sha or repo@sha)
    if [[ "$plugin_name" == *'@'* ]]; then
      commitsha="${plugin_name#*@}"
      plugin_name="${plugin_name%@*}"
    elif [[ "$repo" == *'@'* ]]; then
      commitsha="${repo#*@}"
      repo="${repo%@*}"
    fi

    # ============================================================================
    # CLONE PHASE: Handle cloning based on plugin type
    # ============================================================================

    case "$plugin_type" in
      omz-*)
        # Oh My Zsh: Use sparse checkout from monorepo
        omz_base="$ZPLUGINDIR/ohmyzsh"

        # Ensure base OMZ repo exists
        if [[ ! -d "$omz_base" ]]; then
          echo "Cloning Oh My Zsh base repository..."
          git clone --filter=blob:none --no-checkout --quiet \
            https://github.com/$repo "$omz_base" 2>/dev/null || {
            echo >&2 "Error: Failed to clone Oh My Zsh repository"
            continue
          }
          git -C "$omz_base" sparse-checkout init --no-cone 2>/dev/null
        fi

        # Determine sparse checkout path based on type
        case "$plugin_type" in
          omz-plugin)
            sparse_path="plugins/$plugin_name"
            plugdir="$omz_base/plugins/$plugin_name"
            initfile="$plugdir/$plugin_name.plugin.zsh"
            ;;
          omz-theme)
            sparse_path="themes/$plugin_name.zsh-theme"
            plugdir="$omz_base/themes"
            initfile="$plugdir/$plugin_name.zsh-theme"
            ;;
          omz-lib)
            sparse_path="lib/$plugin_name.zsh"
            plugdir="$omz_base/lib"
            initfile="$plugdir/$plugin_name.zsh"
            ;;
        esac

        # Add to sparse checkout if not already present
        if ! git -C "$omz_base" sparse-checkout list 2>/dev/null | grep -qx "$sparse_path"; then
          echo "$sparse_path" >> "$omz_base/.git/info/sparse-checkout"
        fi

        # Checkout the files
        git -C "$omz_base" checkout 2>/dev/null || true

        # Handle SHA pinning for OMZ
        if [[ -n "$commitsha" ]]; then
          git -C "$omz_base" fetch -q origin "$commitsha" 2>/dev/null || true
          git -C "$omz_base" checkout -q "$commitsha" 2>/dev/null || true
        fi

        # Verify the plugin exists
        if [[ ! -e "$initfile" ]] && [[ ! -d "$plugdir" ]]; then
          echo >&2 "Warning: Oh My Zsh $plugin_type '$plugin_name' not found"
          continue
        fi
        ;;

      prezto-*)
        # Prezto: Full clone of framework (need module structure)
        if [[ "$plugin_type" == "prezto-mod" ]]; then
          prezto_base="$ZPLUGINDIR/prezto"
          plugdir="$prezto_base/modules/$plugin_name"
        else
          prezto_base="$ZPLUGINDIR/prezto-contrib"
          plugdir="$prezto_base/$plugin_name"
        fi

        # Clone base Prezto repo if needed
        if [[ ! -d "$prezto_base" ]]; then
          echo "Cloning $repo..."
          git clone --depth 1 --quiet --recursive --shallow-submodules \
            https://github.com/$repo "$prezto_base" 2>/dev/null || {
            echo >&2 "Error: Failed to clone $repo"
            continue
          }
        fi

        # Handle SHA pinning for Prezto
        if [[ -n "$commitsha" ]]; then
          git -C "$prezto_base" fetch -q origin "$commitsha" 2>/dev/null || true
          git -C "$prezto_base" checkout -q "$commitsha" 2>/dev/null || true
        fi

        initfile="$plugdir/init.zsh"

        if [[ ! -d "$plugdir" ]]; then
          echo >&2 "Warning: Prezto module '$plugin_name' not found in $repo"
          continue
        fi
        ;;

      regular)
        # Regular GitHub repo: shallow clone
        plugdir="$ZPLUGINDIR/${repo:t}"
        initfile="$plugdir/${repo:t}.plugin.zsh"

        if [[ ! -d "$plugdir" ]]; then
          echo "Cloning $repo..."
          git clone --depth 1 --quiet --recursive --shallow-submodules \
            https://github.com/$repo "$plugdir" 2>/dev/null || {
            echo >&2 "Error: Failed to clone $repo"
            continue
          }
        fi

        # Handle SHA pinning for regular repos
        if [[ -n "$commitsha" ]]; then
          git -C "$plugdir" fetch -q origin "$commitsha" 2>/dev/null || true
          git -C "$plugdir" checkout -q "$commitsha" 2>/dev/null || true
        fi
        ;;
    esac

    # ============================================================================
    # PATH PHASE: Add plugin directories to fpath
    # ============================================================================

    case "$plugin_type" in
      omz-plugin)
        fpath=("$plugdir" $fpath)
        [[ -d "$plugdir/completions" ]] && fpath=("$plugdir/completions" $fpath)
        ;;
      prezto-*)
        fpath=("$plugdir" $fpath)
        [[ -d "$plugdir/functions" ]] && fpath=("$plugdir/functions" $fpath)
        ;;
      regular)
        fpath=("$plugdir" $fpath)
        [[ -d "$plugdir/completions" ]] && fpath=("$plugdir/completions" $fpath)
        ;;
      omz-theme|omz-lib)
        # Themes and libs don't typically need fpath
        ;;
    esac

    # ============================================================================
    # SOURCE PHASE: Find init file and source it
    # ============================================================================

    # If init file doesn't exist at expected location, search for it
    if [[ ! -e "$initfile" ]]; then
      # Priority order for finding init files
      initfiles=(
        $plugdir/init.zsh(N)           # Prezto standard (highest priority)
        $plugdir/*.plugin.zsh(N)       # Oh My Zsh plugin
        $plugdir/*.zsh-theme(N)        # Theme file
        $plugdir/*.zsh(N)              # Generic Zsh file
        $plugdir/*.sh(N)               # Shell script
      )

      if (( $#initfiles )); then
        # Create symlink to first matching file for consistency
        ln -sf "$initfiles[1]" "$initfile" 2>/dev/null || true
      else
        # No sourceable file found - this is OK for completion-only plugins
        # The plugin dir is already in fpath, so completions will work
        continue
      fi
    fi

    # Source the init file (with optional zsh-defer support)
    if [[ -e "$initfile" ]]; then
      (( $+functions[zsh-defer] )) && zsh-defer . "$initfile" || . "$initfile"
    fi
  done
}
