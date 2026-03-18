FROM debian:bookworm-slim

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    openssh-client \
    procps \
    python3 \
    python3-pip \
    tzdata \
    && ln -fs /usr/share/zoneinfo/Europe/Stockholm /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
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
    ncurses-term \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -d /home/claude -s /bin/bash claude
RUN mkdir -p /home/claude/.claude /workspace \
    && chown -R claude:claude /home/claude /workspace

USER claude

# Install uv
ARG UV_VERSION=0.10.11
RUN curl -LsSf https://astral.sh/uv/${UV_VERSION}/install.sh | sh

# Install Claude Code
ARG CLAUDE_VERSION=2.1.77
RUN curl -fsSL https://claude.ai/install.sh -o /tmp/install-claude.sh \
    && bash /tmp/install-claude.sh ${CLAUDE_VERSION} \
    && rm /tmp/install-claude.sh

# uv and claude on PATH
ENV PATH="/home/claude/bin:/home/claude/.local/bin:/home/claude/.claude/local/bin:$PATH"

# Use multiple colours(!)
ENV TERM=xterm-256color

WORKDIR /workspace

# Container scripts and config
RUN mkdir -p /home/claude/bin /home/claude/.config/zellij/layouts
COPY --chown=claude:claude container/start-claude /home/claude/bin/start-claude
COPY --chown=claude:claude container/start-zellij /home/claude/bin/start-zellij
COPY --chown=claude:claude container/zellij-config.kdl /home/claude/.config/zellij/config.kdl
COPY --chown=claude:claude container/layout.kdl /home/claude/.config/zellij/layouts/layout.kdl
RUN chmod +x /home/claude/bin/start-claude /home/claude/bin/start-zellij
