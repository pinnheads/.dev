# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

This is `pinnheads/.dev` — a personal dotfiles repository deployed with GNU Stow. Each top-level folder is a "stow package": its contents mirror the layout of `$HOME` and get symlinked into place. There is no build system, package manifest, or test suite; changes are verified by re-stowing and inspecting the resulting shell/editor/tmux behavior.

## Layout

Each directory matches what `stow` will symlink relative to `$HOME`:

- `zsh/` — `.zshrc`, `.zsh_profile`, `.bashrc`. `.zshrc` is Oh My Zsh based (theme `af-magic`, plugins `git zsh-autosuggestions`) and sources `~/.zsh_profile` at the end. `.zsh_profile` sets `XDG_CONFIG_HOME`, sources `arch/.config/personal/env` (path helper functions), sets `DEV_DOTFILES=$HOME/.dev`, prepends `~/.local/scripts` to `PATH`, and binds `Ctrl-f` to launch `tmux-sessionizer`.
- `arch/.config/personal/env` — shell helper functions (`addToPath`, `addToPathFront`) used by `.zsh_profile`. Kept separate so it can be sourced from multiple shells.
- `bin/.local/scripts/tmux-sessionizer` — fzf-driven tmux session picker; searches `~/personal` and `~/.config` for project directories and creates/attaches a tmux session named after the picked directory (dots replaced with underscores).
- `tmux/.tmux.conf` — prefix remapped to `C-a`, vim-style pane navigation (`h`/`j`/`k`/`l`), `r` reloads config.
- `nvim/.config/nvim/` — a kickstart.nvim-based config. `init.lua` requires `lua/globals.lua` (core `vim.o`/`vim.g` options) and `lua/keymaps.lua` first, then bootstraps `lazy.nvim` and declares plugins inline plus via `lua/plugins/*.lua` (gitsigns, lazygit, lint, neo-tree, mini.nvim, autopairs, indent_line, base16, debug/DAP). `nvim/.config/nvim/README.md` is upstream kickstart.nvim documentation, not repo-specific.
- `install` — top-level deploy script: for each folder in `$STOW_FOLDERS`, backs up any pre-existing real (non-symlink) target as `<path>.bak`, then runs `stow -D <folder>` followed by `stow <folder>` (unstow-then-restow, so it's safe to re-run).
- `stow` — entry point wrapper: defaults `STOW_FOLDERS="tmux,nvim,zsh,bin,arch"` and `DEV_DOTFILES=$HOME/.dev` if unset, then invokes `install` with those exported.

## Common commands

Deploy/re-deploy all dotfiles (from anywhere, run as the target user — not root):

```sh
$HOME/.dev/stow
```

Deploy only specific packages:

```sh
STOW_FOLDERS="nvim,zsh" $HOME/.dev/stow
```

There is no lint, build, or test tooling in this repo. When changing a script, "testing" means running it directly (e.g. `bash bin/.local/scripts/tmux-sessionizer`) or re-sourcing the relevant shell file (`source zsh/.zshrc`).

## Working conventions

- Keep new dotfiles under the stow package whose name matches the tool (e.g. a new `foo` config's stowed path should be `foo/.config/foo/...`), so it deploys via the existing `stow`/`install` flow without changes to those scripts.
- `install` and `stow` are zsh scripts (`#!/usr/bin/env zsh`) — match that shebang/style for sibling deploy scripts.
- The `.bak` backup behavior in `install` is what protects a user's pre-existing real config files from being clobbered by `stow -D`/`stow`; don't remove it when editing that script.
