#!/usr/bin/env bash
set -u

log() {
  printf '[vscode-customizations] %s\n' "$*" >&2
}

settings='{
  "workbench.colorTheme": "Dark 2026",
  "telemetry.telemetryLevel": "off",
  "terminal.integrated.defaultProfile.linux": "zsh",
  "editor.formatOnSave": true,
  "go.toolsManagement.autoUpdate": true,
  "rust-analyzer.check.command": "clippy",
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter"
  }
}'

merge_settings() {
  local target=$1
  local dir
  local tmp

  dir=$(dirname "$target")
  mkdir -p "$dir" || return 1

  if [ ! -s "$target" ]; then
    printf '{}\n' > "$target" || return 1
  fi

  tmp=$(mktemp)
  if jq -s '.[0] * .[1]' "$target" <(printf '%s\n' "$settings") > "$tmp"; then
    mv "$tmp" "$target"
    log "merged settings into $target"
  else
    rm -f "$tmp"
    log "failed to merge settings into $target"
    return 1
  fi
}

find_code_server() {
  if command -v code-server >/dev/null 2>&1; then
    command -v code-server
    return 0
  fi

  local candidate
  for candidate in /tmp/code-server/lib/code-server-*/bin/code-server; do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

install_code_server_extensions() {
  local code_server=$1
  shift

  local extension
  for extension in "$@"; do
    if "$code_server" --install-extension "$extension" --force >/dev/null 2>&1; then
      log "installed extension $extension"
    else
      log "could not install extension $extension"
    fi
  done
}

sudo ssh-keygen -A 2>/dev/null || true

merge_settings "$HOME/.local/share/code-server/User/settings.json"
merge_settings "$HOME/.vscode-server/data/Machine/settings.json"
merge_settings "$HOME/.vscode-server-insiders/data/Machine/settings.json"

extensions=(
  anthropic.claude-code
  golang.go
  rust-lang.rust-analyzer
  ms-python.python
  ms-python.black-formatter
  ms-python.pylint
  mhutchie.git-graph
  eamodio.gitlens
  streetsidesoftware.code-spell-checker
)

if code_server=$(find_code_server); then
  install_code_server_extensions "$code_server" "${extensions[@]}"
else
  log "code-server CLI not found; skipped code-server extension install"
fi

