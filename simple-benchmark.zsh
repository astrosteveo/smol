#!/usr/bin/env zsh
# Simple Performance Benchmark for Pluck
# Measures startup time using time command

BENCH_DIR="$PWD/benchmark-plugins"
mkdir -p "$BENCH_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "${BLUE}======================================${NC}"
echo "${BLUE}  Pluck Simple Startup Benchmark${NC}"
echo "${BLUE}======================================${NC}\n"

# Helper to measure startup time
measure_startup() {
  local config=$1
  local name=$2
  local iterations=10
  local total=0

  echo "${GREEN}Benchmarking: $name${NC}"

  for i in {1..$iterations}; do
    local start=$(($(date +%s%N)/1000000))
    zsh -c "source $config; exit" 2>/dev/null
    local end=$(($(date +%s%N)/1000000))
    local elapsed=$((end - start))
    total=$((total + elapsed))
  done

  local avg=$((total / iterations))
  echo "  Average startup: ${avg}ms (${iterations} iterations)\n"
  echo "$avg" > "$BENCH_DIR/${name//[^a-zA-Z0-9]/_}.result"
}

# Baseline
cat > $BENCH_DIR/baseline.zshrc <<'EOF'
PS1='%~ %# '
EOF

measure_startup "$BENCH_DIR/baseline.zshrc" "Baseline"

# Pluck with 5 OMZ plugins
cat > $BENCH_DIR/pluck.zshrc <<EOF
ZPLUGINDIR="$BENCH_DIR/pluck"
source $PWD/zsh_unplugged.zsh
repos=('OMZP::git' 'OMZP::sudo' 'OMZP::docker')
plugin-load \$repos 2>/dev/null
PS1='%~ %# '
EOF

# Pre-load
ZPLUGINDIR="$BENCH_DIR/pluck" zsh -c "source $PWD/zsh_unplugged.zsh && plugin-load OMZP::git OMZP::sudo OMZP::docker" 2>/dev/null

measure_startup "$BENCH_DIR/pluck.zshrc" "Pluck (3 OMZ plugins)"

# Display results
echo "${BLUE}======================================${NC}"
echo "${BLUE}           Results Summary${NC}"
echo "${BLUE}======================================${NC}\n"

baseline=$(cat $BENCH_DIR/Baseline.result)
pluck=$(cat $BENCH_DIR/Pluck_3_OMZ_plugins_.result 2>/dev/null || echo "0")

printf "%-25s %10s ms\n" "Baseline:" "$baseline"
printf "%-25s %10s ms\n" "Pluck (3 plugins):" "$pluck"

if [[ $pluck -gt 0 ]]; then
  overhead=$((pluck - baseline))
  printf "\n${YELLOW}Overhead from plugins: ${overhead}ms${NC}\n"
fi

echo "\n${GREEN}✓ Benchmark complete!${NC}"
