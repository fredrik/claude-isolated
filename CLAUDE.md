# CLAUDE

Run Claude Code in isolated Podman containers.

## Structure

```
pyproject.toml                     # Package definition (hatchling)
src/claude_isolated/
  cli.py                           # CLI entrypoint: build, start, stop, ls, init
  data/
    Containerfile                  # Debian trixie-slim image
    container/
      start-claude                 # Entrypoint: launches claude --dangerously-skip-permissions
    home.example/                  # Bootstrap template for ~/.config/claude-isolated/home
tests/
  test-lifecycle.sh                # Automated build/start/verify/stop test
```

## Install

```
uv tool install git+https://github.com/fredrik/claude-isolated
```

## Config

Container config lives at `~/.config/claude-isolated/home/` (override with `CLAUDE_ISOLATED_HOME`). This mirrors `/home/claude/` inside the container. `.gitconfig` is mounted read-only; the rest (`.claude/`, `.claude.json`) read-write.

## Testing

```
./tests/test-lifecycle.sh
```

Requires Podman or Docker. Builds image, starts a container, verifies tools (python3, uv, claude, git, zellij), checks workspace, then stops and cleans up.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): description`

Allowed types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`, `style`, `perf`, `build`

Enforced by a commit-msg hook in `.githooks/`. After cloning, run:

```
git config core.hooksPath .githooks
```

## Changelog

Update `CHANGELOG.md` when adding features, fixing bugs, or making other notable changes. Follow the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

## Conventions

- Installable via `uv tool install` or `pipx install`
- Container user is `claude` (`/home/claude/`)
- Container names follow `claude-isolated-{random-name or hex}` pattern
- Image tag is `claude-isolated:latest`
- No nodejs/npm — Claude Code installed via `claude.ai/install.sh`
- No zellij — Claude runs directly in the container
- Supports both Podman and Docker (auto-detected, prefers Podman)
- Requires git 2.48+ in the container (for relative worktree paths); installed from Debian sid
