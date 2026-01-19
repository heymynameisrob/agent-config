#!/bin/bash
set -e

# Colors and formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Print header
header() {
    echo ""
    echo -e "${BOLD}Agent Config Sync${NC}"
    echo -e "${DIM}─────────────────────────────────────${NC}"
    echo ""
}

# Show usage
usage() {
    header
    echo -e "${BOLD}Usage:${NC} ./sync.sh <command>"
    echo ""
    echo -e "${BOLD}Commands:${NC}"
    echo -e "  ${GREEN}status${NC}    Show sync status of all skills"
    echo -e "  ${GREEN}pull${NC}      Pull latest changes and reinstall"
    echo -e "  ${GREEN}push${NC}      Commit and push changes"
    echo -e "  ${GREEN}add${NC}       Add a skill from ~/.claude/skills/"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  ${DIM}./sync.sh status${NC}"
    echo -e "  ${DIM}./sync.sh pull${NC}"
    echo -e "  ${DIM}./sync.sh push \"Added new skill\"${NC}"
    echo -e "  ${DIM}./sync.sh add my-skill${NC}"
    echo ""
}

# Show status of skills
status() {
    header
    echo -e "${BOLD}Skills${NC}"

    # Check skills in repo
    for skill_dir in "$SCRIPT_DIR"/skills/*/; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            # Remove trailing slash for comparison
            skill_path="${skill_dir%/}"

            # Check Claude symlink
            claude_link=~/.claude/skills/"$skill_name"
            opencode_link=~/.config/opencode/skill/"$skill_name"

            claude_status=""
            opencode_status=""

            if [ -L "$claude_link" ]; then
                link_target=$(readlink "$claude_link")
                if [ "$link_target" = "$skill_path" ]; then
                    claude_status="${GREEN}✓${NC}"
                else
                    claude_status="${YELLOW}→${NC}"
                fi
            elif [ -d "$claude_link" ]; then
                claude_status="${RED}⚠${NC}"
            else
                claude_status="${DIM}○${NC}"
            fi

            if [ -L "$opencode_link" ]; then
                link_target=$(readlink "$opencode_link")
                if [ "$link_target" = "$skill_path" ]; then
                    opencode_status="${GREEN}✓${NC}"
                else
                    opencode_status="${YELLOW}→${NC}"
                fi
            elif [ -d "$opencode_link" ]; then
                opencode_status="${RED}⚠${NC}"
            else
                opencode_status="${DIM}○${NC}"
            fi

            echo -e "  $skill_name  ${DIM}[claude:${NC}$claude_status${DIM}]${NC} ${DIM}[opencode:${NC}$opencode_status${DIM}]${NC}"
        fi
    done

    echo ""
    echo -e "${DIM}Legend: ${GREEN}✓${NC}${DIM} synced  ${NC}${DIM}○${NC}${DIM} not installed  ${YELLOW}→${NC}${DIM} external link  ${RED}⚠${NC}${DIM} conflict${NC}"
    echo ""
}

# Pull latest changes
pull() {
    header
    echo -e "${BLUE}Pulling latest changes...${NC}"
    git pull
    echo ""
    echo -e "${BLUE}Reinstalling...${NC}"
    "$SCRIPT_DIR/install.sh"
}

# Update README skills table
update_readme() {
    local readme="$SCRIPT_DIR/Readme.md"
    local temp_file=$(mktemp)
    local in_skills_table=false
    local table_header_found=false
    local table_separator_found=false
    local skills_in_readme=()
    local skills_in_dir=()

    # Get skills from directory
    for skill_dir in "$SCRIPT_DIR"/skills/*/; do
        if [ -d "$skill_dir" ]; then
            skills_in_dir+=($(basename "$skill_dir"))
        fi
    done

    # Read existing skills from README table
    while IFS= read -r line; do
        if [[ "$line" =~ ^\|[[:space:]]*\`([a-zA-Z0-9_-]+)\`[[:space:]]*\| ]]; then
            skills_in_readme+=("${BASH_REMATCH[1]}")
        fi
    done < "$readme"

    # Find skills to add (in dir but not in readme)
    local skills_to_add=()
    for skill in "${skills_in_dir[@]}"; do
        local found=false
        for existing in "${skills_in_readme[@]}"; do
            if [ "$skill" = "$existing" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            skills_to_add+=("$skill")
        fi
    done

    # Find skills to remove (in readme but not in dir)
    local skills_to_remove=()
    for existing in "${skills_in_readme[@]}"; do
        local found=false
        for skill in "${skills_in_dir[@]}"; do
            if [ "$skill" = "$existing" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            skills_to_remove+=("$existing")
        fi
    done

    # If no changes needed, return
    if [ ${#skills_to_add[@]} -eq 0 ] && [ ${#skills_to_remove[@]} -eq 0 ]; then
        return 0
    fi

    echo -e "${BLUE}Updating README skills table...${NC}"

    # Process README line by line
    in_skills_table=false
    while IFS= read -r line; do
        # Detect start of skills table
        if [[ "$line" =~ ^\|[[:space:]]*Skill[[:space:]]*\| ]]; then
            in_skills_table=true
            table_header_found=true
            echo "$line" >> "$temp_file"
            continue
        fi

        # Detect table separator
        if [ "$table_header_found" = true ] && [ "$table_separator_found" = false ] && [[ "$line" =~ ^\|[-]+\| ]]; then
            table_separator_found=true
            echo "$line" >> "$temp_file"
            continue
        fi

        # If in skills table and it's a skill row
        if [ "$in_skills_table" = true ] && [[ "$line" =~ ^\|[[:space:]]*\`([a-zA-Z0-9_-]+)\`[[:space:]]*\| ]]; then
            local skill_name="${BASH_REMATCH[1]}"

            # Check if this skill should be removed
            local should_remove=false
            for remove_skill in "${skills_to_remove[@]}"; do
                if [ "$skill_name" = "$remove_skill" ]; then
                    should_remove=true
                    echo -e "  ${RED}−${NC} Removed $skill_name from README"
                    break
                fi
            done

            if [ "$should_remove" = false ]; then
                echo "$line" >> "$temp_file"
            fi
            continue
        fi

        # Detect end of skills table (empty line or non-table line after table started)
        if [ "$in_skills_table" = true ] && [ "$table_separator_found" = true ] && ! [[ "$line" =~ ^\| ]]; then
            # Add new skills before ending the table
            for skill in "${skills_to_add[@]}"; do
                local skill_md="$SCRIPT_DIR/skills/$skill/SKILL.md"
                local description="TODO: Add description"
                local triggers="TODO: Add triggers"

                # Try to extract description from SKILL.md frontmatter
                if [ -f "$skill_md" ]; then
                    local desc_line=$(grep -m1 "^description:" "$skill_md" 2>/dev/null || true)
                    if [ -n "$desc_line" ]; then
                        description=$(echo "$desc_line" | sed 's/^description:[[:space:]]*//' | sed 's/[[:space:]]*$//')
                        # Truncate if too long and extract triggers from description
                        if [[ "$description" == *"Use when"* ]]; then
                            triggers=$(echo "$description" | sed 's/.*Use when //' | sed 's/\.$//')
                            description=$(echo "$description" | sed 's/[[:space:]]*Use when.*//')
                        fi
                    fi
                fi

                echo "| \`$skill\` | $description | $triggers |" >> "$temp_file"
                echo -e "  ${GREEN}+${NC} Added $skill to README"
            done

            in_skills_table=false
            echo "$line" >> "$temp_file"
            continue
        fi

        echo "$line" >> "$temp_file"
    done < "$readme"

    # Handle case where skills need to be added at the very end of table (no trailing content)
    if [ "$in_skills_table" = true ] && [ ${#skills_to_add[@]} -gt 0 ]; then
        for skill in "${skills_to_add[@]}"; do
            local skill_md="$SCRIPT_DIR/skills/$skill/SKILL.md"
            local description="TODO: Add description"
            local triggers="TODO: Add triggers"

            if [ -f "$skill_md" ]; then
                local desc_line=$(grep -m1 "^description:" "$skill_md" 2>/dev/null || true)
                if [ -n "$desc_line" ]; then
                    description=$(echo "$desc_line" | sed 's/^description:[[:space:]]*//' | sed 's/[[:space:]]*$//')
                    if [[ "$description" == *"Use when"* ]]; then
                        triggers=$(echo "$description" | sed 's/.*Use when //' | sed 's/\.$//')
                        description=$(echo "$description" | sed 's/[[:space:]]*Use when.*//')
                    fi
                fi
            fi

            echo "| \`$skill\` | $description | $triggers |" >> "$temp_file"
            echo -e "  ${GREEN}+${NC} Added $skill to README"
        done
    fi

    mv "$temp_file" "$readme"
    echo ""
}

# Push changes
push() {
    header
    local message="${1:-Update agent config}"

    # Update README skills table before checking for changes
    update_readme

    echo -e "${BLUE}Checking for changes...${NC}"

    if [ -z "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}No changes to commit.${NC}"
        echo ""
        return
    fi

    echo ""
    git status --short
    echo ""

    echo -e "${BLUE}Committing changes...${NC}"
    git add -A
    git commit -m "$message"

    echo ""
    echo -e "${BLUE}Pushing to remote...${NC}"
    git push

    echo ""
    echo -e "${GREEN}Done!${NC} Changes pushed successfully."
    echo ""
}

# Add a skill from ~/.claude/skills/
add() {
    header
    local skill_name="$1"

    if [ -z "$skill_name" ]; then
        echo -e "${RED}Error:${NC} Please provide a skill name."
        echo -e "${DIM}Usage: ./sync.sh add <skill-name>${NC}"
        echo ""
        exit 1
    fi

    local source_dir=~/.claude/skills/"$skill_name"
    local target_dir="$SCRIPT_DIR/skills/$skill_name"

    if [ ! -d "$source_dir" ]; then
        echo -e "${RED}Error:${NC} Skill not found at $source_dir"
        echo ""
        exit 1
    fi

    if [ -d "$target_dir" ]; then
        echo -e "${YELLOW}Warning:${NC} Skill already exists in repo."
        echo ""
        exit 1
    fi

    echo -e "${BLUE}Adding skill:${NC} $skill_name"

    # Copy skill to repo
    cp -R "$source_dir" "$target_dir"
    echo -e "  ${GREEN}✓${NC} Copied to repo"

    # Replace original with symlink
    rm -rf "$source_dir"
    ln -sfn "$target_dir" "$source_dir"
    echo -e "  ${GREEN}✓${NC} Symlinked Claude"

    # Also symlink for opencode
    ln -sfn "$target_dir" ~/.config/opencode/skill/"$skill_name"
    echo -e "  ${GREEN}✓${NC} Symlinked Opencode"

    echo ""
    echo -e "${GREEN}Done!${NC} Skill added. Run ${DIM}./sync.sh push${NC} to share."
    echo ""
}

# Main command handler
case "${1:-}" in
    status)
        status
        ;;
    pull)
        pull
        ;;
    push)
        push "$2"
        ;;
    add)
        add "$2"
        ;;
    *)
        usage
        ;;
esac
