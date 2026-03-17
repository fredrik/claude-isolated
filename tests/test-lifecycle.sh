#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CLI="$PROJECT_ROOT/scripts/claude-isolated"
CONTAINER_NAME=""
TEST_DIR=""

# macOS doesn't have timeout; use perl as fallback
if ! command -v timeout &>/dev/null; then
    timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }
fi

cleanup() {
    [[ -n "$CONTAINER_NAME" ]] && podman rm -f "$CONTAINER_NAME" 2>/dev/null
    [[ -n "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Setup
TEST_DIR="$(mktemp -d "$HOME/tmp/claude-isolated-test.XXXXX")"

# Build
echo "--- Building image ---"
"$CLI" build

# Start — capture the name from output
echo "--- Starting container ---"
OUTPUT=$("$CLI" start "$TEST_DIR")
CONTAINER_NAME=$(echo "$OUTPUT" | grep '^Started:' | awk '{print $2}')
echo "Container: $CONTAINER_NAME"

# Verify tools (timeout each command to catch hangs)
echo "--- Verifying tools ---"
timeout 10 podman exec "$CONTAINER_NAME" python3 --version
timeout 10 podman exec "$CONTAINER_NAME" uv --version
timeout 10 podman exec "$CONTAINER_NAME" claude --version 2>&1 || echo "WARN: claude --version failed (may need auth)"
timeout 10 podman exec "$CONTAINER_NAME" git --version
timeout 10 podman exec "$CONTAINER_NAME" zellij --version

# Verify working directory
echo "--- Verifying workspace ---"
timeout 10 podman exec "$CONTAINER_NAME" bash -c '[[ "$(pwd)" == "/workspace" ]]'

# Verify ls script shows the container
echo "--- Verifying ls ---"
"$CLI" ls | grep -q "$CONTAINER_NAME"

# Stop
echo "--- Stopping container ---"
"$CLI" stop "$CONTAINER_NAME"
CONTAINER_NAME=""  # prevent double-cleanup

echo "All tests passed."
