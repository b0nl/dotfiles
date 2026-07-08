# Dotfiles

Personal dotfiles and machine bootstrap setup.

This repo is designed to make setting up a new Linux/Ubuntu machine fast, reproducible, and maintainable.

The setup uses a **bare Git repository** stored at:

```bash
~/.dotfiles
```

with the home directory as the work tree:

```bash
$HOME
```

This means the repo directly tracks files such as:

```text
~/.bashrc
~/.bashrc.base
~/.bashrc.work
~/.gitconfig
~/.config/dotfiles/...
~/bootstrap/...
```

without needing symlinks.

---

## Goals

This dotfiles setup aims to provide:

* reproducible shell configuration
* work/personal environment separation
* versioned Git configuration
* package installation manifests
* reusable bootstrap scripts
* VSCode configuration and extension reproducibility
* install helpers for tools such as `uv`, Docker, apt packages, and snap packages
* a clean daily workflow for managing dotfiles

This repo is not intended to clone every detail of a machine. It tracks deliberate configuration and install intent, not random machine state.

---

## Current target platform

The current bootstrap setup primarily targets:

```text
Ubuntu / Debian-like Linux systems
```

Some scripts may work on WSL or other Linux systems, but the apt, snap, and Docker installers are currently Ubuntu/Debian-oriented.

Cross-platform support may be added later.

---

## Repo architecture

Important files and directories:

```text
~/.dotfiles
    Bare Git repository metadata.

~/.bashrc
    Main Bash entrypoint.

~/.bashrc.base
    Shared shell config loaded across environments.

~/.bashrc.work
    Work-specific shell config.

~/.bashrc.personal
    Optional personal-specific shell config.

~/.bashrc.local
    Optional machine-local shell config. Should not be tracked.

~/.dotfiles-profile
    Local profile selector. Usually contains either "work" or "personal".
    Should not usually be tracked.

~/.config/dotfiles/shell/dotfiles.sh
    Dotfiles helper functions and aliases.

~/.config/dotfiles/packages/
    Package manifests for apt and snap.

~/bootstrap/
    Installer scripts for dotfiles, apt packages, snap packages, uv, Docker, etc.

~/.gitconfig
    Shared/default Git configuration.

~/.gitconfig.work
    Work-specific Git configuration.

~/.gitconfig.personal
    Optional personal-specific Git configuration.

~/.gitconfig.local
    Machine-local/private Git configuration. Should not be tracked.

~/.gitignore
    Ignore rules for the dotfiles repo itself.

~/.gitignore_global
    Global Git ignore rules used by all Git repos.
```

---

## Shell layering

The shell setup is layered.

The intended load chain is:

```text
~/.bashrc
  -> ~/.bashrc.base
      -> ~/.config/dotfiles/shell/dotfiles.sh
  -> profile-specific config
      -> ~/.bashrc.work or ~/.bashrc.personal
  -> ~/.bashrc.local
```

The base config contains shared behavior.

The work config contains work-specific aliases, paths, and environment variables.

The local config is for private or machine-specific values and should not be committed.

---

## Profiles

The current shell profile is controlled by:

```bash
~/.dotfiles-profile
```

Example:

```bash
echo work > ~/.dotfiles-profile
```

or:

```bash
echo personal > ~/.dotfiles-profile
```

Helper functions may also be available:

```bash
use-work
use-personal
```

These update the profile file and reload the shell config.

---

## Daily dotfiles command

The main helper is:

```bash
dotfiles
```

It is a function equivalent to:

```bash
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"
```

Common usage:

```bash
dotfiles status -sb
dotfiles add .bashrc.base
dotfiles commit -m "Update bash config"
dotfiles push
```

Depending on the shell helper aliases currently enabled, shorter aliases may also exist, such as:

```bash
dots='dotfiles status'
dotsb='dotfiles status -sb'
dotsd='dotfiles diff'
dotsdt='dotfiles difftool'
dotsn='dotfiles diff --name-only'
dotsstat='dotfiles diff --stat'
dotsa='dotfiles add'
dotsc='dotfiles commit'
dotsp='dotfiles push'
dotsl='dotfiles log --oneline --graph --decorate'
dotsu='dotfiles-audit'
dotsua='dotfiles-audit-all'
```

Avoid using `df` as a dotfiles alias because `df` is already a standard Unix command for disk usage.

---

## Dotfiles helper script

Dotfiles helper functions live in:

```bash
~/.config/dotfiles/shell/dotfiles.sh
```

This script provides helpers such as:

```bash
dotfiles
dotfiles-audit
dotfiles-audit-all
dotfiles-pick
dotfiles-ensure-config
dotfiles-commit
dotfiles-save-all
packages-save-current
packages-review
packages-edit
```

