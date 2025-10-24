# Pluck - Plugin Loader Using Curated Kits
# Based on zsh_unplugged by mattmc3 - https://github.com/mattmc3/zsh_unplugged
#
# A simple, fast, minimalist Zsh plugin manager with Oh My Zsh and Prezto support.
# Pluck only what you need - no frameworks, no bloat, just your plugins.
#
# Usage:
# ZPLUGINDIR=${ZDOTDIR:-~}/plugins
# source $ZPLUGINDIR/zsh_unplugged/zsh_unplugged.zsh
# repos=(
#   # Regular plugins from GitHub
#   'zsh-users/zsh-completions'
#   'ajeetdsouza/zoxide'
#
#   # Plugins pinned to a particular SHA
#   'zsh-users/zsh-syntax-highlighting@5eb677bb0fa9a3e60f0eff031dc13926e093df92'
#   'zsh-users/zsh-autosuggestions@85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5'
#
#   # Oh My Zsh plugins (sparse checkout from monorepo)
#   'OMZP::git'
#   'OMZP::sudo'
#   'OMZP::kubectl'
#
#   # Oh My Zsh themes
#   'OMZT::robbyrussell'
#   'OMZT::agnoster'
#
#   # Oh My Zsh libs
#   'OMZL::git'
#   'OMZL::clipboard'
#   'OMZL::history'
#
#   # Prezto modules (from main repo)
#   'PZT::git'
#   'PZT::editor'
#   'PZT::prompt'
#
#   # Prezto contrib modules
#   'PZTC::kubernetes'
#   'PZTC::zoxide'
# )
# plugin-load $repos
#

