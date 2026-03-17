# claude-isolated Implementation Plan

> **Status:** Done. All 10 tasks implemented. Implementation diverged from plan in several places (Debian over Alpine, `claude` user, `claude.ai` installer, configurable home dir, dispatcher script, `--dangerously-skip-permissions`, auto-remove containers, gh CLI). See git log for details.

**Goal:** A set of scripts and a container image that run Claude Code inside a Podman container with full OS isolation, mounted project directory, and read-only auth/config.

**Architecture:** Alpine-based Podman container with Python/uv, git, Claude Code, and Zellij. Shell scripts manage lifecycle (build, start, enter, stop, ls). Container names use two random words (like Zellij). Auth, SSH keys, git config, and skills are mounted read-only from host. Project dir mounted read-write at /workspace.

**Tech Stack:** Podman, Alpine Linux, shell scripts (bash), Zellij, Claude Code (npm), Python/uv

---

## Project Structure

```
~/code/fredrik/claude-isolated/
├── Containerfile              # Alpine image definition
├── scripts/
│   ├── claude-isolated-build  # Build the container image
│   ├── claude-isolated-start  # Start a new container
│   ├── claude-isolated-enter  # Attach to running container
│   ├── claude-isolated-stop   # Stop and remove container
│   └── claude-isolated-ls     # List running instances
├── config/
│   └── wordlist.txt           # Word pairs for random naming
└── README.md
```

## Container Mounts

| Host (read-only) | Container | Purpose |
|---|---|---|
| `~/.claude.json` | `/home/dev/.claude.json` | Team auth token |
| `~/.claude/settings.json` | `/home/dev/.claude/settings.json` | Claude config |
| `~/.claude/plugins/` | `/home/dev/.claude/plugins/` | Skills & agents |
| `~/.claude/CLAUDE.md` | `/home/dev/.claude/CLAUDE.md` | Global instructions |
| `~/.claude-isolated/ssh/` | `/home/dev/.ssh/` | SSH keys for Claude |
| `~/.claude-isolated/gitconfig` | `/home/dev/.gitconfig` | Git config |

| Host (read-write) | Container | Purpose |
|---|---|---|
| `<project-dir>` | `/workspace` | Working directory |

---

### Task 1: Initialize project repository

**Files:**
- Create: `~/code/fredrik/claude-isolated/` (git init)

**Step 1: Create project directory and initialize git**

```bash
mkdir -p ~/code/fredrik/claude-isolated/{scripts,config}
cd ~/code/fredrik/claude-isolated
git init
```

**Step 2: Create .gitignore**

```
.DS_Store
```

**Step 3: Commit**

```bash
git add -A
git commit -m "Init claude-isolated project"
```

---

### Task 2: Create the wordlist for random naming

**Files:**
- Create: `config/wordlist.txt`

**Step 1: Create wordlist**

A flat file with ~100 short, memorable adjectives and nouns. The naming script picks one adjective + one noun at random.

```
# Adjectives (lines 1-50)
bright
calm
cold
cool
dark
deep
dry
fair
fast
...
# Nouns (lines 51-100)
ant
bat
bear
bird
cat
crow
deer
dove
...
```

Use two separate sections (adjectives, nouns) separated by a blank line, ~50 each.

**Step 2: Commit**

```bash
git add config/wordlist.txt
git commit -m "Add wordlist for random container naming"
```

---

### Task 3: Write the Containerfile

**Files:**
- Create: `Containerfile`

**Step 1: Write the Containerfile**

```dockerfile
FROM alpine:3.21

# System deps
RUN apk add --no-cache \
    bash \
    curl \
    git \
    openssh-client \
    nodejs \
    npm \
    python3 \
    py3-pip \
    zellij

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Create non-root user
RUN adduser -D -h /home/dev -s /bin/bash dev
RUN mkdir -p /home/dev/.claude /home/dev/.ssh /workspace \
    && chown -R dev:dev /home/dev /workspace

USER dev
WORKDIR /workspace

# uv on PATH
ENV PATH="/home/dev/.local/bin:$PATH"

# Entrypoint: zellij with session name passed via env
ENV CLAUDE_ISOLATED_NAME="unnamed"
ENTRYPOINT ["bash", "-c", "zellij --session \"$CLAUDE_ISOLATED_NAME\""]
```

**Step 2: Commit**

```bash
git add Containerfile
git commit -m "Add Alpine-based Containerfile

Python/uv, git, Claude Code, Zellij. Non-root user.
Zellij session name set via CLAUDE_ISOLATED_NAME env var."
```

---

### Task 4: Write claude-isolated-build

**Files:**
- Create: `scripts/claude-isolated-build`

**Step 1: Write the build script**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

