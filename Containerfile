FROM alpine:3.21

# System deps
RUN apk add --no-cache \
    bash \
    curl \
    git \
    openssh-client \
    python3 \
    py3-pip \
    zellij

# Create non-root user
RUN adduser -D -h /home/claude -s /bin/bash claude
RUN mkdir -p /home/claude/.claude /home/claude/.ssh /workspace \
    && chown -R claude:claude /home/claude /workspace

USER claude
WORKDIR /workspace

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash

# uv and claude on PATH
ENV PATH="/home/claude/.local/bin:/home/claude/.claude/local/bin:$PATH"

# Entrypoint: zellij with session name passed via env
ENV CLAUDE_ISOLATED_NAME="unnamed"
ENTRYPOINT ["bash", "-c", "zellij --session \"$CLAUDE_ISOLATED_NAME\""]
