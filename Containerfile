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
