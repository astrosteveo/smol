# Pluck Architecture

This document explains the design decisions and internal workings of Pluck v2.

## Design Philosophy

**Core Principle:** Maximize simplicity while supporting Oh My Zsh and Prezto plugins without framework bloat.

**Anti-Goals:**
- No complex state management
- No fancy update mechanisms
- No dependency resolution
- No configuration files

The filesystem IS the state. Git IS the update mechanism.

## High-Level Flow

```
User Input → Parse → Clone → Path Setup → Source
```

Each plugin goes through these phases independently:

1. **Parse Phase** - Determine plugin type and extract metadata
2. **Clone Phase** - Download plugin (if not already present)
3. **Path Phase** - Add directories to `fpath` for completions
4. **Source Phase** - Find and source init file

## Plugin Type Taxonomy

```
┌─────────────────────────────────────────────────────────┐
│                   Plugin Types                          │
├──────────────┬──────────────────────────────────────────┤
│ omz-plugin   │ Oh My Zsh plugin (plugins/name/)        │
│ omz-theme    │ Oh My Zsh theme (themes/name.zsh-theme) │
│ omz-lib      │ Oh My Zsh library (lib/name.zsh)        │
│ prezto-mod   │ Prezto module (modules/name/)           │
│ prezto-contrib│ Prezto contrib (name/)                  │
│ regular      │ Standard GitHub repo (user/repo)        │
└──────────────┴──────────────────────────────────────────┘
```

## Parse Phase

### Input Formats

```zsh
# Oh My Zsh
'OMZP::git'              → type: omz-plugin,   name: git
'OMZT::robbyrussell'     → type: omz-theme,    name: robbyrussell
'OMZL::clipboard'        → type: omz-lib,      name: clipboard

# Prezto
'PZT::editor'            → type: prezto-mod,   name: editor
'PZTC::kubernetes'       → type: prezto-contrib, name: kubernetes

# Regular
'user/repo'              → type: regular,      repo: user/repo

# Version pinning (works with any type)
'OMZP::git@abc123'       → name: git, sha: abc123
'user/repo@def456'       → repo: user/repo, sha: def456
```

### Logic

```zsh
case "$plugin" in
  OMZP::*) plugin_type="omz-plugin" ;;
  OMZT::*) plugin_type="omz-theme" ;;
  OMZL::*) plugin_type="omz-lib" ;;
  PZT::*)  plugin_type="prezto-mod" ;;
  PZTC::*) plugin_type="prezto-contrib" ;;
  *)       plugin_type="regular" ;;
esac

# Extract @sha if present
if [[ "$input" == *'@'* ]]; then
  sha="${input#*@}"
  input="${input%@*}"
fi
```

## Clone Phase

### Strategy Matrix

| Type | Method | Why |
|------|--------|-----|
| OMZ (all) | Sparse checkout | Save 13+ MB per plugin |
| Prezto | Full shallow clone | Need module structure |
| Regular | Shallow clone | Standard approach |

### Oh My Zsh Sparse Checkout

**Problem:** OMZ is a 14 MB monorepo with 300+ plugins. We only need 1-2.

**Solution:** Git sparse checkout

```zsh
# Clone once with no files
git clone --filter=blob:none --no-checkout \
  https://github.com/ohmyzsh/ohmyzsh $ZPLUGINDIR/ohmyzsh

# Enable sparse checkout
git sparse-checkout init --no-cone

# Request specific paths
echo "plugins/git" >> .git/info/sparse-checkout
echo "plugins/docker" >> .git/info/sparse-checkout

# Checkout only requested files
git checkout
```

**Result:** Only the requested plugin directories are downloaded.

**Path Mapping:**
```
OMZP::git       → plugins/git/
OMZT::agnoster  → themes/agnoster.zsh-theme
OMZL::clipboard → lib/clipboard.zsh
```

### Prezto Clone

**Problem:** Prezto modules depend on framework structure.

**Solution:** Clone entire framework once, reference specific modules.

```zsh
# Clone full framework (shallow)
git clone --depth 1 https://github.com/sorin-ionescu/prezto \
  $ZPLUGINDIR/prezto

# Modules live at: prezto/modules/name/
# Contrib lives at: prezto-contrib/name/
```

### Regular Repos

**Standard shallow clone:**

```zsh
git clone --depth 1 --recursive --shallow-submodules \
  https://github.com/user/repo $ZPLUGINDIR/repo
```

### Version Pinning

When a SHA is specified:

```zsh
git clone --no-checkout ...  # Don't checkout master
git fetch origin $sha         # Fetch specific commit
git checkout $sha             # Checkout pinned version
```

## Path Phase

Add plugin directories to `fpath` so Zsh can find completions and functions.

```zsh
# Always add plugin directory
fpath=("$plugdir" $fpath)

# Add completions/ subdirectory if it exists
[[ -d "$plugdir/completions" ]] && fpath=("$plugdir/completions" $fpath)

# Prezto: also add functions/ directory
[[ -d "$plugdir/functions" ]] && fpath=("$plugdir/functions" $fpath)
```

**Why prepend?** So plugin completions take priority over system completions.

## Source Phase

### Init File Detection

**Priority order** (first match wins):

```
1. init.zsh           (Prezto standard - highest priority)
2. *.plugin.zsh       (Oh My Zsh plugin)
3. *.zsh-theme        (Theme file)
4. *.zsh              (Generic Zsh file)
5. *.sh               (Shell script fallback)
```

**Why this order?**
- Prezto uses `init.zsh` as the standard entry point
- OMZ plugins use `{name}.plugin.zsh`
- Themes use `.zsh-theme` extension
- Generic Zsh files are `.zsh`
- Shell scripts are `.sh`