##? Clone a plugin using its github repo and (optionally) commit sha,
##? identify its init file, source it, and add it to your fpath.
##? Supports Oh My Zsh plugins using OMZP::, OMZT::, and OMZL:: prefixes.
##? Supports Prezto modules using PZT:: and PZTC:: prefixes.
##? Handles plugins, themes, completions, and library files.
function plugin-load {
  local plugin repo commitsha plugdir initfile initfiles=() clone_args=()
  local is_prezto=false prezto_module=""
  local is_omz=false omz_type="" omz_name=""
  : ${ZPLUGINDIR:=${ZDOTDIR:-~/.config/zsh}/plugins}
  for plugin in $@; do
    repo="$plugin"
    clone_args=(--quiet --depth 1 --recursive --shallow-submodules)
    commitsha=""
    is_prezto=false
    prezto_module=""
    is_omz=false
    omz_type=""
    omz_name=""

    # Handle Oh My Zsh (OMZP/OMZT/OMZL all use monorepo with sparse checkout)
    if [[ "$plugin" == OMZP::* ]]; then
      omz_name="${plugin#OMZP::}"
      omz_type="plugins"
      repo="ohmyzsh/ohmyzsh"
      is_omz=true
    elif [[ "$plugin" == OMZT::* ]]; then
      omz_name="${plugin#OMZT::}"
      omz_type="themes"
      repo="ohmyzsh/ohmyzsh"
      is_omz=true
    elif [[ "$plugin" == OMZL::* ]]; then
      omz_name="${plugin#OMZL::}"
      omz_type="lib"
      repo="ohmyzsh/ohmyzsh"
      is_omz=true
    # Handle Prezto modules (PZT::name) and contrib (PZTC::name)
    elif [[ "$plugin" == PZT::* ]]; then
      prezto_module="${plugin#PZT::}"
      repo="sorin-ionescu/prezto"
      is_prezto=true
    elif [[ "$plugin" == PZTC::* ]]; then
      prezto_module="${plugin#PZTC::}"
      repo="belak/prezto-contrib"
      is_prezto=true
    fi

    # Pin repo to a specific commit sha if provided
    if [[ "$prezto_module" == *'@'* ]]; then
      commitsha="${prezto_module#*@}"
      prezto_module="${prezto_module%@*}"
      clone_args+=(--no-checkout)
    elif [[ "$omz_name" == *'@'* ]]; then
      commitsha="${omz_name#*@}"
      omz_name="${omz_name%@*}"
      clone_args+=(--no-checkout)
    elif [[ "$repo" == *'@'* ]]; then
      commitsha="${repo#*@}"
      repo="${repo%@*}"
      clone_args+=(--no-checkout)
    fi

    plugdir=$ZPLUGINDIR/${repo:t}

    # Set paths based on framework type
    if [[ "$is_prezto" == true ]]; then
      # Prezto-contrib has modules at root, not in modules/
      if [[ "$repo" == "belak/prezto-contrib" ]]; then
        plugdir=$ZPLUGINDIR/${repo:t}/${prezto_module}
      else
        plugdir=$ZPLUGINDIR/${repo:t}/modules/${prezto_module}
      fi
      initfile=$plugdir/init.zsh
    elif [[ "$is_omz" == true ]]; then
      if [[ "$omz_type" == "themes" ]]; then
        plugdir=$ZPLUGINDIR/${repo:t}/themes
        initfile=$plugdir/${omz_name}.zsh-theme
      elif [[ "$omz_type" == "lib" ]]; then
        plugdir=$ZPLUGINDIR/${repo:t}/lib
        initfile=$plugdir/${omz_name}.zsh
      else
        plugdir=$ZPLUGINDIR/${repo:t}/plugins/${omz_name}
        initfile=$plugdir/${omz_name}.plugin.zsh
      fi
    else
      initfile=$plugdir/${repo:t}.plugin.zsh
    fi

    # Clone and checkout appropriate files
    if [[ "$is_omz" == true ]]; then
      local base_repo_dir=$ZPLUGINDIR/${repo:t}

      # Initial clone with sparse-checkout if repo doesn't exist
      if [[ ! -d $base_repo_dir ]]; then
        echo "Cloning $repo..."
        git clone --filter=blob:none --no-checkout "${clone_args[@]}" https://github.com/$repo $base_repo_dir
        git -C $base_repo_dir sparse-checkout init --no-cone
        if [[ -n "$commitsha" ]]; then
          git -C $base_repo_dir fetch -q origin "$commitsha"
          git -C $base_repo_dir checkout -q "$commitsha"
        fi
      fi

      # Add the specific plugin/theme/lib to sparse-checkout
      local sparse_path="${omz_type}/${omz_name}"
      [[ "$omz_type" == "themes" ]] && sparse_path="themes/${omz_name}.zsh-theme"
      [[ "$omz_type" == "lib" ]] && sparse_path="lib/${omz_name}.zsh"

      # Append to sparse-checkout if not already there
      if ! git -C $base_repo_dir sparse-checkout list 2>/dev/null | grep -q "^${sparse_path}\$"; then
        echo "$sparse_path" >> $base_repo_dir/.git/info/sparse-checkout
      fi
      git -C $base_repo_dir checkout 2>/dev/null || true

      # Verify the file/directory exists
      if [[ ! -e $initfile ]] && [[ ! -d $plugdir ]]; then
        echo >&2 "Oh My Zsh ${omz_type} '${omz_name}' not found."
        continue
      fi
    elif [[ "$is_prezto" == true ]]; then
      local base_repo_dir=$ZPLUGINDIR/${repo:t}
      if [[ ! -d $base_repo_dir ]]; then
        echo "Cloning $repo..."
        git clone "${clone_args[@]}" https://github.com/$repo $base_repo_dir
        if [[ -n "$commitsha" ]]; then
          git -C $base_repo_dir fetch -q origin "$commitsha"
          git -C $base_repo_dir checkout -q "$commitsha"
        fi
      fi
      if [[ ! -d $plugdir ]]; then
        echo >&2 "Prezto module '$prezto_module' not found in $repo."
        continue
      fi
    else
      # Regular plugin repos
      if [[ ! -d $plugdir ]]; then
        echo "Cloning $repo..."
        git clone "${clone_args[@]}" https://github.com/$repo $plugdir
        if [[ -n "$commitsha" ]]; then
          git -C $plugdir fetch -q origin "$commitsha"
          git -C $plugdir checkout -q "$commitsha"
        fi
      fi
    fi

    # Add plugin directory to fpath (for completions and autoload functions)
    if [[ "$is_omz" == true ]]; then
      [[ "$omz_type" == "plugins" ]] && fpath+=$plugdir
      [[ -d "$plugdir/completions" ]] && fpath+="$plugdir/completions"
    elif [[ "$is_prezto" == true ]]; then
      fpath+=$plugdir
      [[ -d "$plugdir/functions" ]] && fpath+="$plugdir/functions"
    else
      fpath+=$plugdir
      [[ -d "$plugdir/completions" ]] && fpath+="$plugdir/completions"
    fi

    # Find and source the init file
    if [[ ! -e $initfile ]]; then
      # Look for plugin files in order of preference:
      # 1. init.zsh (Prezto standard)
      # 2. .plugin.zsh files (standard plugin format)
      # 3. .zsh-theme files (theme format)
      # 4. .zsh files (library/generic zsh files)
      # 5. .sh files (shell scripts)
      initfiles=(
        $plugdir/init.zsh(N)
        $plugdir/*.plugin.zsh(N)
        $plugdir/*.zsh-theme(N)
        $plugdir/*.zsh(N)
        $plugdir/*.sh(N)
      )

      # If we found at least one file, use the first one
      if (( $#initfiles )); then
        ln -sf $initfiles[1] $initfile
      else
        # No sourceable file found - this is OK for completion-only plugins
        # Just skip sourcing but keep the plugin in fpath for completions
        continue
      fi
    fi

    # Source the init file (with optional deferred loading)
    (( $+functions[zsh-defer] )) && zsh-defer . $initfile || . $initfile
  done
}
