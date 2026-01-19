# Agent Config

Inspired by https://github.com/brianlovin/claude-config

Shared configuration and skills for AI coding assistants. One source of truth for both [Claude Code](https://claude.ai/claude-code) and [Opencode](https://opencode.ai).

## Setup

```bash
# Clone the repo
git clone <your-repo-url> ~/code/agent-config
cd ~/code/agent-config

# Install (creates symlinks to both tools)
./install.sh
```

## Commands

| Command | Description |
|---------|-------------|
| `./install.sh` | Symlink all skills and configs to Claude and Opencode |
| `./sync.sh status` | Show sync status of all skills |
| `./sync.sh pull` | Pull latest changes from git and reinstall |
| `./sync.sh push "msg"` | Commit and push changes to git |
| `./sync.sh add <name>` | Import a skill from `~/.claude/skills/` into the repo |

## Skills

| Skill | Description |
|-------|-------------|
| `systematic-debugging` | Fix bugs using Dan Abramov's systematic debugging method |
| `web-design-guidelines` | Review UI code against Vercel's Web Interface Guidelines |
| `design-review` | Run accessibility and visual design review on components |
| `deslop` | Remove AI-generated code slop from the current branch |
| `react-best-practices` | React and Next.js performance optimization guidelines from Vercel Engineering |


## Adding New Skills

1. Create the skill in Claude Code/Opencode as normal
2. Import it into the repo: `./sync.sh add my-new-skill`
3. Push to git: `./sync.sh push "Added my-new-skill"`

The skill will now be available in both Claude Code and Opencode.
