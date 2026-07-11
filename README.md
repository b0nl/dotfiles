# Dotfiles

Personal dotfiles and machine bootstrap setup.

This repository is designed to make a fresh Ubuntu/Debian-like development machine feel familiar quickly. It tracks shell configuration, Git configuration, package manifests, VSCode configuration, GNOME settings, bootstrap scripts, and helper functions.

The setup uses a **bare Git repository** stored at:

```bash
~/.dotfiles
```

with the home directory as the work tree:

```bash
$HOME
```

That means the repo directly tracks files in `$HOME`, such as:

```text
~/.bashrc
~/.bashrc.work
~/.gitconfig
~/.gitignore
~/.gitignore_global
~/.tmux.conf
~/.config/Code/User/settings.json
~/.config/dotfiles/...
~/bootstrap/...
```

No symlink manager is used.

---

## Goals

This setup aims to provide:

* reproducible shell configuration
* reproducible Git configuration
* package manifests for apt and snap
* bootstrap scripts for system setup
* VSCode settings, keybindings, and extensions
* GNOME/dconf settings export and restore
* helper commands for day-to-day dotfiles management
* a health check for validating the local setup
* a safer Git workflow for a home-directory dotfiles repo

This repo tracks **intentional configuration**, not the entire state of a machine.

Do not treat this as a full home-directory backup.

---

## Target platform

The current bootstrap setup mainly targets:

```text
Ubuntu / Debian-like Linux systems
```

Some parts may work on WSL or other Linux distributions, but the apt, snap, Docker, and GNOME scripts are Ubuntu/Debian-oriented.

This repo does not currently aim to support macOS, Fedora, Arch, or Windows directly.

---

## Important warning

Because this repo uses `$HOME` as the Git work tree, commands such as this are dangerous:

```bash
dotfiles add .
dotfiles add -A
```

From your home directory, those commands mean:

```text
Add everything under $HOME that is not ignored.
```

That can accidentally stage secrets, VPN configs, app state, browser files, SSH metadata, or other private files.

Prefer explicit adds:

```bash
dotfiles add .gitconfig
dotfiles add .config/Code/User/settings.json
dotfiles add bootstrap/install-uv.sh
```

For already-tracked files, this is safer:

```bash
dotfiles add -u
```

That stages modifications/deletions to tracked files only. It does not add new untracked files.

---

## Repository layout

Main structure:

```text
.
├── .bash_aliases
├── .bash_logout
├── .bashrc
├── .bashrc.work
├── .gitconfig
├── .gitignore
├── .gitignore_global
├── .profile
├── .tmux.conf
├── README.md
├── bootstrap/
│   ├── install.sh
│   ├── install-dotfiles.sh
│   ├── install-apt.sh
│   ├── install-snap.sh
│   ├── install-uv.sh
│   ├── install-docker.sh
│   ├── install-vscode.sh
│   └── install-gnome.sh
└── .config/
    ├── Code/
    │   └── User/
    │       ├── extensions.txt
    │       ├── keybindings.json
    │       └── settings.json
    └── dotfiles/
        ├── git-hooks/
        │   └── pre-commit
        ├── gnome/
        │   ├── save.sh
        │   ├── apply.sh
        │   └── configs/
        │       ├── profiles.dconf
        │       ├── desktop-interface.dconf
        │       ├── wm-keybindings.dconf
        │       └── media-keys.dconf
        ├── packages/
        │   ├── apt-base.txt
        │   ├── apt-work.txt
        │   ├── apt-personal.txt
        │   ├── snap-base.txt
        │   ├── snap-work.txt
        │   └── snap-personal.txt
        └── shell/
            ├── dotfiles.sh
            ├── vscode.sh
            └── health.sh
```

---

## Fresh machine install

### 1. Install minimum prerequisites

On a fresh Ubuntu/Debian-like machine:

```bash
sudo apt update
sudo apt install -y git curl
```

If using the SSH remote, make sure the machine has a GitHub SSH key configured before cloning:

```bash
ssh -T git@github.com
```

The repo remote currently assumes:

```text
git@github.com:b0nl/dotfiles.git
```

If SSH is not set up yet, either configure SSH first or temporarily clone with HTTPS.

---

### 2. Clone the bare repo

