# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-03-26

### Added

- Worktree detection for isolated container mounts
- Enable `relativeWorktrees` git extension before creating worktrees
- Worktree-keeper integration (#1)
- Installable via `uv tool install` (#2)

### Changed

- Run Claude Code directly in the container, removing Zellij dependency (#3)
- Remove GitHub CLI (`gh`) from container image

### Fixed

- Container hang by adding `--userns=keep-id` to podman run (#4)

## [0.1.0] - 2026-03-18

### Added

- CLI with subcommands: `build`, `start`, `stop`, `ls`, `init`
- Debian trixie-slim based container image with Claude Code installed via `claude.ai/install.sh`
- Launch Claude Code with `--dangerously-skip-permissions`
- Config bootstrapping from `~/.config/claude-isolated/home/`
- `init` command to set up home directory from template
- Random container naming with wordlist (hex fallback)
- Optional prompt argument for initial Claude task
- Zellij multiplexer integration with custom layout
- Git diff `--stat` pane in Zellij layout
- GitHub CLI mounted into containers
- CLAUDE.md mount (conditional on file existence)
- Braille spinner during build step
- SIGTERM handler for container cleanup
- Automated lifecycle test script
- Pinned uv and Claude Code versions for reproducible builds
- Configurable uv and Claude Code versions via build args
- 256-color terminal support
- Timezone set to Europe/Stockholm

### Changed

- Replaced bash scripts with single Python CLI runnable via `uv`
- Switched from Alpine to Debian base image
- Refactored volume mounts into a data structure
- Run podman in subprocess and remove container when done
- Detect architecture for Zellij download instead of hardcoding aarch64

### Fixed

- Credentials source path to use `.credentials.json` (with leading dot)
- Interactive session handling on Debian
- Unclosed quote in test-lifecycle.sh
- Return code checking in `cmd_stop`
- Zellij tabs launching claude layout instead of plain bash

[0.2.0]: https://github.com/fredrik/claude-isolated/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/fredrik/claude-isolated/releases/tag/v0.1.0
