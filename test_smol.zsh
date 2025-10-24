#!/usr/bin/env zsh
# Unit tests for Pluck plugin manager
# Tests Oh My Zsh and Prezto plugin loading

# Test configuration
TEST_DIR="${TMPDIR:-/data/data/com.termux/files/home}/smol-test-$$"
ZPLUGINDIR="$TEST_DIR/plugins"
PASSED=0
FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Setup test environment
setup() {
  echo "${YELLOW}Setting up test environment...${NC}"
  mkdir -p "$ZPLUGINDIR"
  source /data/data/com.termux/files/home/workspace/smol/zsh_unplugged.zsh
}

# Teardown test environment
teardown() {
  echo "${YELLOW}Cleaning up test environment...${NC}"
  rm -rf "$TEST_DIR"
}

# Test assertion helpers
assert_file_exists() {
  local file="$1"
  local desc="$2"
  if [[ -f "$file" ]]; then
    echo "${GREEN}✓${NC} $desc"
    ((PASSED++))
    return 0
  else
    echo "${RED}✗${NC} $desc"
    echo "  Expected file: $file"
    ((FAILED++))
    return 1
  fi
}

assert_dir_exists() {
  local dir="$1"
  local desc="$2"
  if [[ -d "$dir" ]]; then
    echo "${GREEN}✓${NC} $desc"
    ((PASSED++))
    return 0
  else
    echo "${RED}✗${NC} $desc"
    echo "  Expected directory: $dir"
    ((FAILED++))
    return 1
  fi
}

assert_sparse_checkout_contains() {
  local repo_dir="$1"
  local pattern="$2"
  local desc="$3"
  if git -C "$repo_dir" sparse-checkout list 2>/dev/null | grep -q "$pattern"; then
    echo "${GREEN}✓${NC} $desc"
    ((PASSED++))
    return 0
  else
    echo "${RED}✗${NC} $desc"
    echo "  Expected sparse-checkout to contain: $pattern"
    echo "  Actual sparse-checkout list:"
    git -C "$repo_dir" sparse-checkout list 2>/dev/null | sed 's/^/    /'
    ((FAILED++))
    return 1
  fi
}

# Test: OMZP (Oh My Zsh Plugin)
test_omzp_plugin() {
  echo "\n${YELLOW}Test: OMZP::git (Oh My Zsh git plugin)${NC}"

  repos=('OMZP::git')
  plugin-load $repos 2>/dev/null

  assert_dir_exists "$ZPLUGINDIR/ohmyzsh" \
    "OMZ repo directory created"

  assert_file_exists "$ZPLUGINDIR/ohmyzsh/plugins/git/git.plugin.zsh" \
    "git.plugin.zsh exists"

  assert_sparse_checkout_contains "$ZPLUGINDIR/ohmyzsh" "plugins/git" \
    "Sparse checkout includes plugins/git"

  # Verify it's actually sparse (not full clone)
  if [[ ! -d "$ZPLUGINDIR/ohmyzsh/plugins/docker" ]]; then
    echo "${GREEN}✓${NC} Sparse checkout verified (docker plugin NOT present)"
    ((PASSED++))
  else
    echo "${RED}✗${NC} Sparse checkout failed (full repo was cloned)"
    ((FAILED++))
  fi
}

# Test: OMZL (Oh My Zsh Lib)
test_omzl_lib() {
  echo "\n${YELLOW}Test: OMZL::clipboard (Oh My Zsh lib)${NC}"

  repos=('OMZL::clipboard')
  plugin-load $repos 2>/dev/null

  assert_file_exists "$ZPLUGINDIR/ohmyzsh/lib/clipboard.zsh" \
    "clipboard.zsh exists"

  assert_sparse_checkout_contains "$ZPLUGINDIR/ohmyzsh" "lib/clipboard.zsh" \
    "Sparse checkout includes lib/clipboard.zsh"
}

# Test: OMZT (Oh My Zsh Theme)
test_omzt_theme() {
  echo "\n${YELLOW}Test: OMZT::robbyrussell (Oh My Zsh theme)${NC}"

  repos=('OMZT::robbyrussell')
  plugin-load $repos 2>/dev/null

  assert_file_exists "$ZPLUGINDIR/ohmyzsh/themes/robbyrussell.zsh-theme" \
    "robbyrussell.zsh-theme exists"

  assert_sparse_checkout_contains "$ZPLUGINDIR/ohmyzsh" "themes/robbyrussell.zsh-theme" \
    "Sparse checkout includes themes/robbyrussell.zsh-theme"
}

