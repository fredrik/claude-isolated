# CLAUDE

Run Claude Code in isolated Podman containers with Zellij sessions.

## Structure

```
pyproject.toml                     # Package definition (hatchling)
src/claude_isolated/
  cli.py                           # CLI entrypoint: build, start, stop, ls, init
  data/
    Containerfile                  # Debian trixie-slim image
    container/
      start-zellij                 # Entrypoint: launches zellij with an inline layout
      start-claude                 # Launches claude --dangerously-skip-permissions
      zellij-config.kdl            # Zellij config (no startup tips, bash as default shell)
    home.example/                  # Bootstrap template for ~/.config/claude-isolated/home
tests/
  test-lifecycle.sh                # Automated build/start/verify/stop test
```

## Install

```
uv tool install git+https://github.com/fredrik/claude-isolated
```

## Config

Container config lives at `~/.config/claude-isolated/home/` (override with `CLAUDE_ISOLATED_HOME`). This mirrors `/home/claude/` inside the container. `.gitconfig` is mounted read-only; the rest (`.claude/`, `.claude.json`, `.config/gh/`) read-write.

## Testing

```
./tests/test-lifecycle.sh
```

Requires Podman running. Builds image, starts a container, verifies tools (python3, uv, claude, git, zellij), checks workspace, then stops and cleans up.

## Conventions

- Installable via `uv tool install` or `pipx install`
- Container user is `claude` (`/home/claude/`)
- Container names follow `claude-isolated-{random-name or hex}` pattern
- Image tag is `claude-isolated:latest`
- No nodejs/npm — Claude Code installed via `claude.ai/install.sh`
- Requires git 2.48+ in the container (for relative worktree paths); installed from Debian sid
