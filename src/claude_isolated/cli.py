"""Run Claude Code in isolated containers (Podman or Docker)."""

import argparse
import contextlib
import itertools
import os
import shutil
import subprocess
import signal
import sys
import threading
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent / "data"
IMAGE = "claude-isolated:latest"


def runtime() -> str:
    for cmd in ("podman", "docker"):
        if shutil.which(cmd):
            return cmd
    print("Neither podman nor docker found in PATH", file=sys.stderr)
    sys.exit(1)


RUNTIME = runtime()


def generate_name() -> str:
    if shutil.which("random-name"):
        return f"claude-isolated-{subprocess.check_output(['random-name'], text=True).strip()}"
    else:
        return f"claude-isolated-{os.urandom(8).hex()}"


def path_for_isolated_home() -> Path:
    return Path(os.environ.get("CLAUDE_ISOLATED_HOME", Path.home() / ".config" / "claude-isolated" / "home"))


@contextlib.contextmanager
def spinner(message: str):
    done = threading.Event()
    failed = False

    def _spin():
        for char in itertools.cycle("⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"):
            if done.is_set():
                break
            print(f"\r{char} {message}", end="", flush=True)
            done.wait(0.08)
        symbol = "✘" if failed else "✔"
        print(f"\r{symbol} {message}")

    t = threading.Thread(target=_spin, daemon=True)
    t.start()
    try:
        yield
    except BaseException:
        failed = True
        raise
    finally:
        done.set()
        t.join()


class WorktreeInfo:
    """Result of worktree detection."""
    def __init__(self, bare_dir: Path | None = None, worktree_name: str = ""):
        self.bare_dir = bare_dir      # Host path to .bare/
        self.worktree_name = worktree_name  # Directory name of the worktree

    @property
    def is_worktree(self) -> bool:
        return self.bare_dir is not None


def detect_worktree(cwd: Path) -> WorktreeInfo:
    """Detect if cwd is a git worktree in a bare-clone layout.

    If cwd/.git is a file with a gitdir: pointer, walk up from the gitdir
    target to find the .bare/ directory.

    Returns WorktreeInfo with the host .bare/ path and the worktree name,
    so that we can mount:
      - cwd          -> /workspace/<name>
      - .bare/       -> /workspace/.bare
    This preserves the relative gitdir path (../.bare/worktrees/<name>).
    """
    dot_git = cwd / ".git"
    if not dot_git.is_file():
        return WorktreeInfo()

    text = dot_git.read_text().strip()
    if not text.startswith("gitdir:"):
        return WorktreeInfo()

    gitdir_raw = text.split("gitdir:", 1)[1].strip()
    gitdir = (cwd / gitdir_raw).resolve()

    # Walk up from gitdir to find a parent containing .bare/
    candidate = gitdir
    for _ in range(10):
        candidate = candidate.parent
        bare = candidate / ".bare"
        if bare.is_dir():
            return WorktreeInfo(bare_dir=bare, worktree_name=cwd.name)
        if candidate == candidate.parent:
            break

    return WorktreeInfo()


def cmd_init(args: argparse.Namespace) -> None:
    isolated_home = path_for_isolated_home()
    if isolated_home.exists():
        print(f"Already exists: {isolated_home}", file=sys.stderr)
        sys.exit(1)
    shutil.copytree(PROJECT_ROOT / "home.example", isolated_home)
    print(f"Created: {isolated_home}")
    print("Edit the files with your actual config.")


def cmd_build(args: argparse.Namespace, silent: bool = False) -> None:
    kwargs = {"stdout": subprocess.DEVNULL, "stderr": subprocess.DEVNULL} if silent else {}
    containerfile = str(PROJECT_ROOT / "Containerfile")
    subprocess.run([RUNTIME, "build", "-f", containerfile, "-t", IMAGE, str(PROJECT_ROOT)], check=True, **kwargs)
    if not silent:
        print(f"Image built: {IMAGE}")