```bash
git clone --bare git@github.com:b0nl/dotfiles.git "$HOME/.dotfiles"
```

---

### 3. Check out the work tree

```bash
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" checkout
```

If checkout fails because existing files would be overwritten, back them up first. For example:

```bash
mkdir -p "$HOME/.dotfiles-backup"

mv "$HOME/.bashrc" "$HOME/.dotfiles-backup/.bashrc" 2>/dev/null || true
mv "$HOME/.gitconfig" "$HOME/.dotfiles-backup/.gitconfig" 2>/dev/null || true
```

Then retry:

```bash
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" checkout
```

---

### 4. Run the main bootstrap

After checkout:

```bash
~/bootstrap/install.sh
```

The top-level installer runs the individual installers in order:

```bash
~/bootstrap/install-dotfiles.sh
~/bootstrap/install-apt.sh
~/bootstrap/install-snap.sh
~/bootstrap/install-uv.sh
~/bootstrap/install-docker.sh
~/bootstrap/install-vscode.sh
~/bootstrap/install-gnome.sh
```

---

### 5. Reload the shell

```bash
source ~/.bashrc
```

Then check the installation:

```bash
dotfiles-health
dotfiles status -sb
```

---

## The `dotfiles` command

The main helper function is:

```bash
dotfiles
```

It is defined in:

```text
~/.config/dotfiles/shell/dotfiles.sh
```

It is equivalent to:

```bash
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"
```

Common commands:

```bash
dotfiles status -sb
dotfiles diff
dotfiles add .gitconfig
dotfiles commit -m "Update git config"
dotfiles push
```

Aliases may also be available:

```bash
dots       # dotfiles status
dotsb      # dotfiles status -sb
dotsd      # dotfiles diff
dotsdt     # dotfiles difftool
dotsn      # dotfiles diff --name-only
dotsstat   # dotfiles diff --stat
dotsa      # dotfiles add
dotsc      # dotfiles commit
dotsp      # dotfiles push
dotsl      # dotfiles log --oneline --graph --decorate
dotsu      # dotfiles-audit
dotsua     # dotfiles-audit-all
```

The alias `df` is intentionally avoided because `df` is already a standard Unix command.

---

## Shell setup

The main Bash entrypoint is:

```text
~/.bashrc
```

It handles normal Bash setup and then sources dotfiles-specific helper scripts.

Important sourced helper files:

```text
~/.config/dotfiles/shell/dotfiles.sh
~/.config/dotfiles/shell/vscode.sh
~/.config/dotfiles/shell/health.sh
```

The current profile is controlled by:

```text
~/.dotfiles-profile
```

Example:

```bash
echo work > ~/.dotfiles-profile
source ~/.bashrc
```

The current tracked profile-specific config is:

```text
~/.bashrc.work
```

At the moment, the work profile loads `.bashrc.work`. Other profile values can be added later if needed.

---

## Local-only shell config

For secrets or machine-specific shell settings, do not commit them directly.

Use local files such as:

```text
~/.bashrc.local
~/.bashrc.work.local
~/.gitconfig.local
```

These should stay untracked.

Examples of things that belong in local-only files:

```bash
export SOME_PRIVATE_TOKEN="..."
export AWS_PROFILE="..."
export PRIVATE_API_BASE_URL="..."
```

Do not commit tokens, certificates, credentials, private hostnames, or VPN configs.

---

## Dotfiles helper script

Path:

```text
~/.config/dotfiles/shell/dotfiles.sh
```

Provides:

```text
dotfiles
dotfiles aliases
dotfiles-ensure-config
dotfiles-audit
dotfiles-audit-all
dotfiles-pick
```

### `dotfiles-ensure-config`

Configures local Git settings for the bare dotfiles repo:

```bash
dotfiles config --local status.showUntrackedFiles no
dotfiles config --local core.hooksPath "$HOME/.config/dotfiles/git-hooks"
```

If the VSCode CLI exists, it also configures VSCode as the Git difftool.

Run manually if needed:

```bash
dotfiles-ensure-config
```

### `dotfiles-audit`

Shows filtered untracked candidates that might be worth tracking:

```bash
dotfiles-audit
```

This hides obvious noise such as caches, browser data, large app state, and project directories.

### `dotfiles-audit-all`

Shows all untracked files:

```bash
dotfiles-audit-all
```

