#!/usr/bin/env bash
#
# Links every config in this repo to the place its program reads it from.
# Safe to run as often as you like.
#
#   ./install.sh          make all links (old files are moved to ~/.dotfiles-backup)
#   ./install.sh status   check all links, change nothing
#
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y-%m-%d-%H%M%S)"
VSCODIUM="$HOME/Library/Application Support/VSCodium/User"

# What goes where:   "path in this repo | path on this Mac"
# A folder entry links the whole folder.
LINKS=(
  # Shell
  "zsh/zshrc               | $HOME/.zshrc"
  "zsh/zprofile            | $HOME/.zprofile"
  "zsh/zshenv              | $HOME/.zshenv"
  "bash/bash_profile       | $HOME/.bash_profile"
  "bash/profile            | $HOME/.profile"

  # Git, GitHub, SSH
  "git/gitconfig           | $HOME/.gitconfig"
  "git/ignore              | $HOME/.config/git/ignore"
  "gh/config.yml           | $HOME/.config/gh/config.yml"
  "ssh/config              | $HOME/.ssh/config"

  # Terminal and editors
  "ghostty                 | $HOME/.config/ghostty"
  "zed                     | $HOME/.config/zed"
  "nvim                    | $HOME/.config/nvim"
  "vscodium/settings.json  | $VSCODIUM/settings.json"

  # Tools
  "htop                    | $HOME/.config/htop"
  "opencode/opencode.json  | $HOME/.config/opencode/opencode.json"
  "opencode/opencode.jsonc | $HOME/.config/opencode/opencode.jsonc"
  "codex/rules/default.rules | $HOME/.codex/rules/default.rules"
  "claude/CLAUDE.md        | $HOME/.claude/CLAUDE.md"
  "claude/settings.json    | $HOME/.claude/settings.json"
)

# Private files that configs need but that never go in git.
SECRETS=(
  "$HOME/.secrets/stitch-api-key | Stitch MCP key, used by opencode/opencode.json"
)

# ─── Output helpers ───────────────────────────────────────
if [ -t 1 ]; then
  GREEN=$'\033[32m' YELLOW=$'\033[33m' RED=$'\033[31m' DIM=$'\033[2m' OFF=$'\033[0m'
else
  GREEN="" YELLOW="" RED="" DIM="" OFF=""
fi
PROBLEMS=0
say()   { printf '  %b%-10s%b %s\n' "$1" "$2" "$OFF" "$3"; }
short() { printf '%s' "${1/#$HOME/~}"; }
trim()  { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; printf '%s' "${s%"${s##*[![:space:]]}"}"; }

# ─── Make one link ────────────────────────────────────────
link_one() {
  local src="$DOTFILES/$1" dst="$2"

  if [ ! -e "$src" ]; then
    say "$RED" "missing" "$1 is not in the repo"; PROBLEMS=$((PROBLEMS + 1)); return
  fi
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    say "$DIM" "ok" "$(short "$dst")"; return
  fi

  # Something else is there: keep a copy before replacing it.
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ -f "$dst" ] && [ ! -L "$dst" ] && cmp -s "$dst" "$src"; then
      rm "$dst"                       # same content as the repo, nothing to keep
    else
      local rel="${dst#"$HOME"/}"
      mkdir -p "$BACKUP/$(dirname "$rel")"
      mv "$dst" "$BACKUP/$rel"
      say "$YELLOW" "saved" "old $(short "$dst") -> $(short "$BACKUP/$rel")"
    fi
  fi

  mkdir -p "$(dirname "$dst")"
  case "$dst" in "$HOME/.ssh/"*) chmod 700 "$HOME/.ssh" ;; esac
  ln -s "$src" "$dst"
  say "$GREEN" "linked" "$(short "$dst")"
}

# ─── Check one link (changes nothing) ─────────────────────
check_one() {
  local src="$DOTFILES/$1" dst="$2"

  if [ ! -e "$src" ]; then
    say "$RED" "missing" "$1 is not in the repo"
  elif [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    say "$DIM" "ok" "$(short "$dst")"; return
  elif [ -L "$dst" ]; then
    say "$RED" "wrong" "$(short "$dst") points to $(readlink "$dst")"
  elif [ -e "$dst" ]; then
    if [ -f "$dst" ] && cmp -s "$dst" "$src"; then
      say "$YELLOW" "unlinked" "$(short "$dst") is a plain copy (same content)"
    else
      say "$RED" "unlinked" "$(short "$dst") is a real file or folder, not a link. An app may have replaced it."
      say "" "" "  compare: diff \"$dst\" \"$src\""
    fi
  else
    say "$RED" "missing" "$(short "$dst") does not exist"
  fi
  PROBLEMS=$((PROBLEMS + 1))
}

check_secrets() {
  local entry path what
  for entry in ${SECRETS[@]+"${SECRETS[@]}"}; do
    path="$(trim "${entry%%|*}")"; what="$(trim "${entry#*|}")"
    if [ -s "$path" ]; then
      say "$DIM" "ok" "$(short "$path")"
    else
      say "$RED" "missing" "$(short "$path")  ($what)"; PROBLEMS=$((PROBLEMS + 1))
    fi
  done
  [ -d "$HOME/.secrets" ] && chmod 700 "$HOME/.secrets"
  return 0
}

install_extensions() {
  local list="$DOTFILES/vscodium/extensions.txt" have ext
  command -v codium >/dev/null 2>&1 && [ -f "$list" ] || return 0
  have="$(codium --list-extensions 2>/dev/null || true)"
  while IFS= read -r ext || [ -n "$ext" ]; do
    ext="$(trim "$ext")"
    case "$ext" in ""|"#"*) continue ;; esac
    if printf '%s\n' "$have" | grep -qixF "$ext"; then
      say "$DIM" "ok" "$ext"
    elif codium --install-extension "$ext" >/dev/null 2>&1; then
      say "$GREEN" "installed" "$ext"
    else
      say "$RED" "failed" "$ext"; PROBLEMS=$((PROBLEMS + 1))
    fi
  done < "$list"
}

# ─── Main ────────────────────────────────────────────────
mode="${1:-install}"
case "$mode" in
  install|status) ;;
  *) echo "usage: $0 [status]"; exit 2 ;;
esac

echo "Configs"
for entry in "${LINKS[@]}"; do
  src="$(trim "${entry%%|*}")"; dst="$(trim "${entry#*|}")"
  if [ "$mode" = status ]; then check_one "$src" "$dst"; else link_one "$src" "$dst"; fi
done

echo "Secrets (kept outside git)"
check_secrets

if [ "$mode" = install ]; then
  echo "VSCodium extensions"
  install_extensions
fi

echo
if [ "$PROBLEMS" -eq 0 ]; then
  echo "${GREEN}All good.${OFF}"
else
  echo "${RED}$PROBLEMS problem(s).${OFF} Fix them, then run ./install.sh again."
  exit 1
fi
