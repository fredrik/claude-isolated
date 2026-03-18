# CLAUDE

Run Claude Code in isolated Podman containers with Zellij sessions.

## Structure

```
Containerfile              # Debian bookworm-slim image
scripts/
  claude-isolated          # Python script (uv run): build, start, stop, ls
config/
  layout.kdl               # Zellij layout: launches claude --dangerously-skip-permissions
home.example/              # Bootstrap template for ~/.config/claude-isolated/home
tests/
  test-lifecycle.sh        # Automated build/start/verify/stop test
```

## Config

Container config lives at `~/.config/claude-isolated/home/` (override with `CLAUDE_ISOLATED_HOME`). This mirrors `/home/claude/` inside the container. `.gitconfig` is mounted read-only; the rest (`.claude/`, `.claude.json`, `.config/gh/`) read-write.

## Testing

```
./tests/test-lifecycle.sh
```

Requires Podman running. Builds image, starts a container, verifies tools (python3, uv, claude, git, zellij), checks workspace, then stops and cleans up.

## Conventions

- Main script is Python, runnable via `uv run scripts/claude-isolated`
- Container user is `claude` (`/home/claude/`)
- Container names follow `claude-isolated-{random-name or hex}` pattern
- Image tag is `claude-isolated:latest`
- No nodejs/npm — Claude Code installed via `claude.ai/install.sh`
