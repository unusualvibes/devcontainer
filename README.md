# devcontainer

A development container configuration targeting [Coder](https://coder.com) with [envbuilder](https://github.com/coder/envbuilder). The `devcontainer.json` and `Dockerfile` are present for IDE compatibility, but the primary runtime is envbuilder — not Docker Desktop or the VS Code Dev Containers extension.

## What's inside

**Base:** Ubuntu Noble (24.04)

| Layer | Tools |
|---|---|
| Languages | Go 1.24.3, Rust (stable), Python 3, Node.js 22 |
| Go tools | `gopls`, `dlv`, `goimports`, `golangci-lint` |
| Rust tools | `clippy`, `rustfmt`, `rust-src`, `cargo-watch` |
| Python tools | `uv`, `ruff`, `black`, `mypy`, `pytest`, `ipython` |
| Node globals | `claude-code`, `codex` |
| Shell | zsh + [Starship](https://starship.rs) prompt, tmux + [tpm](https://github.com/tmux-plugins/tpm) |
| Extras | `vim`, `rsync`, `jq`, `openssh-client/server`, `iproute2` |

**VS Code / code-server extensions:** Claude Code, Go, Rust Analyzer, Python + Black + Pylint, Git Graph, GitLens, Code Spell Checker.

## envbuilder notes

Coder's envbuilder builds the image from this repo's `Dockerfile` at workspace-start time. A few things differ from a standard devcontainer setup:

- **VS Code customizations are applied manually.** envbuilder does not inject `customizations.vscode` into code-server's user-data directory, so `postStartCommand` runs `apply-vscode-customizations` to merge settings and install extensions on every start.
- **SSH host keys** are regenerated at start time by the same script (`ssh-keygen -A`).
- **No Docker socket is required.** envbuilder handles image building inside the Coder workspace.

## Environment variables

Set these in your host shell (or Coder template) before starting the workspace:

| Variable | Purpose |
|---|---|
| `ANTHROPIC_API_KEY` | Passed into the container for Claude Code |
| `OPENAI_API_KEY` | Passed into the container for Codex |

Telemetry and auto-updates for Claude Code are disabled by default (`CLAUDE_CODE_DISABLE_TELEMETRY=1`, `DISABLE_AUTOUPDATER=1`). Remove those lines from `devcontainer.json` if you want them enabled.

## Persistent storage

Claude Code auth and configuration are stored in a named Docker volume (`claude-code-config-<devcontainerId>`) mounted at `/home/coder/.claude`, so credentials survive container rebuilds.

## Build arguments

The `Dockerfile` exposes these `ARGs` if you need to pin different versions:

| ARG | Default |
|---|---|
| `UBUNTU_VERSION` | `noble` |
| `GO_VERSION` | `1.24.3` |
| `RUST_VERSION` | `stable` |
| `NODE_VERSION` | `22` |

## User-level installs

User tools (Rust toolchain, Go binaries, npm globals, Python tools, Starship, tmux plugins) are installed in parallel during the Docker build via [cgr](https://github.com/commandgraph/cgr), a dependency-aware command runner. The install graph lives in `.devcontainer/install.cgr`.
