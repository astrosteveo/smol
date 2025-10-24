#!/usr/bin/env zsh
# Pluck Performance Benchmark Suite
# Compares Pluck vs Oh My Zsh vs Prezto startup times and resource usage

BENCHMARK_DIR="$PWD/benchmark-results"
PLUGINS_DIR="$PWD/benchmark-plugins"
ZSH_BENCH="$PWD/zsh-bench/zsh-bench"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

mkdir -p "$BENCHMARK_DIR"
mkdir -p "$PLUGINS_DIR"

echo "${BLUE}========================================${NC}"
echo "${BLUE}   Pluck Performance Benchmark Suite${NC}"
echo "${BLUE}========================================${NC}\n"

# Cleanup function
cleanup() {
  echo "\n${YELLOW}Cleaning up benchmark environments...${NC}"
  rm -rf "$PLUGINS_DIR"
}

trap cleanup EXIT

# ============================================
# Scenario 1: Baseline (no plugins)
# ============================================
benchmark_baseline() {
  echo "${GREEN}[1/5] Benchmarking: Baseline (no plugins)${NC}"

  cat > $HOME/.zshrc-baseline <<'EOF'
# Baseline - minimal zshrc
PS1='%~ %# '
EOF

  ZDOTDIR=$HOME zsh -c "source $HOME/.zshrc-baseline && $ZSH_BENCH --iters 10" \
    > "$BENCHMARK_DIR/baseline.txt" 2>&1

  echo "  ✓ Baseline benchmark complete"
}

# ============================================
# Scenario 2: Pluck with 5 OMZ plugins
# ============================================
benchmark_pluck() {
  echo "${GREEN}[2/5] Benchmarking: Pluck (5 OMZ plugins)${NC}"

  cat > $HOME/.zshrc-pluck <<EOF
# Pluck configuration
ZPLUGINDIR="$PLUGINS_DIR/pluck"
source $PWD/zsh_unplugged.zsh

repos=(
  'OMZP::git'
  'OMZP::sudo'
  'OMZP::docker'
  'OMZP::kubectl'
  'OMZP::colored-man-pages'
)
plugin-load \$repos

PS1='%~ %# '
EOF

  # Pre-load plugins to avoid timing the initial clone
  ZPLUGINDIR="$PLUGINS_DIR/pluck" zsh -c "source $PWD/zsh_unplugged.zsh && plugin-load OMZP::git OMZP::sudo OMZP::docker OMZP::kubectl OMZP::colored-man-pages" 2>/dev/null

  ZDOTDIR=$HOME zsh -c "source $HOME/.zshrc-pluck && $ZSH_BENCH --iters 10" \
    > "$BENCHMARK_DIR/pluck.txt" 2>&1

  # Measure disk usage
  du -sh "$PLUGINS_DIR/pluck" > "$BENCHMARK_DIR/pluck-disk.txt"
  find "$PLUGINS_DIR/pluck" -type f | wc -l > "$BENCHMARK_DIR/pluck-files.txt"

  echo "  ✓ Pluck benchmark complete"
}

# ============================================
# Scenario 3: Oh My Zsh (full install)
# ============================================
benchmark_omz() {
  echo "${GREEN}[3/5] Benchmarking: Oh My Zsh (full framework)${NC}"

  # Install OMZ
  export ZSH="$PLUGINS_DIR/ohmyzsh"
  if [[ ! -d "$ZSH" ]]; then
    echo "  Installing Oh My Zsh..."
    git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$ZSH" 2>/dev/null
  fi

  cat > $HOME/.zshrc-omz <<EOF
export ZSH="$ZSH"
ZSH_THEME="robbyrussell"
plugins=(git sudo docker kubectl colored-man-pages)
source \$ZSH/oh-my-zsh.sh
EOF

  ZDOTDIR=$HOME zsh -c "source $HOME/.zshrc-omz && $ZSH_BENCH --iters 10" \
    > "$BENCHMARK_DIR/omz.txt" 2>&1

  # Measure disk usage
  du -sh "$ZSH" > "$BENCHMARK_DIR/omz-disk.txt"
  find "$ZSH" -type f | wc -l > "$BENCHMARK_DIR/omz-files.txt"

  echo "  ✓ Oh My Zsh benchmark complete"
}

# ============================================
# Scenario 4: Prezto (full install)
# ============================================
benchmark_prezto() {
  echo "${GREEN}[4/5] Benchmarking: Prezto (full framework)${NC}"

  # Install Prezto
  export ZPREZTODIR="$PLUGINS_DIR/prezto"
  if [[ ! -d "$ZPREZTODIR" ]]; then
    echo "  Installing Prezto..."
    git clone --depth 1 --recursive https://github.com/sorin-ionescu/prezto.git "$ZPREZTODIR" 2>/dev/null
  fi

  cat > $HOME/.zshrc-prezto <<EOF
export ZPREZTODIR="$ZPREZTODIR"
source "\$ZPREZTODIR/init.zsh"

# Enable modules
zstyle ':prezto:load' pmodule 'git' 'editor' 'history' 'directory' 'utility' 'completion'
PS1='%~ %# '
EOF

  ZDOTDIR=$HOME zsh -c "source $HOME/.zshrc-prezto && $ZSH_BENCH --iters 10" \
    > "$BENCHMARK_DIR/prezto.txt" 2>&1

  # Measure disk usage
  du -sh "$ZPREZTODIR" > "$BENCHMARK_DIR/prezto-disk.txt"
  find "$ZPREZTODIR" -type f | wc -l > "$BENCHMARK_DIR/prezto-files.txt"

  echo "  ✓ Prezto benchmark complete"
}