def cmd_start(args: argparse.Namespace) -> None:
    cwd = Path(".").resolve()
    wt = detect_worktree(cwd)

    name = generate_name()
    isolated_home = path_for_isolated_home()

    if wt.is_worktree:
        workspace_mount = f"/workspace/{wt.worktree_name}"
    else:
        workspace_mount = "/workspace"

    volumes = [
        (cwd, workspace_mount, "rw"),
        (isolated_home / ".claude", "/home/claude/.claude", "rw"),
        (isolated_home / ".claude.json", "/home/claude/.claude.json", "rw"),
        (isolated_home / ".gitconfig", "/home/claude/.gitconfig", "ro"),
    ]

    if wt.is_worktree:
        volumes.append((wt.bare_dir, "/workspace/.bare", "rw"))

    if not isolated_home.exists():
        print(f"Config directory not found: {isolated_home}", file=sys.stderr)
        print(f"Run 'claude-isolated init' to create it.", file=sys.stderr)
        sys.exit(1)

    # TODO: consider re-adding per-file required checks

    run_args = [
        RUNTIME, "run", "-it",
        # keep-id maps the host user into the container so mounted volumes stay
        # writable. It is Podman-specific; Docker maps ownership differently.
        *(["--userns=keep-id"] if RUNTIME == "podman" else []),
        "--name", name,
        *[flag for src, dest, mode in volumes for flag in ("-v", f"{src}:{dest}:{mode}")],
    ]

    if wt.is_worktree:
        run_args += ["-w", workspace_mount]

    run_args += ["-e", f"CONTAINER_NAME={name}"]
    if args.prompt:
        run_args += ["-e", f"CLAUDE_PROMPT={args.prompt}"]
    run_args += [IMAGE, "start-claude"]

    signal.signal(signal.SIGHUP, lambda *_: sys.exit(1))
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(1))

    try:
        subprocess.run(run_args)
    finally:
        # Ensure the container gets stopped and removed on exit (including on Ctrl+C or SIGHUP, which happens when closing a terminal tab for example).
        subprocess.run([RUNTIME, "stop", "-t", "10", name],
                        capture_output=True)
        subprocess.run([RUNTIME, "rm", name],
                        capture_output=True)



def cmd_stop(args: argparse.Namespace) -> None:
    stop = subprocess.run([RUNTIME, "stop", "-t", "2", args.name], capture_output=True)
    if stop.returncode != 0:
        print(f"Failed to stop container: {args.name}", file=sys.stderr)
        sys.exit(1)
    rm = subprocess.run([RUNTIME, "rm", args.name], capture_output=True)
    if rm.returncode != 0:
        print(f"Stopped but failed to remove container: {args.name}", file=sys.stderr)
        sys.exit(1)
    print(f"Stopped and removed: {args.name}")


def cmd_ls(args: argparse.Namespace) -> None:
    subprocess.run([
        RUNTIME, "ps",
        "--filter", f"ancestor={IMAGE}",
        "--format", "table {{.Names}}\t{{.Status}}\t{{.Created}}",
    ], check=True)


SUBCOMMANDS = {"init", "build", "start", "stop", "ls"}


def main() -> None:
    # If first arg isn't a subcommand, treat as default: build + start [prompt]
    if not sys.argv[1:] or sys.argv[1] not in SUBCOMMANDS:
        prompt = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else ""
        with spinner("Building Containerfile.."):
            cmd_build(argparse.Namespace(), silent=True)
        print(f'\r✔ Running Claude Code in bypass permissions mode..')
        cmd_start(argparse.Namespace(prompt=prompt))
        return

    parser = argparse.ArgumentParser(description="Run Claude Code in isolated containers")
    sub = parser.add_subparsers(dest="command")

    sub.add_parser("init", help="Create config directory from template")

    sub.add_parser("build", help="Build the container image")

    p_start = sub.add_parser("start", help="Start a new container")
    p_start.add_argument("prompt", nargs="?", default="", help="Optional prompt for Claude")

    p_stop = sub.add_parser("stop", help="Stop and remove a container")
    p_stop.add_argument("name", help="Container name")

    sub.add_parser("ls", help="List running containers")

    args = parser.parse_args()

    commands = {
        "init": cmd_init,
        "build": cmd_build,
        "start": cmd_start,
        "stop": cmd_stop,
        "ls": cmd_ls,
    }
    commands[args.command](args)


if __name__ == "__main__":
    main()