This can be very noisy because `$HOME` is the work tree.

### `dotfiles-pick`

Uses `fzf` to interactively select untracked files from the audit list and add them:

```bash
dotfiles-pick
```

Requires:

```bash
fzf
```

---

## Git config

Tracked Git files:

```text
~/.gitconfig
~/.gitignore
~/.gitignore_global
```

Optional/local-only:

```text
~/.gitconfig.local
```

### `.gitconfig`

Contains shared Git settings such as:

```ini
[core]
    editor = code --wait
    excludesfile = ~/.gitignore_global
    autocrlf = input
```

Meaning:

```text
editor = code --wait
    Use VSCode for Git commit/rebase messages and wait for the editor to close.

excludesfile = ~/.gitignore_global
    Use ~/.gitignore_global as the global ignore file for all repos.

autocrlf = input
    Normalize CRLF line endings to LF on commit, but do not convert LF to CRLF on checkout.
```

### `.gitignore`

This applies to the dotfiles repo itself because the work tree is `$HOME`.

Use it for home-directory-specific ignores, such as:

```text
.dotfiles/
.dotfiles-profile
.gitconfig.local
.bashrc.local
.cache/
.local/
.ssh/
.aws/
.gnupg/
.kube/
*.ovpn
.lesshst
```

### `.gitignore_global`

This applies to every Git repo on the machine.

Use it for generic local/editor/OS junk:

```text
.DS_Store
Thumbs.db
*.swp
*.swo
__pycache__/
.pytest_cache/
.mypy_cache/
.ruff_cache/
*.log
```

Do not globally ignore `.vscode/` if some projects may intentionally commit `.vscode/tasks.json`, `.vscode/launch.json`, or `.vscode/extensions.json`.

---

## Git hooks

Tracked hooks live in:

```text
~/.config/dotfiles/git-hooks/
```

Current hook:

```text
~/.config/dotfiles/git-hooks/pre-commit
```

The hook sorts package manifests before commits.

It handles:

```text
.config/dotfiles/packages/apt-base.txt
.config/dotfiles/packages/apt-work.txt
.config/dotfiles/packages/apt-personal.txt
.config/dotfiles/packages/snap-base.txt
.config/dotfiles/packages/snap-work.txt
.config/dotfiles/packages/snap-personal.txt
```

The hook is enabled through local repo config:

```bash
dotfiles config --local core.hooksPath "$HOME/.config/dotfiles/git-hooks"
```

This is set by:

```bash
dotfiles-ensure-config
```

and by:

```bash
~/bootstrap/install-dotfiles.sh
```

If commits appear to stop after printing:

```text
==> Sorting package manifests
```

debug the hook with:

```bash
bash -x ~/.config/dotfiles/git-hooks/pre-commit
```

Temporary escape hatch:

```bash
dotfiles commit --no-verify -m "Your message"
```

Only use `--no-verify` when necessary.

---

## Bootstrap scripts

Bootstrap scripts live in:

```text
~/bootstrap/
```

### `install.sh`

Top-level installer.

Runs the individual installers in order:

```bash
install-dotfiles.sh
install-apt.sh
install-snap.sh
install-uv.sh
install-docker.sh
install-vscode.sh
install-gnome.sh
```

Run with:

```bash
~/bootstrap/install.sh
```

---

### `install-dotfiles.sh`

Ensures the bare repo exists and checks it out into `$HOME`.

Responsibilities:

* checks that Git exists
* clones the bare repo into `~/.dotfiles` if missing
* checks out tracked files into `$HOME`
* backs up checkout conflicts into `~/.dotfiles-backup`
* configures local dotfiles Git settings
* sets the dotfiles Git hook path
* configures VSCode difftool if `code` exists
* creates a default `~/.dotfiles-profile` if missing

Run manually with:

```bash
~/bootstrap/install-dotfiles.sh
```

---

### `install-apt.sh`

Installs apt packages from curated manifests:

```text
~/.config/dotfiles/packages/apt-base.txt
~/.config/dotfiles/packages/apt-work.txt
~/.config/dotfiles/packages/apt-personal.txt
```

Behavior:

* always installs `apt-base.txt`
* reads `~/.dotfiles-profile`
* installs either work or personal packages depending on the profile
* skips missing/empty package files

Run manually:

