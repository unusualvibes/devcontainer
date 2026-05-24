ARG UBUNTU_VERSION=noble

FROM ubuntu:${UBUNTU_VERSION}

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

ARG GO_VERSION=1.24.3
ARG RUST_VERSION=stable
ARG NODE_VERSION=22

# ── System utilities ──────────────────────────────────────────────────────────
RUN apt-get update && apt-get upgrade --yes --no-install-recommends --no-install-suggests && \
    apt-get install --yes --no-install-recommends --no-install-suggests \
    vim tmux zsh build-essential pkg-config libssl-dev \
    curl wget git ca-certificates unzip jq locales sudo \
    openssh-client openssh-server iproute2 iputils-ping traceroute \
    python3 python3-venv python3-pip pipx rsync shellcheck \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ── Node ──────────────────────────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - \
    && apt-get install --yes --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── Go ────────────────────────────────────────────────────────────────────────
RUN curl -fsSL "https://go.dev/dl/go$GO_VERSION.linux-$(dpkg --print-architecture).tar.gz" \
    | tar -C /usr/local -xz

# ── cgr ───────────────────────────────────────────────────────────────────────
RUN curl -fsSL https://raw.githubusercontent.com/commandgraph/cgr/main/cgr.py \
    -o /usr/local/bin/cgr && chmod +x /usr/local/bin/cgr

# ── coder user (UID 1000) with passwordless sudo ──────────────────────────────
# ubuntu:noble ships an 'ubuntu' user at UID 1000 — remove it first
RUN userdel -r ubuntu && \
    useradd coder --create-home --shell=/bin/bash --uid=1000 --user-group && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

RUN mkdir -p /workspaces && chown coder:coder /workspaces

COPY tmux.conf /etc/tmux.conf
COPY apply-vscode-customizations.sh /usr/local/bin/apply-vscode-customizations
RUN chmod +x /usr/local/bin/apply-vscode-customizations

# ── User-level installs (Rust, Go tools, npm globals, Python tools) ───────────
USER coder

ENV GOPATH="/home/coder/go"
ENV PATH="/usr/local/go/bin:${GOPATH}/bin:/home/coder/.cargo/bin:/home/coder/.npm-global/bin:/home/coder/.local/bin:${PATH}"

RUN npm config set prefix ~/.npm-global

COPY --chown=coder:coder install.cgr /tmp/install.cgr
RUN cgr apply -v --no-state /tmp/install.cgr

RUN mkdir -p ~/.config
COPY --chown=coder:coder starship.toml /home/coder/.config/starship.toml

RUN echo 'export PATH="/usr/local/go/bin:$GOPATH/bin:$HOME/.cargo/bin:$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"' >> ~/.zshrc \
    && echo 'eval "$(starship init zsh)"' >> ~/.zshrc \
    && echo 'export PATH="/usr/local/go/bin:$GOPATH/bin:$HOME/.cargo/bin:$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"' >> ~/.bashrc \
    && echo 'eval "$(starship init bash)"' >> ~/.bashrc
