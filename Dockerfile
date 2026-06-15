FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    CODEX_HOME=/root/.codex \
    TERM=xterm-256color \
    PATH=/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        bash-completion \
        bubblewrap \
        build-essential \
        ca-certificates \
        curl \
        fd-find \
        git \
        gh \
        jq \
        less \
        nano \
        nodejs \
        npm \
        openssh-client \
        procps \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
        ripgrep \
        sudo \
        unzip \
        vim-tiny \
        zip \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/codex-home /root/.codex /workspace /root/.cache \
    && curl -fsSL https://chatgpt.com/codex/install.sh \
        | CODEX_NON_INTERACTIVE=1 CODEX_HOME=/opt/codex-home CODEX_INSTALL_DIR=/usr/local/bin sh \
    && codex --version

COPY docker/entrypoint.sh /usr/local/bin/container-entrypoint
RUN chmod +x /usr/local/bin/container-entrypoint

WORKDIR /workspace

VOLUME ["/workspace", "/root/.codex", "/root/.cache"]

ENTRYPOINT ["container-entrypoint"]
CMD ["codex"]