After editing this file, reload the shell:

```bash
source ~/.bashrc
```

Then commit changes:

```bash
dotfiles add .config/dotfiles/shell/dotfiles.sh
dotfiles commit -m "Update dotfiles helpers"
dotfiles push
```

---

## Untracked files and auditing

Normal dotfiles status hides untracked files:

```bash
dotfiles config --local status.showUntrackedFiles no
```

This keeps the home directory manageable.

To find possible new files worth tracking, use:

```bash
dotfiles-audit
```

This shows filtered untracked candidates while ignoring obvious cache/state directories.

To show everything untracked:

```bash
dotfiles-audit-all
```

Do not run:

```bash
dotfiles add .
```

or:

```bash
dotfiles add -A
```

from the home directory unless you know exactly what you are doing.

Use explicit adds:

```bash
dotfiles add .gitconfig
dotfiles add .config/Code/User/settings.json
dotfiles add bootstrap/install-uv.sh
```

---

## Fresh machine installation

On a new Ubuntu/Debian-like machine, first install Git:

```bash
sudo apt update
sudo apt install -y git
```

Clone the bare dotfiles repo:

```bash
git clone --bare git@github.com:b0nl/dotfiles.git ~/.dotfiles
```

Check out the files into `$HOME`:

```bash
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" checkout
```

If checkout fails because files already exist, move or back up the conflicting files, then retry.

After checkout, run the installer:

```bash
~/bootstrap/install.sh
```

Then reload the shell:

```bash
source ~/.bashrc
```

---

## Dotfiles installer

The dotfiles-specific installer is:

```bash
~/bootstrap/install-dotfiles.sh
```

It is responsible for:

* ensuring Git exists
* cloning the bare repo if needed
* checking out files into `$HOME`
* configuring local dotfiles Git behavior
* setting up VSCode difftool support if `code` exists
* creating a default profile if missing

This script is mainly intended for fresh-machine setup.

---

## Top-level installer

The top-level installer is:

```bash
~/bootstrap/install.sh
```

It calls the individual install scripts in order.

Typical structure:

```bash
~/bootstrap/install-dotfiles.sh
~/bootstrap/install-apt.sh
~/bootstrap/install-snap.sh
~/bootstrap/install-uv.sh
~/bootstrap/install-docker.sh
~/bootstrap/install-vscode.sh
```

Some of these scripts may be added, removed, or reordered as the setup evolves.

---

## Apt package manifests

Apt package manifests live in:

```text
~/.config/dotfiles/packages/apt-base.txt
~/.config/dotfiles/packages/apt-work.txt
~/.config/dotfiles/packages/apt-personal.txt
```

Meaning:

```text
apt-base.txt
    Packages wanted on all machines.

apt-work.txt
    Work-specific apt packages.

apt-personal.txt
    Personal-machine apt packages.
```

Install them with:

```bash
~/bootstrap/install-apt.sh
```

The active profile determines whether the work or personal package list is installed.

---

## Snap package manifests

Snap package manifests live in:

```text
~/.config/dotfiles/packages/snap-base.txt
~/.config/dotfiles/packages/snap-work.txt
~/.config/dotfiles/packages/snap-personal.txt
```

The format supports package names and flags:

```text
spotify
code --classic
```

Install them with:

```bash
~/bootstrap/install-snap.sh
```

---

## Updating package manifests

Generated package snapshots are for auditing only.

Useful helpers:

```bash
packages-save-current
packages-review
packages-edit
```

These may generate files such as:

```text
apt-manual-current.txt
apt-after-install-current.txt
snap-current.txt
```

These are machine snapshots and should generally not be committed.

Curated install manifests are the files that should be tracked:

```text
apt-base.txt
apt-work.txt
apt-personal.txt
snap-base.txt
snap-work.txt
snap-personal.txt
```

After editing package manifests:

```bash
dotfiles add .config/dotfiles/packages
dotfiles commit -m "Update package manifests"
dotfiles push
```

---

## Git configuration

Git config is layered.

Main config:

```bash
~/.gitconfig
```

Work config:

```bash
~/.gitconfig.work
```

Optional personal config:

```bash
~/.gitconfig.personal
```

Local private config:

```bash
~/.gitconfig.local
```

The main config can include work settings based on repo paths, for example:

```ini
[includeIf "gitdir:~/dev/work/"]
    path = ~/.gitconfig.work
```

This means repos under:

```bash
~/dev/work/
```

automatically use the work Git identity.

The local config should not be committed:

```bash
~/.gitconfig.local
```

Use it for machine-specific or private Git settings.

---

## Git ignore files

There are two ignore files with different jobs.

### `~/.gitignore`

