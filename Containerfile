FROM debian:bookworm-slim

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    openssh-client \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install zellij (detect architecture)
ARG TARGETARCH
RUN case "${TARGETARCH:-$(dpkg --print-architecture)}" in \
        amd64|x86_64) ZARCH="x86_64" ;; \
        arm64|aarch64) ZARCH="aarch64" ;; \
        *) echo "Unsupported arch: $TARGETARCH" >&2; exit 1 ;; \
    esac && \
    curl -LsSf "https://github.com/zellij-org/zellij/releases/latest/download/zellij-${ZARCH}-unknown-linux-musl.tar.gz" \
    | tar xz -C /usr/local/bin

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -d /home/claude -s /bin/bash claude
RUN mkdir -p /home/claude/.claude /home/claude/.ssh /workspace \
    && chown -R claude:claude /home/claude /workspace

USER claude
WORKDIR /workspace

# Zellij config and layout
RUN mkdir -p /home/claude/.config/zellij/layouts
COPY --chown=claude:claude config/layout.kdl /home/claude/.config/zellij/layouts/default.kdl
RUN printf 'default_shell "bash"\nshow_startup_tips false\nshow_release_notes false\n' > /home/claude/.config/zellij/config.kdl

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash

# uv and claude on PATH
ENV PATH="/home/claude/.local/bin:/home/claude/.claude/local/bin:$PATH"