```bash
~/bootstrap/install-apt.sh
```

---

### `install-snap.sh`

Installs snap packages from curated manifests:

```text
~/.config/dotfiles/packages/snap-base.txt
~/.config/dotfiles/packages/snap-work.txt
~/.config/dotfiles/packages/snap-personal.txt
```

The snap manifests support package flags.

Example:

```text
code --classic
```

Run manually:

```bash
~/bootstrap/install-snap.sh
```

---

### `install-uv.sh`

Installs `uv` if missing.

Run manually:

```bash
~/bootstrap/install-uv.sh
```

To update `uv` later, use:

```bash
uv self update
```

The installer intentionally does not auto-update an existing `uv`.

---

### `install-docker.sh`

Installs Docker Engine from Docker’s official apt repository.

Responsibilities:

* removes conflicting Docker packages if present
* installs Docker apt prerequisites
* adds Docker’s GPG key
* adds Docker’s apt repository
* installs:

  * `docker-ce`
  * `docker-ce-cli`
  * `containerd.io`
  * `docker-buildx-plugin`
  * `docker-compose-plugin`
* ensures the `docker` group exists
* adds the current user to the `docker` group
* starts/enables Docker if systemd is available

Run manually:

```bash
~/bootstrap/install-docker.sh
```

After installing Docker, log out and log back in, or run:

```bash
newgrp docker
```

Then test:

```bash
docker run hello-world
```

On WSL or systems without systemd, service startup may be skipped.

---

### `install-vscode.sh`

Installs VSCode extensions listed in:

```text
~/.config/Code/User/extensions.txt
```

Run manually:

```bash
~/bootstrap/install-vscode.sh
```

This script assumes the `code` CLI already exists. VSCode itself is expected to be installed through snap, apt, or manually before this runs.

---

### `install-gnome.sh`

Applies tracked GNOME/dconf settings.

It calls:

```text
~/.config/dotfiles/gnome/apply.sh
```

The script skips cleanly if:

* `dconf` is not installed
* no graphical session is detected
* the GNOME apply script is missing

Run manually:

```bash
~/bootstrap/install-gnome.sh
```

---

## Package manifests

Package manifests live in:

```text
~/.config/dotfiles/packages/
```

Apt manifests:

```text
apt-base.txt
apt-work.txt
apt-personal.txt
```

Snap manifests:

```text
snap-base.txt
snap-work.txt
snap-personal.txt
```

### Base vs profile-specific packages

`*-base.txt` files are for packages wanted on every machine.

`*-work.txt` files are for work-specific packages.

`*-personal.txt` files are for personal-machine extras.

The active profile comes from:

```text
~/.dotfiles-profile
```

Example:

```bash
echo work > ~/.dotfiles-profile
```

---

## Updating package manifests

Edit manifests with:

```bash
code ~/.config/dotfiles/packages
```

or use any editor.

The pre-commit hook automatically sorts and deduplicates package manifests.

Manual sort if needed:

```bash
sort -u ~/.config/dotfiles/packages/apt-base.txt -o ~/.config/dotfiles/packages/apt-base.txt
```

Commit:

```bash
dotfiles add .config/dotfiles/packages
dotfiles commit -m "Update package manifests"
dotfiles push
```

### What belongs in manifests?

Good:

```text
git
curl
fzf
ripgrep
shellcheck
dconf-cli
tree
jq
```

Avoid listing random dependencies unless you intentionally want them.

Avoid putting tools here if they have dedicated installers:

```text
Docker -> bootstrap/install-docker.sh
uv     -> bootstrap/install-uv.sh
VSCode extensions -> bootstrap/install-vscode.sh
```

Generated package snapshot files should not usually be committed.

---

## VSCode configuration

Tracked VSCode files:

```text
~/.config/Code/User/settings.json
~/.config/Code/User/keybindings.json
~/.config/Code/User/extensions.txt
```

Do not track the entire:

```text
~/.config/Code/
```

That directory includes caches, state, backups, and machine-specific data.

---

## VSCode helper script

Path:

```text
~/.config/dotfiles/shell/vscode.sh
```

Provides:

```text
vscode-save-extensions
vscode-install-extensions
vscode-edit-settings
vscode-save-config
```

### Save installed extensions

```bash
vscode-save-extensions
```

Writes:

