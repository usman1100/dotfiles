# Dotfiles

All my configs in one place. Each program still finds its config where it
expects it, because that path is a **link** to the file in this repo.
Edit either one: it is the same file.

## Set up a Mac

```sh
git clone git@github.com:usman1100/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
./install.sh
```

`install.sh` is safe to run again and again. If a real file is in the way, it
moves it to `~/.dotfiles-backup/<date>/` first. Nothing is deleted.

Then add the secrets (see below) and run `./install.sh status`.

## Check that everything is linked

```sh
./install.sh status
```

Some apps save their config by replacing the file. That breaks the link.
`status` finds this and shows a `diff` command. Copy over any changes you
want to keep, then run `./install.sh` again.

## Add a new config

1. Move the file (or folder) into this repo, in a folder named after the program.
2. Add one line to `LINKS` in `install.sh`: `"repo/path | $HOME/real/path"`.
3. Run `./install.sh`.

## What is where

| Program      | In this repo                | Linked to                                           |
| ------------ | --------------------------- | --------------------------------------------------- |
| zsh          | `zsh/`                      | `~/.zshrc`, `~/.zprofile`, `~/.zshenv`              |
| bash / sh    | `bash/`                     | `~/.bash_profile`, `~/.profile`                     |
| Git          | `git/`                      | `~/.gitconfig`, `~/.config/git/ignore`              |
| GitHub CLI   | `gh/config.yml`             | `~/.config/gh/config.yml`                           |
| SSH          | `ssh/config`                | `~/.ssh/config`                                     |
| Ghostty      | `ghostty/` (whole folder)   | `~/.config/ghostty`                                 |
| Zed          | `zed/` (whole folder)       | `~/.config/zed`                                     |
| Neovim       | `nvim/` (whole folder)      | `~/.config/nvim`                                    |
| VSCodium     | `vscodium/settings.json`    | `~/Library/Application Support/VSCodium/User/`      |
| htop         | `htop/` (whole folder)      | `~/.config/htop`                                    |
| opencode     | `opencode/`                 | `~/.config/opencode/opencode.json(c)`               |
| Codex        | `codex/rules/`              | `~/.codex/rules/default.rules`                      |
| Claude Code  | `claude/`                   | `~/.claude/CLAUDE.md`, `~/.claude/settings.json`    |

VSCodium extensions are listed in `vscodium/extensions.txt`; `install.sh`
installs any that are missing. Zed installs its theme on start
(`auto_install_extensions` in `zed/settings.json`).

## Secrets

**This repo is public.** Keys and tokens never go in it. They live in
`~/.secrets/` (only you can read it), and configs point to them:

| File                         | Used by                                            |
| ---------------------------- | -------------------------------------------------- |
| `~/.secrets/stitch-api-key`  | `opencode/opencode.json` via `{file:~/.secrets/stitch-api-key}` |
| `~/.secrets/env.zsh`         | optional; `zshrc` loads it for private env vars    |

## Not in this repo, on purpose

- Files with logins or tokens: `~/.npmrc`, `~/.config/gh/hosts.yml`,
  `~/.codex/auth.json`, `~/.config/acli`, gcloud, Copilot.
- `~/.claude-personal/settings.json`: holds private project details.
- `~/.codex/config.toml`: Codex rewrites it all the time, and it lists
  work project paths.
- App data and caches (Raycast, darktable, Joplin, FileZilla, Picard, QCAD, ART, …).
- VSCodium's hidden panels and buttons: saved in its own database, not in a file.
