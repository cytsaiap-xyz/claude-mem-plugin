#!/usr/bin/env bash
# install-plugin.sh
# Copies claude-mem plugin files to the Claude Code plugin directory
#
# Usage:
#   bash install-plugin.sh              # Install to default location
#   bash install-plugin.sh /custom/path # Install to custom Claude config path

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[info]${NC}  $1"; }
success() { echo -e "${GREEN}[ok]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC}  $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_VERSION="10.6.2"
PLUGIN_NAME="claude-mem"
MARKETPLACE="thedotmack"

# Determine Claude config directory
if [ -n "$1" ]; then
  CLAUDE_DIR="$1"
elif [ -n "$CLAUDE_CONFIG_DIR" ]; then
  CLAUDE_DIR="$CLAUDE_CONFIG_DIR"
else
  CLAUDE_DIR="$HOME/.claude"
fi

TARGET_DIR="$CLAUDE_DIR/plugins/cache/$MARKETPLACE/$PLUGIN_NAME/$PLUGIN_VERSION"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

main() {
  echo ""
  echo "  ╭───────────────────────────────────────╮"
  echo "  │                                       │"
  echo "  │   claude-mem Plugin Installer          │"
  echo "  │   v$PLUGIN_VERSION                          │"
  echo "  │                                       │"
  echo "  ╰───────────────────────────────────────╯"
  echo ""
  echo "  Source:  $SCRIPT_DIR"
  echo "  Target:  $TARGET_DIR"
  echo ""

  # --- Check source files exist ---
  if [ ! -f "$SCRIPT_DIR/package.json" ]; then
    error "package.json not found in $SCRIPT_DIR"
    error "Please run this script from the claude-mem-plugin directory."
    exit 1
  fi

  # --- Create target directory ---
  info "Creating plugin directory..."
  mkdir -p "$TARGET_DIR"
  success "Directory created: $TARGET_DIR"

  # --- Clean old installation if exists ---
  if [ "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]; then
    warn "Existing installation found, cleaning..."
    rm -rf "$TARGET_DIR"/*
    rm -rf "$TARGET_DIR"/.claude-plugin
    rm -f "$TARGET_DIR"/.mcp.json
    success "Old files removed"
  fi

  # --- Copy plugin files ---
  info "Copying plugin files..."

  # Core config
  cp -r "$SCRIPT_DIR/.claude-plugin" "$TARGET_DIR/"
  cp "$SCRIPT_DIR/.mcp.json" "$TARGET_DIR/"
  cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET_DIR/"
  cp "$SCRIPT_DIR/package.json" "$TARGET_DIR/"
  success "Core config files"

  # Hooks
  cp -r "$SCRIPT_DIR/hooks" "$TARGET_DIR/"
  success "Hooks ($(ls "$SCRIPT_DIR/hooks" | wc -l | tr -d ' ') files)"

  # Scripts
  cp -r "$SCRIPT_DIR/scripts" "$TARGET_DIR/"
  chmod +x "$TARGET_DIR/scripts/claude-mem" 2>/dev/null || true
  success "Scripts ($(ls "$SCRIPT_DIR/scripts" | wc -l | tr -d ' ') files)"

  # Skills
  cp -r "$SCRIPT_DIR/skills" "$TARGET_DIR/"
  success "Skills ($(ls -d "$SCRIPT_DIR/skills"/*/ | wc -l | tr -d ' ') skills)"

  # Modes
  cp -r "$SCRIPT_DIR/modes" "$TARGET_DIR/"
  success "Modes ($(ls "$SCRIPT_DIR/modes" | wc -l | tr -d ' ') files)"

  # UI
  cp -r "$SCRIPT_DIR/ui" "$TARGET_DIR/"
  success "UI assets"

  # --- Verify installation ---
  info "Verifying installation..."
  FILE_COUNT=$(find "$TARGET_DIR" -type f | wc -l | tr -d ' ')
  success "Installed $FILE_COUNT files"

  # --- Register plugin in settings.json ---
  info "Checking plugin registration..."

  if [ -f "$SETTINGS_FILE" ]; then
    if grep -q "claude-mem@thedotmack" "$SETTINGS_FILE" 2>/dev/null; then
      success "Plugin already registered in settings.json"
    else
      warn "Plugin not found in settings.json"
      echo ""
      echo "  Add these entries to your $SETTINGS_FILE:"
      echo ""
      echo '  In "enabledPlugins":'
      echo '    "claude-mem@thedotmack": true'
      echo ""
      echo '  In "extraKnownMarketplaces":'
      echo '    "thedotmack": {'
      echo '      "source": {'
      echo '        "source": "github",'
      echo '        "repo": "thedotmack/claude-mem"'
      echo '      }'
      echo '    }'
      echo ""
    fi
  else
    warn "settings.json not found at $SETTINGS_FILE"
    info "Creating settings.json with plugin registration..."
    cat > "$SETTINGS_FILE" << 'SETTINGS_EOF'
{
  "enabledPlugins": {
    "claude-mem@thedotmack": true
  },
  "extraKnownMarketplaces": {
    "thedotmack": {
      "source": {
        "source": "github",
        "repo": "thedotmack/claude-mem"
      }
    }
  }
}
SETTINGS_EOF
    success "settings.json created with plugin registered"
  fi

  # --- Done ---
  echo ""
  success "============================================"
  success "  claude-mem v$PLUGIN_VERSION installed!"
  success "============================================"
  echo ""
  echo "  Installed to:"
  echo "    $TARGET_DIR"
  echo ""
  echo "  Next steps:"
  echo "    1. Restart Claude Code"
  echo "    2. Dependencies will auto-install on first session"
  echo "    3. Use /mem-search to search memories"
  echo ""
}

main "$@"
