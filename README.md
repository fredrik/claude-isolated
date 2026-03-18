# claude-isolated

Run Claude Code in isolated containers with [zellij](https://zellij.dev/) sessions.

Each container gets its own workspace, while sharing an isolated set of Claude auth and config and git config.

## Prerequisites

- [Podman](https://podman.io/)
- [uv](https://docs.astral.sh/uv/)

## Quick start

Install:

```
ln -s "$(pwd)/bin/claude-isolated" ~/.local/bin/claude-isolated
```

Bootstrap your config:

```
claude-isolated init
```

Edit the files with your actual values:

| File | What to put there |
|------|-------------------|
| `.gitconfig` | Your name and email |
| `.config/gh/hosts.yml` | Copy from `~/.config/gh/hosts.yml` (GitHub CLI auth) |
| `.claude.json` | Copy from `~/.claude.json` |
| `.claude/` | Copy from `~/.claude/` (settings, credentials, CLAUDE.md, etc.) |

Start a container from the directory you want mounted at `/workspace`:

```
cd ~/code/my-project
claude-isolated start
```

Or use the default shorthand (builds image then starts):

```
cd ~/code/my-project
claude-isolated
```

You can also pass a prompt directly:

```
claude-isolated "fix the failing tests"
```

## First-time auth

If you don't have `credentials.json` yet, start a container without it. Claude Code will prompt you to authenticate. The credentials file is written inside the container at `/home/claude/.claude/.credentials.json` and persisted back to your config directory via the volume mount.

## Commands

| Command | Purpose |
|---------|---------|
| `claude-isolated [prompt]` | Build image + start container (default) |
| `claude-isolated init` | Create config directory from template |
| `claude-isolated build` | Build the container image |
| `claude-isolated start [prompt]` | Start a new container (mounts cwd) |
| `claude-isolated stop <name>` | Stop and remove a container |
| `claude-isolated ls` | List running containers |

## Structure

```
Containerfile              # Debian bookworm-slim image
bin/
  claude-isolated          # Main script (uv run): build, start, stop, ls
container/
  start-zellij             # Entrypoint: launches zellij with an inline layout
  start-claude             # Launches claude --dangerously-skip-permissions
  zellij-config.kdl        # Zellij config (no startup tips, bash as default shell)
home.example/              # Bootstrap template for ~/.config/claude-isolated/home
tests/
  test-lifecycle.sh        # Automated build/start/verify/stop test
```

## Config location

Defaults to `~/.config/claude-isolated/home`. Override with `CLAUDE_ISOLATED_HOME`.

The directory mirrors the container's `/home/claude/`:

```
~/.config/claude-isolated/home/
├── .claude.json
├── .claude/              (rw — settings, credentials, CLAUDE.md, etc.)
├── .config/
│   └── gh/
│       └── hosts.yml
└── .gitconfig
```

`.gitconfig` is mounted read-only. The rest (`.claude/`, `.claude.json`, `.config/gh/`) are read-write so Claude Code can update auth tokens, session state, and settings.