This applies to the dotfiles repo itself because `$HOME` is the work tree.

Use it for home-directory-specific ignores:

```text
.dotfiles/
.dotfiles-profile
.bashrc.local
.gitconfig.local
.config/dotfiles/packages/*-current.txt
.cache/
.local/share/
.ssh/
.aws/
.gnupg/
```

### `~/.gitignore_global`

This applies to all Git repositories through:

```ini
[core]
    excludesfile = ~/.gitignore_global
```

Use it for generic junk such as:

```text
.DS_Store
*.swp
*.swo
__pycache__/
.pytest_cache/
.ruff_cache/
*.log
```

Do not globally ignore `.vscode/` by default if project-level VSCode configs may sometimes be committed.

---

## VSCode

Global VSCode user settings live here on Linux:

```text
~/.config/Code/User/settings.json
~/.config/Code/User/keybindings.json
~/.config/Code/User/snippets/
~/.config/Code/User/extensions.txt
```

Track these explicitly.

Do not track the whole:

```text
~/.config/Code/
```

because it contains caches, state, backups, and machine-specific data.

Save installed extensions:

```bash
code --list-extensions | sort > ~/.config/Code/User/extensions.txt
```

Install tracked extensions:

```bash
~/bootstrap/install-vscode.sh
```

or, if helper functions are available:

```bash
vscode-install-extensions
```

---

## VSCode difftool

The dotfiles repo can be configured to use VSCode as a visual difftool:

```bash
dotfiles difftool .bashrc.base
```

The local config for this is created by:

```bash
dotfiles-ensure-config
```

or by:

```bash
~/bootstrap/install-dotfiles.sh
```

This configuration is stored in the local bare Git repo config:

```text
~/.dotfiles/config
```

It is not itself tracked, so the installer/helper recreates it.

---

## uv

`uv` is installed with:

```bash
~/bootstrap/install-uv.sh
```

To update `uv` later:

```bash
uv self update
```

The install script intentionally only ensures `uv` exists. It does not force updates every time.

---

## Docker

Docker is installed with:

```bash
~/bootstrap/install-docker.sh
```

This script installs Docker from Docker’s official apt repository rather than relying on Ubuntu’s default `docker.io` package.

It also adds the current user to the `docker` group.

After running the installer, log out and log back in, or run:

```bash
newgrp docker
```

Then test:

```bash
docker run hello-world
```

On WSL or systems without systemd, Docker service startup may be skipped.

---

## Secrets and local-only files

Do not commit secrets.

Examples of files that should generally remain untracked:

```text
~/.bashrc.local
~/.bashrc.work.local
~/.bashrc.personal.local
~/.gitconfig.local
~/.dotfiles-profile
~/.ssh/
~/.aws/
~/.gnupg/
~/.kube/
```

Use tracked base config files that source untracked local files when needed.

---

## Typical workflow

Check tracked changes:

```bash
dotfiles status -sb
```

View diff:

```bash
dotfiles diff
```

Audit new untracked candidates:

```bash
dotfiles-audit
```

Add a file:

```bash
dotfiles add path/to/file
```

Commit:

```bash
dotfiles commit -m "Update config"
```

Push:

```bash
dotfiles push
```

---

## Tracking new config

When configuring a new tool, decide whether the file is:

```text
config       -> good candidate for dotfiles
cache/state  -> do not track
secret       -> do not track
project data -> do not track
```

Good candidates:

```text
~/.bashrc.base
~/.gitconfig
~/.gitignore_global
~/.config/Code/User/settings.json
~/.config/dotfiles/...
~/bootstrap/...
```

Bad candidates:

```text
~/.cache/
~/.local/share/
~/.ssh/id_*
~/.aws/credentials
~/.mozilla/
~/.npm/
~/.rustup/
~/.cargo/registry/
```

---

## Maintenance checklist

After making changes:

```bash
dotfiles status -sb
dotfiles diff
dotfiles add <changed-files>
dotfiles commit -m "Describe change"
dotfiles push
```

After installing new packages manually:

```bash
packages-review
```

Then update the curated package manifests if needed.

After changing VSCode extensions:

```bash
code --list-extensions | sort > ~/.config/Code/User/extensions.txt
dotfiles add .config/Code/User/extensions.txt
dotfiles commit -m "Update VSCode extensions"
dotfiles push
```

---

## Design philosophy

This repo tracks intent, not machine state.

The goal is not to preserve every file in `$HOME`.

The goal is to make a new machine quickly feel like the same development environment by versioning:

* shell behavior
* Git config
* editor config
* package manifests
* installer scripts
* reusable helper functions

Everything else should either be installed from a package manager, recreated from scripts, synced through app accounts, or left local.
