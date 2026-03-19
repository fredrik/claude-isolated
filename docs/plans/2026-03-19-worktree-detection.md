# Worktree detection for container mounts

## Problem

When CWD is a git worktree (e.g. `project/feature-x/`), claude-isolated
mounts only that directory at `/workspace`. Git inside the container breaks
because it can't reach the bare repo (`.bare/`) which lives in the parent
directory.

## Prerequisite

The worktree must use relative paths in its `.git` file (e.g.
`gitdir: ../.bare/worktrees/feature-x` instead of an absolute path).
`git worktree add --relative-paths` does this natively. The
`git-clone-bare-worktree` script has been updated to use this flag.

## Proposed change

In the host-side launch script, before creating the container:

1. Check if CWD's `.git` is a file (not a directory) — this indicates a
   worktree.
2. Read the `gitdir:` pointer and walk up to find the project root (the
   directory containing `.bare/` or the real `.git/` directory).
3. Mount the **project root** at `/workspace` instead of CWD.
4. Set the container **workdir** to `/workspace/<relative-path-to-worktree>`.

## Example

```
# host
cd ~/code/project/feature-x
claude-isolated start

# detection logic
.git is a file → gitdir: ../.bare/worktrees/feature-x
project root: ~/code/project/
relative workdir: feature-x

# container mounts
-v ~/code/project:/workspace:rw
-w /workspace/feature-x
```

## Scope

- The container image does not change.
- Only the mount/workdir logic in `bin/claude-isolated` is affected.
- Non-worktree repos (normal `.git/` directory) behave exactly as before.