# Test: PZT (Prezto Module)
test_pzt_module() {
  echo "\n${YELLOW}Test: PZT::git (Prezto git module)${NC}"

  repos=('PZT::git')
  plugin-load $repos 2>/dev/null

  assert_dir_exists "$ZPLUGINDIR/prezto" \
    "Prezto repo directory created"

  assert_dir_exists "$ZPLUGINDIR/prezto/modules/git" \
    "Prezto git module directory exists"

  assert_file_exists "$ZPLUGINDIR/prezto/modules/git/init.zsh" \
    "Prezto git module init.zsh exists"

  # Check for functions directory
  if [[ -d "$ZPLUGINDIR/prezto/modules/git/functions" ]]; then
    echo "${GREEN}✓${NC} Prezto git module has functions directory"
    ((PASSED++))
  else
    echo "${YELLOW}~${NC} Prezto git module has no functions directory (may be normal)"
  fi
}

# Test: PZTC (Prezto Contrib Module)
test_pztc_module() {
  echo "\n${YELLOW}Test: PZTC::zoxide (Prezto contrib module)${NC}"

  repos=('PZTC::zoxide')
  plugin-load $repos 2>/dev/null

  assert_dir_exists "$ZPLUGINDIR/prezto-contrib" \
    "Prezto contrib repo directory created"

  # Prezto-contrib has modules at root, not in modules/ subdirectory
  assert_dir_exists "$ZPLUGINDIR/prezto-contrib/zoxide" \
    "Prezto contrib zoxide module directory exists"

  assert_file_exists "$ZPLUGINDIR/prezto-contrib/zoxide/init.zsh" \
    "Prezto contrib zoxide module init.zsh exists"
}

# Test: Multiple OMZ plugins with sparse checkout
test_omz_multiple_sparse() {
  echo "\n${YELLOW}Test: Multiple OMZ plugins with sparse checkout${NC}"

  repos=('OMZP::sudo' 'OMZL::git')
  plugin-load $repos 2>/dev/null

  assert_file_exists "$ZPLUGINDIR/ohmyzsh/plugins/sudo/sudo.plugin.zsh" \
    "sudo.plugin.zsh exists"

  assert_file_exists "$ZPLUGINDIR/ohmyzsh/lib/git.zsh" \
    "git.zsh exists"

  assert_sparse_checkout_contains "$ZPLUGINDIR/ohmyzsh" "plugins/sudo" \
    "Sparse checkout includes plugins/sudo"

  assert_sparse_checkout_contains "$ZPLUGINDIR/ohmyzsh" "lib/git.zsh" \
    "Sparse checkout includes lib/git.zsh"
}

# Test: OMZ plugin with completions subdirectory
test_omz_completions() {
  echo "\n${YELLOW}Test: OMZ plugin with completions (docker)${NC}"

  repos=('OMZP::docker')
  plugin-load $repos 2>/dev/null

  assert_file_exists "$ZPLUGINDIR/ohmyzsh/plugins/docker/docker.plugin.zsh" \
    "docker.plugin.zsh exists"

  # Check if completions directory exists (if docker plugin has it)
  if [[ -d "$ZPLUGINDIR/ohmyzsh/plugins/docker/completions" ]]; then
    echo "${GREEN}✓${NC} Docker plugin has completions directory"
    ((PASSED++))
  else
    echo "${YELLOW}~${NC} Docker plugin has no completions directory (checking plugin structure)"
  fi
}

# Print summary
print_summary() {
  echo "\n========================================"
  echo "Test Summary"
  echo "========================================"
  echo "${GREEN}Passed:${NC} $PASSED"
  echo "${RED}Failed:${NC} $FAILED"
  echo "========================================"

  if [[ $FAILED -eq 0 ]]; then
    echo "${GREEN}All tests passed! ✓${NC}"
    return 0
  else
    echo "${RED}Some tests failed! ✗${NC}"
    return 1
  fi
}

# Run all tests
main() {
  echo "${YELLOW}===========================================${NC}"
  echo "${YELLOW}    Pluck Plugin Manager Unit Tests${NC}"
  echo "${YELLOW}===========================================${NC}"

  setup

  # Run tests
  test_omzp_plugin
  test_omzl_lib
  test_omzt_theme
  test_omz_multiple_sparse
  test_omz_completions
  test_pzt_module
  test_pztc_module

  print_summary
  local exit_code=$?

  teardown

  return $exit_code
}

# Execute tests
main
