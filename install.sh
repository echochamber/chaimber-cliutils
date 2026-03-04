#!/usr/bin/env bash
# install.sh — Install chaimber-cliutils (claudegrep)
#
# Symlinks tools into ~/.claude/scripts/ so they're on PATH.
# Safe to re-run — existing symlinks are updated, regular files are skipped
# unless --force is given.
#
# Usage:
#   ./install.sh              # install (interactive)
#   ./install.sh --dry-run    # show what would be done
#   ./install.sh --force      # overwrite existing files (not just symlinks)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.claude/scripts"

# --- Options ---
dry_run=false
force=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    --force) force=true ;;
    -h|--help)
      echo "Usage: install.sh [--dry-run] [--force]"
      echo "  --dry-run  Show what would be done without making changes"
      echo "  --force    Overwrite existing files (not just symlinks)"
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

# --- Symlink map: source → target ---
declare -a LINKS=(
  "claudegrep/claudegrep:claudegrep"
)

# --- Install ---
mkdir -p "$INSTALL_DIR"

installed=0
skipped=0
errors=0

for entry in "${LINKS[@]}"; do
  src="${SCRIPT_DIR}/${entry%%:*}"
  target="${INSTALL_DIR}/${entry##*:}"

  if [ ! -f "$src" ]; then
    echo "  SKIP  ${entry%%:*} (source not found)"
    ((skipped++)) || true
    continue
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ -L "$target" ]; then
      # Existing symlink — update it
      if $dry_run; then
        echo "  UPDATE  $target → $src"
      else
        ln -sf "$src" "$target"
        echo "  UPDATE  $target → $src"
      fi
      ((installed++)) || true
    elif $force; then
      # Regular file + --force — replace it
      if $dry_run; then
        echo "  REPLACE $target → $src"
      else
        rm -f "$target"
        ln -sf "$src" "$target"
        echo "  REPLACE $target → $src"
      fi
      ((installed++)) || true
    else
      echo "  SKIP  $target (existing file; use --force to overwrite)"
      ((skipped++)) || true
    fi
  else
    # New symlink
    if $dry_run; then
      echo "  CREATE  $target → $src"
    else
      ln -sf "$src" "$target"
      echo "  CREATE  $target → $src"
    fi
    ((installed++)) || true
  fi
done

# Make claudegrep executable
if ! $dry_run; then
  chmod +x "$SCRIPT_DIR/claudegrep/claudegrep"
fi

echo ""
if $dry_run; then
  echo "Dry run complete. $installed would be installed, $skipped skipped."
else
  echo "Done. $installed installed, $skipped skipped."
  echo ""
  echo "Verify:"
  echo "  which claudegrep    # should be $INSTALL_DIR/claudegrep"
  echo "  claudegrep --help"
fi
