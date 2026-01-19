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

| Skill | Description | Triggers |
|-------|-------------|----------|
| `systematic-debugging` | Fix bugs using Dan Abramov's systematic debugging method. Forces a disciplined approach: establish reproduction case first, then fix. | debugging, fixing bugs, investigating errors, "bug", "broken", "not working" |
| `web-design-guidelines` | Review UI code against Vercel's Web Interface Guidelines. Fetches the latest guidelines and audits your code for compliance. | "review my UI", "check accessibility", "audit design", "review UX" |
| `design-review` | Run accessibility and visual design review on components. | reviewing UI code for WCAG compliance and design issues |
| `deslop` | Remove AI-generated code slop from the current branch. Use after writing code to clean up unnecessary comments, defensive checks, and inconsistent style. | TODO: Add triggers |
| `react-best-practices` | React and Next.js performance optimization guidelines from Vercel Engineering. This skill should be used when writing, reviewing, or refactoring React/Next.js code to ensure optimal performance patterns. Triggers on tasks involving React components, Next.js pages, data fetching, bundle optimization, or performance improvements. | TODO: Add triggers |

## Structure

```
agent-config/
├── install.sh        # Symlinks skills to both tools
├── sync.sh           # Git sync + skill management
└── skills/           # Shared skills
    ├── systematic-debugging/
    ├── vercel-react-best-practices/
    └── web-design-guidelines/
```

## Adding New Skills

1. Create the skill in Claude Code as normal
2. Import it into the repo: `./sync.sh add my-new-skill`
3. Push to git: `./sync.sh push "Added my-new-skill"`

The skill will now be available in both Claude Code and Opencode.
