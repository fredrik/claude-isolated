# CLAUDE

Run Claude Code in isolated Podman containers with Zellij sessions.

## Structure

```
Containerfile              # Debian bookworm-slim image
scripts/
  claude-isolated          # Dispatcher: routes subcommands, default = build + start .
  claude-isolated-build    # podman build
  claude-isolated-start    # Generate name, mount config, podman run
  claude-isolated-enter    # podman exec + zellij attach --create
  claude-isolated-stop     # podman stop + rm
  claude-isolated-ls       # podman ps --filter ancestor=claude-isolated
config/
  wordlist.txt             # Adjectives + nouns for random naming (blank line separates sections)
  layout.kdl               # Zellij layout: launches claude --dangerously-skip-permissions
home.example/              # Bootstrap template for ~/.config/claude-isolated/home
tests/
  test-lifecycle.sh        # Automated build/start/verify/stop test
```

## Config

Container config lives at `~/.config/claude-isolated/home/` (override with `CLAUDE_ISOLATED_HOME`). This mirrors `/home/claude/` inside the container. `.gitconfig`, `.ssh/`, and `.claude/CLAUDE.md` are mounted read-only; the rest read-write.

## Testing

```
./tests/test-lifecycle.sh
```

Requires Podman running. Builds image, starts a container, verifies tools (python3, uv, claude, git, zellij), checks workspace, then stops and cleans up.

## Conventions

- Scripts are bash with `set -euo pipefail`
- Container user is `claude` (`/home/claude/`)
- Container names follow `claude-isolated-{adjective}-{noun}` pattern
- Image tag is `claude-isolated:latest`
- No nodejs/npm — Claude Code installed via `claude.ai/install.sh`