# ============================================
# Scenario 5: Pluck with mixed OMZ + Prezto
# ============================================
benchmark_pluck_mixed() {
  echo "${GREEN}[5/5] Benchmarking: Pluck (mixed OMZ + Prezto)${NC}"

  cat > $HOME/.zshrc-pluck-mixed <<EOF
# Pluck mixed configuration
ZPLUGINDIR="$PLUGINS_DIR/pluck-mixed"
source $PWD/zsh_unplugged.zsh

repos=(
  'OMZP::git'
  'OMZP::docker'
  'PZT::editor'
  'PZT::completion'
  'OMZL::clipboard'
)
plugin-load \$repos

PS1='%~ %# '
EOF

  # Pre-load plugins
  ZPLUGINDIR="$PLUGINS_DIR/pluck-mixed" zsh -c "source $PWD/zsh_unplugged.zsh && plugin-load OMZP::git OMZP::docker PZT::editor PZT::completion OMZL::clipboard" 2>/dev/null

  ZDOTDIR=$HOME zsh -c "source $HOME/.zshrc-pluck-mixed && $ZSH_BENCH --iters 10" \
    > "$BENCHMARK_DIR/pluck-mixed.txt" 2>&1

  # Measure disk usage
  du -sh "$PLUGINS_DIR/pluck-mixed" > "$BENCHMARK_DIR/pluck-mixed-disk.txt"
  find "$PLUGINS_DIR/pluck-mixed" -type f | wc -l > "$BENCHMARK_DIR/pluck-mixed-files.txt"

  echo "  ✓ Pluck mixed benchmark complete"
}

# ============================================
# Parse and display results
# ============================================
display_results() {
  echo "\n${BLUE}========================================${NC}"
  echo "${BLUE}         Benchmark Results${NC}"
  echo "${BLUE}========================================${NC}\n"

  parse_result() {
    local file=$1
    local name=$2

    if [[ -f "$file" ]]; then
      # Extract first command lag from zsh-bench output
      local cmd_lag=$(grep "first_command" "$file" | head -1 | awk '{print $2}')
      local input_lag=$(grep "input_lag" "$file" | head -1 | awk '{print $2}')
      local startup=$(grep "exit_time" "$file" | head -1 | awk '{print $2}')

      echo "${name}:"
      echo "  Startup time: ${startup:-N/A} ms"
      echo "  Input lag:    ${input_lag:-N/A} ms"
      echo "  Command lag:  ${cmd_lag:-N/A} ms"
    else
      echo "${name}: ${RED}No data${NC}"
    fi
  }

  parse_result "$BENCHMARK_DIR/baseline.txt" "${YELLOW}Baseline${NC}"
  echo ""
  parse_result "$BENCHMARK_DIR/pluck.txt" "${GREEN}Pluck (5 OMZ plugins)${NC}"
  echo ""
  parse_result "$BENCHMARK_DIR/omz.txt" "${RED}Oh My Zsh${NC}"
  echo ""
  parse_result "$BENCHMARK_DIR/prezto.txt" "${BLUE}Prezto${NC}"
  echo ""
  parse_result "$BENCHMARK_DIR/pluck-mixed.txt" "${GREEN}Pluck (mixed)${NC}"

  echo "\n${BLUE}========================================${NC}"
  echo "${BLUE}       Resource Usage Comparison${NC}"
  echo "${BLUE}========================================${NC}\n"

  show_disk_usage() {
    local name=$1
    local disk_file=$2
    local files_file=$3

    if [[ -f "$disk_file" ]] && [[ -f "$files_file" ]]; then
      local disk=$(cat "$disk_file" | awk '{print $1}')
      local files=$(cat "$files_file")
      printf "%-25s %10s    %6s files\n" "$name:" "$disk" "$files"
    fi
  }

  show_disk_usage "Pluck (5 OMZ plugins)" "$BENCHMARK_DIR/pluck-disk.txt" "$BENCHMARK_DIR/pluck-files.txt"
  show_disk_usage "Oh My Zsh" "$BENCHMARK_DIR/omz-disk.txt" "$BENCHMARK_DIR/omz-files.txt"
  show_disk_usage "Prezto" "$BENCHMARK_DIR/prezto-disk.txt" "$BENCHMARK_DIR/prezto-files.txt"
  show_disk_usage "Pluck (mixed)" "$BENCHMARK_DIR/pluck-mixed-disk.txt" "$BENCHMARK_DIR/pluck-mixed-files.txt"

  echo "\n${GREEN}✓ All benchmarks complete!${NC}"
  echo "Raw data saved to: $BENCHMARK_DIR/"
}

# ============================================
# Run all benchmarks
# ============================================
main() {
  if [[ ! -x "$ZSH_BENCH" ]]; then
    echo "${RED}Error: zsh-bench not found at $ZSH_BENCH${NC}"
    echo "Please run: git clone https://github.com/romkatv/zsh-bench.git"
    exit 1
  fi

  benchmark_baseline
  benchmark_pluck
  benchmark_omz
  benchmark_prezto
  benchmark_pluck_mixed

  display_results
}

main "$@"