podman build -t claude-isolated:latest "$PROJECT_ROOT"
echo "Image built: claude-isolated:latest"
```

**Step 2: Make executable and commit**

```bash
chmod +x scripts/claude-isolated-build
git add scripts/claude-isolated-build
git commit -m "Add claude-isolated-build script"
```

---

### Task 5: Write claude-isolated-start

**Files:**
- Create: `scripts/claude-isolated-start`

**Step 1: Write the start script**

This is the most complex script. It:
- Generates a two-random-word name from wordlist.txt
- Validates the project dir argument
- Sets up all mounts
- Starts the container with Zellij

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WORDLIST="$PROJECT_ROOT/config/wordlist.txt"

# --- Args ---
PROJECT_DIR="${1:?Usage: claude-isolated-start <project-dir>}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"  # resolve to absolute

# --- Generate name ---
ADJECTIVES=()
NOUNS=()
section="adj"
while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && { section="noun"; continue; }
    if [[ "$section" == "adj" ]]; then
        ADJECTIVES+=("$line")
    else
        NOUNS+=("$line")
    fi
done < "$WORDLIST"

ADJ="${ADJECTIVES[$((RANDOM % ${#ADJECTIVES[@]}))]}"
NOUN="${NOUNS[$((RANDOM % ${#NOUNS[@]}))]}"
NAME="claude-isolated-${ADJ}-${NOUN}"

# --- Host paths ---
CLAUDE_JSON="$HOME/.claude.json"
CLAUDE_DIR="$HOME/.claude"
ISOLATED_DIR="$HOME/.claude-isolated"

# --- Validate required files ---
for f in "$CLAUDE_JSON" "$CLAUDE_DIR/settings.json" "$ISOLATED_DIR/ssh" "$ISOLATED_DIR/gitconfig"; do
    if [[ ! -e "$f" ]]; then
        echo "Missing: $f" >&2
        exit 1
    fi
done

# --- Start container ---
podman run -d \
    --name "$NAME" \
    -e "CLAUDE_ISOLATED_NAME=$NAME" \
    -v "$PROJECT_DIR:/workspace:rw" \
    -v "$CLAUDE_JSON:/home/dev/.claude.json:ro" \
    -v "$CLAUDE_DIR/settings.json:/home/dev/.claude/settings.json:ro" \
    -v "$CLAUDE_DIR/plugins:/home/dev/.claude/plugins:ro" \
    -v "$CLAUDE_DIR/CLAUDE.md:/home/dev/.claude/CLAUDE.md:ro" \
    -v "$ISOLATED_DIR/ssh:/home/dev/.ssh:ro" \
    -v "$ISOLATED_DIR/gitconfig:/home/dev/.gitconfig:ro" \
    -it \
    claude-isolated:latest

echo "Started: $NAME"
echo "Enter:   claude-isolated-enter $NAME"
```

**Step 2: Make executable and commit**

```bash
chmod +x scripts/claude-isolated-start
git add scripts/claude-isolated-start
git commit -m "Add claude-isolated-start script

Generates two-random-word name, mounts project dir r/w,
auth and config r/o, starts container with Zellij."
```

---

### Task 6: Write claude-isolated-enter

**Files:**
- Create: `scripts/claude-isolated-enter`

**Step 1: Write the enter script**

```bash
#!/usr/bin/env bash
set -euo pipefail

NAME="${1:?Usage: claude-isolated-enter <name>}"

# Attach to the running container's Zellij session
podman exec -it "$NAME" zellij attach "$NAME"
```

**Step 2: Make executable and commit**

```bash
chmod +x scripts/claude-isolated-enter
git add scripts/claude-isolated-enter
git commit -m "Add claude-isolated-enter script"
```

---

### Task 7: Write claude-isolated-stop

**Files:**
- Create: `scripts/claude-isolated-stop`

**Step 1: Write the stop script**

```bash
#!/usr/bin/env bash
set -euo pipefail

NAME="${1:?Usage: claude-isolated-stop <name>}"

podman stop "$NAME" 2>/dev/null && podman rm "$NAME" 2>/dev/null
echo "Stopped and removed: $NAME"
```

**Step 2: Make executable and commit**

```bash
chmod +x scripts/claude-isolated-stop
git add scripts/claude-isolated-stop
git commit -m "Add claude-isolated-stop script"
```

---

### Task 8: Write claude-isolated-ls

**Files:**
- Create: `scripts/claude-isolated-ls`

**Step 1: Write the ls script**

```bash
#!/usr/bin/env bash
set -euo pipefail

podman ps --filter "ancestor=claude-isolated:latest" \
    --format "table {{.Names}}\t{{.Status}}\t{{.Created}}"
```

**Step 2: Make executable and commit**

```bash
chmod +x scripts/claude-isolated-ls
git add scripts/claude-isolated-ls
git commit -m "Add claude-isolated-ls script"
```

---

### Task 9: Test the full lifecycle

**Step 1: Build the image**

```bash
./scripts/claude-isolated-build
```

Expected: image builds successfully.

**Step 2: Start a container with a test project**

```bash
mkdir -p /tmp/test-project
./scripts/claude-isolated-start /tmp/test-project
```

Expected: prints name like `claude-isolated-bright-falcon`.

**Step 3: List running containers**

```bash
./scripts/claude-isolated-ls
```

Expected: shows the running container.

**Step 4: Enter the container**

```bash
./scripts/claude-isolated-enter claude-isolated-bright-falcon
```

Expected: drops into Zellij session. Verify:
- `pwd` shows `/workspace`
- `ls /workspace` shows test project contents
- `python3 --version` works
- `uv --version` works
- `claude --version` works
- `ls ~/.claude/plugins` shows skills
- `cat ~/.gitconfig` shows git config

**Step 5: Stop the container**

```bash
./scripts/claude-isolated-stop claude-isolated-bright-falcon
```

Expected: container stopped and removed.

---

### Task 10: Write README

**Files:**
- Create: `README.md`

Brief README covering:
- What this is
- Prerequisites (podman)
- Setup (`~/.claude-isolated/ssh/`, `~/.claude-isolated/gitconfig`)
- Usage (build, start, enter, stop, ls)

**Commit:**

```bash
git add README.md
git commit -m "Add README"
```
