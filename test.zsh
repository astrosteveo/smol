#!/usr/bin/env zsh
# Quick test to verify sparse checkout logic

# Test directory
ZPLUGINDIR=/data/data/com.termux/files/home/workspace/smol/test-plugins
mkdir -p $ZPLUGINDIR

# Source the plugin manager
source /data/data/com.termux/files/home/workspace/smol/zsh_unplugged.zsh

echo "Testing Oh My Zsh sparse checkout..."
echo "======================================"

# Test OMZP (plugin)
repos=('OMZP::git')
plugin-load $repos

if [[ -f $ZPLUGINDIR/ohmyzsh/plugins/git/git.plugin.zsh ]]; then
  echo "✓ OMZP::git - Plugin file exists"
else
  echo "✗ OMZP::git - Plugin file NOT found"
fi

# Test OMZL (lib)
repos=('OMZL::clipboard')
plugin-load $repos

if [[ -f $ZPLUGINDIR/ohmyzsh/lib/clipboard.zsh ]]; then
  echo "✓ OMZL::clipboard - Lib file exists"
else
  echo "✗ OMZL::clipboard - Lib file NOT found"
fi

# Check sparse checkout is active
echo ""
echo "Sparse checkout status:"
git -C $ZPLUGINDIR/ohmyzsh sparse-checkout list

# Clean up
# rm -rf $ZPLUGINDIR
echo ""
echo "Test directory: $ZPLUGINDIR"
echo "(Not cleaned up for inspection)"
