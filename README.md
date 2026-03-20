# claude-isolated

Run Claude Code with `--dangerously-skip-permissions` in an isolated Podman container.

Only the code you're working on (and Claude's config) is available to Claude.

I made this in order to be able to let Claude Code run freely without constantly asking for permissions while being mostly safe inside a sandboxed environment. More sandboxing is certainly possible though! The main focus is being able to move quickly and somewhat safely.

## Prerequisites

- [Podman](https://podman.io/)
- [uv](https://docs.astral.sh/uv/)

## How to use claude-isolated

Install:

```
uv tool install git+https://github.com/fredrik/claude-isolated
```

This command installs a single `claude-isolated` Python script to `~/.local/bin` (as per uv standard).


Bootstrap your config:

```
claude-isolated init
```

The bootstrap copies the 'home.example' directory to the config directory `~/.config/claude-isolated/home`. You might want to edit `.gitconfig`. Please note that your normal CLAUDE.md and other Claude config is not included by default, nor is any other files from your system.


Start a container from your project directory:

```
cd ~/code/my-project
claude-isolated
```

You can also pass a prompt directly:

```
claude-isolated "fix the failing tests"
```

`claude-isolated` will mount your project (the current directory) to `/workspace` inside the container. It will also mount the files inside `~/.config/claude-isolated/home` on your host to `/home/claude` inside the container. Any edits to those mounts are reflected on your host system.

## First-time auth

On first start, Claude Code will prompt you to authenticate. The credentials are persisted to the config directory via the volume mount, as are any other Claude configurations. Auths and configs are shared across all `claude-isolated` sessions, just like they are in 'normal' `claude` sessions.

## Usage notes

Closing the first Claude Code instance (Ctrl-D twice, Ctrl-C twice, or `/exit`) will also close the zellij session and stop the container. New tabs opened within the session are plain bash panes and won't affect this behaviour.

Closing the terminal tab, etc, should also close the session.

Sessions are resumable as usual since `~/.config/claude-isolated/home/.claude` is shared between sessions.

Use `claude-isolated ls` to list your running sessions.

Use `claude-isolated stop` to stop / remove a running session.


## Development process

Pretty much all of this repo is written by Claude Code inside a sandboxed "yolo" environment.

README.md is written by a human. Promise!


## Feedback

Please open an issue or PR if you have trouble or if there's something you wish to improve!