```text
~/.config/Code/User/extensions.txt
```

### Install tracked extensions

```bash
vscode-install-extensions
```

Reads:

```text
~/.config/Code/User/extensions.txt
```

and installs each extension with:

```bash
code --install-extension <extension-id>
```

### Edit VSCode config

```bash
vscode-edit-settings
```

Opens:

```text
settings.json
keybindings.json
extensions.txt
```

### Save VSCode config into dotfiles

```bash
vscode-save-config
```

This saves the current extension list, stages VSCode config files, and shows dotfiles status.

Typical VSCode update workflow:

```bash
# Change VSCode settings/extensions normally.

vscode-save-config
dotfiles commit -m "Update VSCode configuration"
dotfiles push
```

---

## GNOME settings

GNOME settings live under:

```text
~/.config/dotfiles/gnome/
```

Scripts:

```text
~/.config/dotfiles/gnome/save.sh
~/.config/dotfiles/gnome/apply.sh
```

Tracked config dumps:

```text
~/.config/dotfiles/gnome/configs/profiles.dconf
~/.config/dotfiles/gnome/configs/desktop-interface.dconf
~/.config/dotfiles/gnome/configs/wm-keybindings.dconf
~/.config/dotfiles/gnome/configs/media-keys.dconf
```

These correspond to:

```text
GNOME Terminal profiles
GNOME desktop interface settings
GNOME window manager keybindings
GNOME media/custom keybindings
```

### Save current GNOME settings

```bash
~/.config/dotfiles/gnome/save.sh
```

Then commit:

```bash
dotfiles add .config/dotfiles/gnome
dotfiles commit -m "Update GNOME settings"
dotfiles push
```

### Apply tracked GNOME settings

```bash
~/.config/dotfiles/gnome/apply.sh
```

or through bootstrap:

```bash
~/bootstrap/install-gnome.sh
```

GNOME changes may require restarting GNOME Terminal, logging out/in, or restarting the session before everything appears.

---

## Health check

Health helpers live in:

```text
~/.config/dotfiles/shell/health.sh
```

Run:

```bash
dotfiles-health
```

It checks:

* dotfiles function availability
* dotfiles Git status
* current profile
* core commands such as `git`, `curl`, `uv`, `docker`, `code`
* VSCode config files
* bootstrap script executability

Output uses colors:

```text
OK       green
MISSING  red
WARN     yellow
sections blue
```

Use this after changes or after a fresh-machine bootstrap:

```bash
source ~/.bashrc
dotfiles-health
```

---

## tmux

This repo tracks:

```text
~/.tmux.conf
```

This is only useful if tmux is installed and used.

If tmux is not installed:

```bash
sudo apt install tmux
```

If tmux is not part of your normal workflow, the config is harmless.

---

## Typical daily workflow

Check tracked changes:

```bash
dotfiles status -sb
```

View diff:

```bash
dotfiles diff
```

Audit possible new config files:

```bash
dotfiles-audit
```

Add specific files:

```bash
dotfiles add .config/Code/User/settings.json
dotfiles add .gitconfig
dotfiles add .config/dotfiles/shell/vscode.sh
```

Commit and push:

```bash
dotfiles commit -m "Update config"
dotfiles push
```

---

## Adding new files safely

Before tracking a new file, ask:

```text
Is this config?
Is this cache?
Is this app state?
Is this secret?
Is this machine-specific?
```

Good candidates:

```text
~/.gitconfig
~/.gitignore_global
~/.tmux.conf
~/.config/Code/User/settings.json
~/.config/Code/User/keybindings.json
~/.config/Code/User/extensions.txt
~/.config/dotfiles/...
~/bootstrap/...
```

Usually do not track:

```text
~/.ssh/
~/.aws/
~/.gnupg/
~/.kube/
~/.docker/
~/.cache/
~/.local/share/
~/.mozilla/
~/.thunderbird/
~/.config/google-chrome/
~/.config/chromium/
*.ovpn
.env
.env.*
```

If unsure whether a file is ignored:

```bash
dotfiles check-ignore -v -- <path>
```

If unsure whether Git sees it:

```bash
dotfiles status --short --untracked-files=all -- <path>
```

---

## Troubleshooting

### `dotfiles` command not found

Reload shell:

```bash
source ~/.bashrc
```

Check helper file exists:

