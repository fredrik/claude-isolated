# claude-isolated

Run Claude Code with `--dangerously-skip-permissions` in a Podman (or Docker) container.

Claude is isolated from your host system: only the code you're working on (and Claude's config) is available inside the container.

I made this so Claude can run freely ("yolo mode") without constantly asking for permissions, while staying sandboxed. More sandboxing is certainly possible though! The main goal is to let Claude work without my constant interruption.

## What you get

Sandboxed `claude` sessions in a Debian container with Python, uv, git, and Claude Code pre-installed.

## Prerequisites

- [Podman](https://podman.io/) or [Docker](https://www.docker.com/)
- [uv](https://docs.astral.sh/uv/)

## Container runtime

`claude-isolated` auto-detects the container runtime, preferring Podman over
Docker when both are installed.

Podman is recommended: it runs rootless by default, and `claude-isolated`
passes `--userns=keep-id` so your host user is mapped into the container and
mounted volumes stay writable. That flag is Podman-specific and is skipped when
running under Docker. With Docker, mounted-volume ownership depends on your
daemon configuration (e.g. rootless mode or userns-remap), so if Claude can't
write to `/home/claude` or `/workspace`, that's the thing to check.

## How to use claude-isolated

Install:

```
uv tool install git+https://github.com/fredrik/claude-isolated
```

This command installs a single `claude-isolated` Python script to `~/.local/bin` (uv's default).


Bootstrap your config:

```
claude-isolated init
```

`init` copies the 'home.example' directory to the config directory (`~/.config/claude-isolated/home`). You might want to set your name and email in `.gitconfig`.

Start a container from your project directory:

```
cd ~/code/my-project
claude-isolated
```

You can also pass a prompt directly:

```
claude-isolated "fix the failing tests"
```

`claude-isolated` will mount your project (the current directory) to `/workspace` inside the container. It will also mount the files inside `~/.config/claude-isolated/home` on your host to `/home/claude` inside the container. Any edits by Claude to either code or settings via the mounted volumes are reflected on your host system: the files are read-write both ways.

## First-time auth

On first start, Claude Code will prompt you to authenticate. The credentials are persisted to the config directory via the volume mount, as are any other Claude configurations. They are shared across all `claude-isolated` sessions via the config directory.

## Usage notes

Your normal CLAUDE.md and other Claude config is not included by default, nor are any other files from your system.

Sessions are resumable since conversation history is stored in the shared config directory.

Closing Claude Code (Ctrl-D twice, Ctrl-C twice, or `/exit`) will stop the container.

Closing the terminal tab, etc, should also stop the container.

Use `claude-isolated ls` to list your running sessions.

Use `claude-isolated stop` to stop / remove a running session.


## Development process

Nearly all of this repo was written by Claude Code inside a sandboxed "yolo" environment.

README.md was written by a human. Promise!


## Feedback

Please open an issue or PR if you have trouble or if there's something you wish to improve!

