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

# Install zellij
RUN curl -LsSf https://github.com/zellij-org/zellij/releases/latest/download/zellij-aarch64-unknown-linux-musl.tar.gz \
    | tar xz -C /usr/local/bin

# Create non-root user
RUN useradd -m -d /home/claude -s /bin/bash claude
RUN mkdir -p /home/claude/.claude /home/claude/.ssh /workspace \
    && chown -R claude:claude /home/claude /workspace

USER claude
WORKDIR /workspace

# Zellij config and layout
RUN mkdir -p /home/claude/.config/zellij/layouts
COPY --chown=claude:claude config/layout.kdl /home/claude/.config/zellij/layouts/default.kdl
RUN printf 'show_startup_tips false\nshow_release_notes false\n' > /home/claude/.config/zellij/config.kdl

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash

# uv and claude on PATH
ENV PATH="/home/claude/.local/bin:/home/claude/.claude/local/bin:$PATH"

# Keep container alive; zellij is started on attach
ENV CLAUDE_ISOLATED_NAME="unnamed"
CMD ["sleep", "infinity"]
