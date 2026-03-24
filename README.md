# claude-mem Plugin v10.6.2

Persistent memory system for [Claude Code](https://claude.com/claude-code) that preserves context across sessions. Forked from [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem).

## What It Does

claude-mem automatically captures observations during your Claude Code sessions (bug fixes, features, discoveries, decisions) and stores them in a local SQLite database. On the next session, relevant memories are injected as context — so Claude "remembers" what happened before.

## Architecture

```
Claude Code Session
        │
    [Hooks]  ← lifecycle integration
        ├─ SessionStart  → smart-install + start worker service
        ├─ UserPromptSubmit → initialize session state
        ├─ PostToolUse   → capture observations from tool results
        ├─ Stop          → generate session summaries
        └─ SessionEnd    → finalize session
        │
  [Worker Service]  (localhost:37777)
        ├─ SQLite DB (~/.claude-mem/claude-mem.db)
        ├─ /api/search, /api/context/inject
        └─ Timeline data serving
        │
    [MCP Server]  (mcp-server.cjs)
        ├─ search, timeline, get_observations tools
        └─ Exposed to Claude Code as MCP tools
        │
    [Skills]  ← user-invocable commands
        └─ /mem-search, /timeline-report, /smart-explore, /make-plan, /do
        │
    [Modes]  ← context profiles
        └─ code, law-study, email-investigation + 30 localized versions
        │
    [UI]  (viewer.html)
        └─ Visual memory browser
```

## File Structure

```
claude-mem-plugin/
│
├── .claude-plugin/
│   ├── plugin.json          # Plugin metadata (name, version, keywords)
│   └── CLAUDE.md            # Plugin config session history
│
├── .mcp.json                # MCP server config → runs mcp-server.cjs
│
├── hooks/
│   ├── hooks.json           # Lifecycle hook definitions (6 events)
│   ├── CLAUDE.md            # Hook system development history
│   └── bugfixes-2026-01-10.md  # Active bugfix tracking
│
├── scripts/
│   ├── claude-mem           # Main binary (Bun-compiled, ~60MB)
│   ├── mcp-server.cjs       # MCP server for memory search tools
│   ├── worker-service.cjs   # Background worker (SQLite, API server)
│   ├── worker-wrapper.cjs   # Worker process wrapper
│   ├── worker-cli.js        # Worker CLI interface
│   ├── context-generator.cjs # Context injection generator
│   ├── smart-install.js     # Auto-dependency installer
│   ├── bun-runner.js        # Bun runtime wrapper
│   ├── statusline-counts.js # Status line memory counter
│   └── CLAUDE.md            # Scripts development history
│
├── skills/
│   ├── mem-search/SKILL.md      # 3-layer memory search (search → timeline → fetch)
│   ├── smart-explore/SKILL.md   # AST-based code exploration via tree-sitter
│   ├── make-plan/SKILL.md       # Phased implementation planning
│   ├── do/SKILL.md              # Plan executor with subagents
│   └── timeline-report/SKILL.md # Narrative session analysis generator
│
├── modes/
│   ├── code.json                # Default coding mode (6 observation types)
│   ├── code--zh.json            # Chinese localized coding mode
│   ├── code--ja.json            # Japanese localized coding mode
│   ├── code--ko.json            # Korean localized coding mode
│   ├── code--{lang}.json        # 30+ other language localizations
│   ├── code--chill.json         # Relaxed coding mode variant
│   ├── law-study.json           # Legal study assistant mode
│   ├── law-study--chill.json    # Relaxed legal study mode
│   ├── law-study-CLAUDE.md      # Legal mode documentation
│   └── email-investigation.json # Email analysis mode
│
├── ui/
│   ├── viewer.html              # Memory browser UI (HTML/CSS/JS)
│   ├── viewer-bundle.js         # Bundled viewer JavaScript
│   ├── claude-mem-logo-*.webp   # Branding assets
│   ├── icon-thick-*.svg         # Status icons (completed, investigated, learned, next-steps)
│   ├── assets/fonts/            # Monaspace Radon font files
│   └── CLAUDE.md                # UI development history
│
├── package.json                 # Dependencies (tree-sitter parsers × 9 languages)
├── CLAUDE.md                    # Root session context
└── README.md                    # This file
```

## Observation Types

| Emoji | Type | Description |
|-------|------|-------------|
| 🔴 | `bugfix` | Something was broken, now fixed |
| 🟣 | `feature` | New capability added |
| 🔄 | `refactor` | Code restructured, behavior unchanged |
| ✅ | `change` | Generic modification (docs, config, misc) |
| 🔵 | `discovery` | Learning about existing system |
| ⚖️ | `decision` | Architectural/design choice with rationale |

## Skills

| Skill | Usage | Description |
|-------|-------|-------------|
| **mem-search** | `/mem-search` | 3-layer memory search: index → timeline → full details |
| **smart-explore** | `/smart-explore` | AST-based code exploration (4-8x token savings vs Read) |
| **make-plan** | `/make-plan` | Create phased implementation plans with doc discovery |
| **do** | `/do` | Execute plans with subagents + verification |
| **timeline-report** | `/timeline-report` | Generate narrative analysis of session history |

## Installation

### Method 1: Via Claude Code Plugin Marketplace (requires internet)

```bash
# Add marketplace
claude plugin marketplace add thedotmack/claude-mem

# Install plugin
claude plugin install claude-mem
```

### Method 2: From This Repo (offline / manual)

1. Clone or download this repo:
   ```bash
   git clone https://github.com/cytsaiap-xyz/claude-mem-plugin.git
   ```

2. Copy the plugin files to your Claude Code plugins directory:
   ```bash
   # Create the plugin directory
   mkdir -p ~/.claude/plugins/cache/thedotmack/claude-mem/10.6.2

   # Copy all files
   cp -r claude-mem-plugin/* ~/.claude/plugins/cache/thedotmack/claude-mem/10.6.2/
   cp -r claude-mem-plugin/.claude-plugin ~/.claude/plugins/cache/thedotmack/claude-mem/10.6.2/
   cp claude-mem-plugin/.mcp.json ~/.claude/plugins/cache/thedotmack/claude-mem/10.6.2/
   ```

3. Register the plugin in your Claude Code settings (`~/.claude/settings.json`):
   ```json
   {
     "plugins": {
       "claude-mem@thedotmack": {
         "enabled": true,
         "scope": "user"
       }
     }
   }
   ```

4. Restart Claude Code. The `smart-install.js` hook will auto-install runtime dependencies (Bun, tree-sitter parsers) on first session start.

## Requirements

- **Claude Code** CLI
- **Node.js** >= 18.0.0 or **Bun** >= 1.0.0
- Dependencies are auto-installed by `smart-install.js` on first run

## Data Storage

- **Database**: `~/.claude-mem/claude-mem.db` (SQLite)
- **Worker API**: `localhost:37777`

## Known Issues

- **Linux**: Bun stdin handling may cause `fstat EINVAL` crash ([#646](https://github.com/thedotmack/claude-mem/issues/646))
- **Crash loop**: Missing `memory_session_id` can trigger infinite recovery ([#623](https://github.com/thedotmack/claude-mem/issues/623))

## License

AGPL-3.0 — Original author: [Alex Newman (thedotmack)](https://github.com/thedotmack/claude-mem)

## Source

- Original repo: https://github.com/thedotmack/claude-mem
- This copy: https://github.com/cytsaiap-xyz/claude-mem-plugin
