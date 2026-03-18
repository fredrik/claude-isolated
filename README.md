# claude-isolated

Run Claude Code in isolated containers with [zellij](https://zellij.dev/) sessions.

Each container gets its own workspace, while sharing an isolated set of Claude auth and config, git config, and SSH keys.

## Prerequisites

- [Podman](https://podman.io/)

## Quick start

Install:

```
ln -s "$(pwd)/scripts/claude-isolated" ~/.local/bin/claude-isolated
```

Build the image:

```
claude-isolated build
```

Bootstrap your config:

```
mkdir -p ~/.config/claude-isolated
cp -r home.example ~/.config/claude-isolated/home
```

Edit the files with your actual values:

| File | What to put there |
|------|-------------------|
| `.gitconfig` | Your name and email |
| `.ssh/` | SSH keys for git access |
| `.config/gh/hosts.yml` | Copy from `~/.config/gh/hosts.yml` (GitHub CLI auth) |
| `.claude.json` | Copy from `~/.claude.json` |
| `.claude/` | Copy from `~/.claude/` (settings, credentials, CLAUDE.md, etc.) |

Start a container from the directory you want mounted at `/workspace`:

```
cd ~/code/my-project
claude-isolated start
```

Attach to it:

```
claude-isolated enter claude-isolated-bright-falcon
```

This opens a zellij session with Claude Code running.

## First-time auth

If you don't have `credentials.json` yet, start and enter a container without it. Claude Code will prompt you to authenticate. The credentials file is written inside the container at `/home/claude/.claude/.credentials.json`.

Copy it to your config dir so future containers pick it up:

```
podman cp <container-name>:/home/claude/.claude/.credentials.json \
  ~/.config/claude-isolated/home/.claude/credentials.json
```

## Commands

| Command | Purpose |
|---------|---------|
| `claude-isolated build` | Build the container image |
| `claude-isolated start` | Start a new container (mounts cwd) |
| `claude-isolated enter <name>` | Attach to a running container |
| `claude-isolated stop <name>` | Stop and remove a container |
| `claude-isolated ls` | List running containers |

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
├── .gitconfig
└── .ssh/
```

`.gitconfig` and `.ssh/` are mounted read-only. The rest (`.claude/`, `.claude.json`, `.config/gh/`) are read-write so Claude Code can update auth tokens, session state, and settings.
