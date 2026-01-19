#!/bin/bash
set -e

# Colors and formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo -e "${BOLD}Agent Config Installer${NC}"
echo -e "${DIM}─────────────────────────────────────${NC}"
echo ""

# Create target directories
echo -e "${BLUE}Creating directories...${NC}"
mkdir -p ~/.claude/skills
mkdir -p ~/.config/opencode/skill
echo ""

# Install skills for Claude Code
echo -e "${BOLD}Claude Code${NC} ${DIM}~/.claude/${NC}"
for skill_dir in "$SCRIPT_DIR"/skills/*/; do
    if [ -d "$skill_dir" ]; then
        skill_name=$(basename "$skill_dir")
        target=~/.claude/skills/"$skill_name"
        # Remove existing directory if not a symlink
        if [ -d "$target" ] && [ ! -L "$target" ]; then
            rm -rf "$target"
        fi
        ln -sfn "${skill_dir%/}" "$target"
        echo -e "  ${GREEN}✓${NC} $skill_name"
    fi
done
echo ""

# Install skills for Opencode
echo -e "${BOLD}Opencode${NC} ${DIM}~/.config/opencode/${NC}"
for skill_dir in "$SCRIPT_DIR"/skills/*/; do
    if [ -d "$skill_dir" ]; then
        skill_name=$(basename "$skill_dir")
        target=~/.config/opencode/skill/"$skill_name"
        # Remove existing directory if not a symlink
        if [ -d "$target" ] && [ ! -L "$target" ]; then
            rm -rf "$target"
        fi
        ln -sfn "${skill_dir%/}" "$target"
        echo -e "  ${GREEN}✓${NC} $skill_name"
    fi
done
echo ""

echo -e "${DIM}─────────────────────────────────────${NC}"
echo -e "${GREEN}Done!${NC} Config files symlinked successfully."
echo ""
echo -e "${DIM}Local-only items in ~/.claude/ and ~/.config/opencode/ are preserved.${NC}"
echo -e "${DIM}Run ./sync.sh to manage shared content.${NC}"
echo ""
