# CLAUDE

Run Claude Code in isolated Podman containers with Zellij sessions.

## Structure

```
Containerfile              # Debian trixie-slim image
bin/
  claude-isolated          # Python script (uv run): build, start, stop, ls
  git-worktree-manager     # Bash script: run, ls, rm worktrees
container/
  start-zellij             # Entrypoint: launches zellij with an inline layout
  start-claude             # Launches claude --dangerously-skip-permissions
  zellij-config.kdl        # Zellij config (no startup tips, bash as default shell)
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

## Worktree Manager

`bin/git-worktree-manager` manages worktrees in bare-clone repos (the layout created by `git-clone-bare-worktree`). It creates worktrees as sibling directories at the project root with `wt/<name>` branches.

```bash
# Run claude-isolated in a new worktree
git-worktree-manager run --name fix-bug -- claude-isolated "fix the login bug"

# Run with auto-generated name
git-worktree-manager run -- bash

# List worktrees
git-worktree-manager ls

# Clean up
git-worktree-manager rm fix-bug
```

Works from anywhere inside the project tree — finds the root by walking up to `.bare/`.

## Conventions

- Main script is Python, runnable via `uv run bin/claude-isolated`
- Container user is `claude` (`/home/claude/`)
- Container names follow `claude-isolated-{random-name or hex}` pattern
- Image tag is `claude-isolated:latest`
- No nodejs/npm — Claude Code installed via `claude.ai/install.sh`
- Requires git 2.48+ in the container (for `relativeworktrees` extension used by worktree mounts); installed from Debian sid