### Symlink Strategy

If multiple files match, we create a symlink to the first match:

```zsh
ln -sf "$plugdir/actual-file.zsh" "$plugdir/{name}.plugin.zsh"
```

This provides a consistent path for future loads without re-detecting.

### Sourcing

```zsh
# With zsh-defer support (optional deferred loading)
(( $+functions[zsh-defer] )) && zsh-defer . "$initfile" || . "$initfile"
```

If `zsh-defer` is available, defer loading for faster startup. Otherwise, source immediately.

### Completion-Only Plugins

Some plugins (like `rustup`, `cargo`) only provide completions with no init file.

**Behavior:** If no init file is found, skip sourcing but keep the plugin in `fpath`.

**Result:** Completions still work, no error.

## Error Handling Philosophy

**Principle:** Fail gracefully. One broken plugin shouldn't break shell startup.

```
Plugin not found    → Print warning, continue
Clone fails         → Print error, continue
No init file        → Silent (completion-only), continue
Source fails        → Zsh handles it, continue
```

**Why?** Your shell should always start, even if a plugin is temporarily broken.

## Architecture Decisions

### AD-1: Single Function Interface

**Decision:** One function `plugin-load` handles everything.

**Rationale:**
- Simple user interface
- Follows zsh_unplugged pattern
- Easy to understand

**Tradeoff:** Larger function (~250 lines), but clearer for users.

### AD-2: Sparse Checkout for OMZ

**Decision:** Use git sparse-checkout for Oh My Zsh.

**Rationale:**
- Saves 13+ MB per plugin
- Only downloads what you need
- Maintains full git repo benefits

**Tradeoff:** More complex git commands, but massive space savings.

### AD-3: Filesystem as State

**Decision:** No state tracking database or config files.

**Rationale:**
- Simplest possible implementation
- No state corruption issues
- Easy to debug (just look at directories)

**Tradeoff:** Can't track metadata like "why" or "when" plugin was installed.

### AD-4: Prefix-Based Type System

**Decision:** Explicit prefixes (OMZP::, OMZT::, etc.).

**Rationale:**
- Clear and unambiguous
- No auto-detection complexity
- Impossible to mistake plugin type

**Tradeoff:** Slightly more typing, but worth the clarity.

### AD-5: Fail Gracefully

**Decision:** Print errors but continue loading.

**Rationale:**
- Shell startup should never fail
- Users can fix issues later
- Better UX than cryptic errors

**Tradeoff:** Users might miss error messages in output.

### AD-6: No Update Command

**Decision:** No built-in update mechanism.

**Rationale:**
- `rm -rf && reload` is simple enough
- Keeps code minimal
- Users have full control

**Tradeoff:** Less convenient than `plugin-update`, but simpler code.

## Performance Considerations

### Sparse Checkout Impact

**Without sparse checkout:**
- Clone OMZ: 14 MB download
- 5 plugins: 70 MB total

**With sparse checkout:**
- Clone OMZ base: ~2 MB
- 5 plugins: ~200 KB each = 3 MB total

**Savings:** ~67 MB for 5 plugins (95% reduction)

### Shallow Clone Benefits

```zsh
--depth 1              # Only latest commit (~80% size reduction)
--shallow-submodules   # Don't fetch full submodule history
--filter=blob:none     # Don't fetch file contents until checkout
```

### Deferred Loading

Optional support for `zsh-defer` allows plugins to load in background:

```zsh
(( $+functions[zsh-defer] )) && zsh-defer . "$initfile"
```

**Benefit:** Shell starts faster, plugins load asynchronously.

## Code Organization

```
pluck.zsh
├── Header (documentation, usage examples)
├── plugin-load function
│   ├── Variable initialization
│   ├── For loop over plugins
│   │   ├── PARSE PHASE (type detection)
│   │   ├── CLONE PHASE (git operations)
│   │   ├── PATH PHASE (fpath management)
│   │   └── SOURCE PHASE (init file detection + sourcing)
│   └── End loop
└── End function
```

**Total:** ~270 lines
- ~40 lines: Header/comments
- ~230 lines: Functional code

## Future Considerations

**What could be added (if needed):**
- Update command (fetch + checkout)
- List command (show installed plugins)
- Health check (verify plugin integrity)
- Parallel cloning (clone multiple at once)
- Lock file (for reproducible environments)

**What should NOT be added:**
- Complex dependency management
- Plugin search/discovery
- Automatic framework detection
- Git operations beyond clone/fetch/checkout

## Testing Strategy

**Manual testing focus areas:**

1. Regular GitHub repos
2. OMZ plugins (sparse checkout)
3. OMZ themes
4. OMZ libs
5. Prezto modules
6. Prezto contrib
7. Version pinning
8. Completion-only plugins
9. Error cases (repo not found, etc.)

**Test command:**

```zsh
# Source the function
source pluck.zsh

# Test each type
repos=(
  'zsh-users/zsh-syntax-highlighting'
  'OMZP::git'
  'OMZT::robbyrussell'
  'OMZL::clipboard'
  'PZT::editor'
)
plugin-load $repos
```

## Debugging

**Check what was cloned:**

```zsh
ls -la $ZPLUGINDIR
```

**Check OMZ sparse checkout:**

```zsh
git -C $ZPLUGINDIR/ohmyzsh sparse-checkout list
```

**Check if plugin sourced:**

```zsh
which <plugin-function>  # See if function exists
echo $fpath | tr ' ' '\n' | grep <plugin>  # Check fpath
```

## Credits

- Based on [zsh_unplugged](https://github.com/mattmc3/zsh_unplugged) by mattmc3
- Sparse checkout inspiration from git documentation
- Design decisions learned from Pluck v1