```bash
ls ~/.config/dotfiles/shell/dotfiles.sh
```

Check `.bashrc` is sourcing it.

---

### Normal status does not show untracked files

This is intentional:

```bash
dotfiles config --local status.showUntrackedFiles no
```

Use:

```bash
dotfiles-audit
```

or:

```bash
dotfiles status --short --untracked-files=all
```

---

### Accidentally staged too much

Inspect staged files:

```bash
dotfiles diff --cached --name-only
```

Unstage everything:

```bash
dotfiles reset
```

Then add files explicitly.

---

### Checkout conflict on fresh machine

Git may refuse to check out files if local files already exist.

Back them up:

```bash
mkdir -p ~/.dotfiles-backup
mv ~/.bashrc ~/.dotfiles-backup/.bashrc 2>/dev/null || true
mv ~/.gitconfig ~/.dotfiles-backup/.gitconfig 2>/dev/null || true
```

Then retry checkout.

The installer also backs up detected checkout conflicts into:

```text
~/.dotfiles-backup/
```

---

### `code` command not found

VSCode extensions cannot be installed unless the VSCode CLI exists.

Check:

```bash
command -v code
```

If VSCode is installed as a snap, make sure `code --classic` is installed via snap manifest or manually:

```bash
sudo snap install code --classic
```

Then rerun:

```bash
~/bootstrap/install-vscode.sh
```

---

### Docker installed but requires sudo

The installer adds the current user to the `docker` group.

You must log out and log back in, or run:

```bash
newgrp docker
```

Then test:

```bash
docker run hello-world
```

---

### Docker service does not start

On non-systemd systems such as some WSL setups, Docker service startup may be skipped.

Check:

```bash
systemctl status docker
```

If using WSL, Docker Desktop integration may be required.

---

### GNOME settings do not apply

Check `dconf` exists:

```bash
command -v dconf
```

Install if missing:

```bash
sudo apt install dconf-cli
```

Apply again:

```bash
~/.config/dotfiles/gnome/apply.sh
```

Restart GNOME Terminal or log out/in.

---

### Commit only prints package sorting message

Debug the pre-commit hook:

```bash
bash -x ~/.config/dotfiles/git-hooks/pre-commit
```

Check hook config:

```bash
dotfiles config --local core.hooksPath
```

Expected:

```text
/home/<user>/.config/dotfiles/git-hooks
```

Temporary bypass:

```bash
dotfiles commit --no-verify -m "Your message"
```

---

### GitHub rejects push because of private email

Set the dotfiles repo identity to an allowed email, such as a GitHub noreply email:

```bash
dotfiles config user.name "b0nl"
dotfiles config user.email "YOUR_GITHUB_NOREPLY_EMAIL"
```

Then amend/retry if needed.

---

## Maintenance checklist

After changing shell helpers:

```bash
source ~/.bashrc
dotfiles-health
dotfiles add .config/dotfiles/shell
dotfiles commit -m "Update shell helpers"
dotfiles push
```

After changing VSCode:

```bash
vscode-save-config
dotfiles commit -m "Update VSCode configuration"
dotfiles push
```

After changing GNOME settings:

```bash
~/.config/dotfiles/gnome/save.sh
dotfiles add .config/dotfiles/gnome
dotfiles commit -m "Update GNOME settings"
dotfiles push
```

After changing package manifests:

```bash
dotfiles add .config/dotfiles/packages
dotfiles commit -m "Update package manifests"
dotfiles push
```

After changing bootstrap scripts:

```bash
shellcheck ~/bootstrap/*.sh ~/.config/dotfiles/shell/*.sh
dotfiles add bootstrap .config/dotfiles/shell
dotfiles commit -m "Update bootstrap scripts"
dotfiles push
```

---

## Design philosophy

This repo is intentionally simple.

It uses:

```text
Git
Bash
apt
snap
dconf
VSCode CLI
```

It does not use a dedicated dotfiles manager such as chezmoi or GNU Stow.

The goal is not to track every file in `$HOME`.

The goal is to make a new machine quickly usable by tracking:

* shell behavior
* Git behavior
* editor configuration
* package intent
* GNOME desktop preferences
* bootstrap scripts
* helper functions

Everything else should either be installed from a package manager, recreated from scripts, synced through app accounts, or kept local.
