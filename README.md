# Dotfiles

Reproducible Ubuntu/Debian workstation setup based on a bare Git repository.

The bare repository is stored at:

```text
~/.dotfiles
```

The Git work tree is the home directory:

```text
$HOME
```

This setup intentionally uses plain Git and Bash rather than Stow or chezmoi.

## Dotfiles command

The main helper is:

```bash
dotfiles() {
  /usr/bin/git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"
}
```

After the shell configuration has loaded, use `dotfiles` like a normal Git command:

```bash
dotfiles status
dotfiles diff
dotfiles log --oneline
dotfiles push
```

## Repository layout

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
|   ├── install-zotero.sh
|   └── install-nzbridge.sh
│   ├── install-vscode.sh
│   ├── install-gnome-extensions.sh
│   └── install-gnome.sh
└── .config/
    ├── Code/
    │   └── User/
    │       ├── extensions.txt
    │       ├── keybindings.json
    │       ├── settings.json
    │       └── snippets/
    └── dotfiles/
        ├── git-hooks/
        │   └── pre-commit
        ├── gnome/
        │   ├── save.sh
        │   ├── apply.sh
        │   ├── configs/
        │   └── tiling-shell/
        │       ├── save.sh
        │       ├── apply.sh
        │       └── layouts.json
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

GNOME Terminal configuration belongs under:

```text
~/.config/dotfiles/gnome/terminal/
```

## Fresh machine installation

Install the minimum prerequisites:

```bash
sudo apt update
sudo apt install -y git curl
```

Clone the repository as a bare Git repository:

```bash
git clone --bare git@github.com:b0nl/dotfiles.git "$HOME/.dotfiles"
```

Check out the work tree:

```bash
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" checkout
```

Run the complete bootstrap:

```bash
~/bootstrap/install.sh
```

Reload Bash and run the health check:

```bash
source ~/.bashrc
dotfiles-health
```

### Checkout conflicts

A fresh machine may already contain files such as `.bashrc` or `.profile`.

Back conflicting files up under:

```text
~/.dotfiles-backup/
```

Then retry the checkout.

Do not delete conflicting files until the backup has been checked.

## Machine type

The bootstrap asks once whether the computer is a work laptop.

The selected value is stored in the local configuration of the bare repository:

```bash
dotfiles config --local dotfiles.machine work
```

or:

```bash
dotfiles config --local dotfiles.machine personal
```

Inspect the current value with:

```bash
dotfiles config --local --get dotfiles.machine
```

The value is stored in:

```text
~/.dotfiles/config
```

It is local to the current computer. It is not tracked or pushed.

The prompt is skipped when `dotfiles.machine` is already configured.

For a non-interactive installation, set the value explicitly:

```bash
DOTFILES_MACHINE=work ~/bootstrap/install.sh
```

or:

```bash
DOTFILES_MACHINE=personal ~/bootstrap/install.sh
```

### Work machines

A work installation:

- installs the base and work package manifests;
- loads `~/.bashrc.work`;
- installs `kubectl`;
- installs Docker;
- adds the current user to the `docker` group;
- prompts for Docker registry authentication to `hub.your-work.com`.

### Personal machines

A personal installation:

- installs the base and personal package manifests;
- does not load a separate personal Bash file;
- skips work-only bootstrap actions.

There is currently no `.bashrc.local` layer.

## Shell setup

The main Bash entrypoint is:

```text
~/.bashrc
```

It loads the tracked shell helpers under:

```text
~/.config/dotfiles/shell/
```

Known helpers:

```text
dotfiles.sh
vscode.sh
health.sh
```

When `dotfiles.machine` is set to `work`, Bash also loads:

```text
~/.bashrc.work
```

Shell files should be sourced defensively:

```bash
[ -f "$HOME/.config/dotfiles/shell/dotfiles.sh" ] &&
  . "$HOME/.config/dotfiles/shell/dotfiles.sh"
```

## Bootstrap scripts

The top-level installer is:

```text
~/bootstrap/install.sh
```

It runs the individual installers in this order:

```text
install-dotfiles.sh
install-apt.sh
install-snap.sh
install-uv.sh
install-docker.sh
install-vscode.sh
install-gnome-extensions.sh
install-gnome.sh
```

### `install.sh`

The top-level coordinator:

- runs the dotfiles checkout/configuration step first;
- reads the existing `dotfiles.machine` value;
- prompts once when the machine type is not configured;
- stores the answer in the bare repository's local Git config;
- exports `DOTFILES_MACHINE` for the remaining installers;
- runs the installers in order.

Run it with:

```bash
~/bootstrap/install.sh
```

### `install-dotfiles.sh`

Responsible for:

- cloning or reusing the bare repository;
- checking out the home-directory work tree;
- backing up conflicting files;
- setting `status.showUntrackedFiles no`;
- setting the tracked Git hook path;
- configuring the VSCode diff tool when `code` is available;
- ensuring the expected local Git configuration exists.

Machine selection is not stored in a separate profile file.

### `install-apt.sh`

Installs curated apt packages from:

```text
~/.config/dotfiles/packages/
```

Behavior:

- always installs `apt-base.txt`;
- installs `apt-work.txt` when `dotfiles.machine=work`;
- installs `apt-personal.txt` when `dotfiles.machine=personal`;
- skips missing, blank, and comment-only lines.

### `install-snap.sh`

Installs curated Snap packages from:

```text
~/.config/dotfiles/packages/
```

Behavior:

- always installs `snap-base.txt`;
- installs `snap-work.txt` when `dotfiles.machine=work`;
- installs `snap-personal.txt` when `dotfiles.machine=personal`;
- supports package flags in the manifest.

The work manifest includes:

```text
kubectl --classic
```

Verify the installation with:

```bash
kubectl version --client
```

Kubernetes credentials and cluster configuration under `~/.kube/` must remain untracked.

### `install-uv.sh`

Installs `uv` when it is missing.

Updating is intentionally manual:

```bash
uv self update
```

### `install-docker.sh`

Installs Docker Engine from Docker's official apt repository.

It also:

- ensures the `docker` group exists;
- adds the current user to the group;
- enables and starts Docker when systemd is available;
- prompts work machines to log in to:

```text
hub.your-work.com
```

The registry login remains interactive:

```bash
docker login hub.your-work.com
```

Passwords and access tokens must never be stored in the bootstrap scripts or committed to the dotfiles repository.

Docker writes local authentication state under:

```text
~/.docker/
```

That directory must remain untracked.

Docker group membership normally becomes active after logging out and back in.

For the current shell only, it can be activated with:

```bash
newgrp docker
```

Check membership with:

```bash
id -nG | tr ' ' '\n' | grep -x docker
```

Membership in the `docker` group grants effectively root-level control over the machine.

### `install-vscode.sh`

Installs extensions listed in:

```text
~/.config/Code/User/extensions.txt
```

### `install-gnome.sh`

Applies tracked GNOME configuration only when:

- `dconf` is available;
- a graphical desktop session is present;
- the relevant tracked configuration files exist.

It should not blindly apply desktop settings on headless systems.

## Package manifests

Package manifests live under:

```text
~/.config/dotfiles/packages/
```

Files:

```text
apt-base.txt
apt-work.txt
apt-personal.txt
snap-base.txt
snap-work.txt
snap-personal.txt
```

### Base and machine-specific packages

`*-base.txt` contains packages wanted on every machine.

`*-work.txt` contains work-only packages.

`*-personal.txt` contains personal-machine packages.

The active machine type is read with:

```bash
dotfiles config --local --get dotfiles.machine
```

Change it manually with:

```bash
dotfiles config --local dotfiles.machine work
```

or:

```bash
dotfiles config --local dotfiles.machine personal
```

Reload Bash after changing it:

```bash
source ~/.bashrc
```

Keep package manifests curated.

Do not track generated package snapshots such as:

```text
apt-manual-current.txt
apt-after-install-current.txt
snap-current.txt
```

## Package manifest hook

The tracked pre-commit hook is:

```text
~/.config/dotfiles/git-hooks/pre-commit
```

It sorts and deduplicates apt and Snap manifests before commits.

Because the repository is bare, the hook must use the `dotfiles` Git command rather than plain `git add`.

If a commit stops after:

```text
==> Sorting package manifests
```

debug it with:

```bash
bash -x ~/.config/dotfiles/git-hooks/pre-commit
```

Temporary bypass:

```bash
dotfiles commit --no-verify -m "message"
```

## Important dotfiles safety rule

Because `$HOME` is the Git work tree, never run these casually from the home directory:

```bash
dotfiles add .
dotfiles add -A
```

They can stage the entire home directory.

For already tracked files, prefer:

```bash
dotfiles add -u
```

For new files, add explicit paths:

```bash
dotfiles add .gitconfig
dotfiles add bootstrap/install-docker.sh
dotfiles add .config/dotfiles/shell/health.sh
```

Before committing:

```bash
dotfiles diff --cached
```

## Hidden untracked files

Normal status output hides untracked files:

```bash
dotfiles config --local status.showUntrackedFiles no
```

This only changes status display. It does not ignore files.

Audit untracked files with:

```bash
dotfiles status --short --untracked-files=all
dotfiles-audit
dotfiles-audit-all
```

## Files that must remain untracked

Do not track credentials, private keys, machine state, or application caches.

Examples:

```text
.dotfiles/
.dotfiles-backup/
.gitconfig.local
.cache/
.local/
.ssh/
.aws/
.gnupg/
.kube/
.docker/
*.ovpn
.env
.env.*
.lesshst
```

An OpenVPN file may contain certificates, private keys, credentials, or private endpoints. Inspect it carefully and keep it untracked by default.

## Git configuration

Tracked Git files:

```text
~/.gitconfig
~/.gitignore
~/.gitignore_global
```

Potential local-only file:

```text
~/.gitconfig.local
```

Recommended core settings:

```gitconfig
[core]
    editor = code --wait
    excludesfile = ~/.gitignore_global
    autocrlf = input
```

Meaning:

- `editor = code --wait` opens VSCode for Git editing and waits for it to close;
- `excludesfile = ~/.gitignore_global` applies user-wide ignore rules;
- `autocrlf = input` normalizes CRLF to LF when committing.

`.gitignore` applies to the bare dotfiles repository's home-directory work tree.

`.gitignore_global` applies to every normal Git repository on the machine.

## VSCode

Tracked VSCode files:

```text
~/.config/Code/User/settings.json
~/.config/Code/User/keybindings.json
~/.config/Code/User/extensions.txt
~/.config/Code/User/snippets/
```

Do not track all of `~/.config/Code`; it contains caches and machine state.

VSCode helper functions live in:

```text
~/.config/dotfiles/shell/vscode.sh
```

Typical update workflow:

```bash
vscode-save-config
dotfiles add \
  .config/Code/User/settings.json \
  .config/Code/User/keybindings.json \
  .config/Code/User/extensions.txt
dotfiles diff --cached
dotfiles commit -m "Update VSCode configuration"
dotfiles push
```

Keep global Python settings restrained. Let each repository's `pyproject.toml` define strict linting and type-checking behavior.

A reasonable global baseline is:

```json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
  "python.terminal.activateEnvironment": true,
  "python.analysis.typeCheckingMode": "basic",
  "python.analysis.autoImportCompletions": true,
  "ruff.nativeServer": "on"
}
```

## GNOME configuration

GNOME helpers live under:

```text
~/.config/dotfiles/gnome/
```

Useful dconf dumps:

```bash
dconf dump /org/gnome/desktop/interface/
dconf dump /org/gnome/desktop/wm/keybindings/
dconf dump /org/gnome/settings-daemon/plugins/media-keys/
dconf dump /org/gnome/terminal/legacy/profiles:/
```

GNOME Terminal profiles are stored beneath:

```text
/org/gnome/terminal/legacy/profiles:/
```

The restore process must remain guarded and should not run on headless machines.

### Tiling Shell

Tiling Shell provides reusable custom window grids for GNOME.

The installation flow consists of:

1. `install-apt.sh` installing the Extension Manager package from the base apt manifest;
2. `install-gnome-extensions.sh` installing and enabling Tiling Shell;
3. disabling Ubuntu's bundled Tiling Assistant extension to prevent both tiling systems from handling the same window snapping events;
4. `install-gnome.sh` restoring the tracked Tiling Shell layouts.

The relevant extension UUIDs are:

```text
tilingshell@ferrarodomenico.com
tiling-assistant@ubuntu.com
```

Only Tiling Shell should remain enabled:

```bash
gnome-extensions list --enabled | grep -i tiling
```

Expected result:

```text
tilingshell@ferrarodomenico.com
```

If Ubuntu's Tiling Assistant is still enabled, disable it with:

```bash
gnome-extensions disable tiling-assistant@ubuntu.com
gnome-extensions enable tilingshell@ferrarodomenico.com
```

A logout and login may be required after installing or changing GNOME Shell extensions.

#### Tracked layouts

Tiling Shell stores its reusable layout definitions in a dconf value. The dotfiles setup exports that value to a readable JSON file:

```text
~/.config/dotfiles/gnome/tiling-shell/layouts.json
```

The supporting scripts are:

```text
~/.config/dotfiles/gnome/tiling-shell/save.sh
~/.config/dotfiles/gnome/tiling-shell/apply.sh
```

Save the current Tiling Shell layouts with:

```bash
~/.config/dotfiles/gnome/tiling-shell/save.sh
```

Restore the tracked layouts with:

```bash
~/.config/dotfiles/gnome/tiling-shell/apply.sh
```

The central GNOME helpers invoke these scripts automatically. To save all tracked GNOME settings, including Tiling Shell layouts, run:

```bash
~/.config/dotfiles/gnome/save.sh
```

To restore all tracked GNOME settings:

```bash
~/.config/dotfiles/gnome/apply.sh
```

The layout JSON may contain several layouts. Saving the layouts again replaces the tracked JSON with the current Tiling Shell configuration.

Tiling Shell restores window-grid definitions only. It does not automatically launch applications or associate specific applications with particular tiles.


## Health check

Health helpers live in:

```text
~/.config/dotfiles/shell/health.sh
```

Run:

```bash
dotfiles-health
```

The health check verifies:

- the `dotfiles` function;
- dotfiles Git status;
- the local `dotfiles.machine` value;
- core commands such as `git`, `curl`, `uv`, `code`, and `zotero`;
- Docker installation;
- Docker group membership;
- whether the Docker group is active in the current shell;
- Docker daemon access;
- `kubectl` on work machines;
- the current kubectl context;
- the local Docker login entry for `hub.your-work.com`;
- tracked VSCode configuration files;
- bootstrap script executability.

Work-only checks run only when:

```text
dotfiles.machine = work
```

Output colors:

```text
OK       green
MISSING  red
WARN     yellow
sections blue
```

Run it after bootstrap or after changing shell helpers:

```bash
source ~/.bashrc
dotfiles-health
```

## Important commands

```bash
dotfiles
dotfiles-ensure-config
dotfiles-audit
dotfiles-audit-all
dotfiles-pick
vscode-save-extensions
vscode-install-extensions
vscode-edit-settings
vscode-save-config
dotfiles-health
```

If available:

```bash
dotfiles-check-scripts
```

## Validation

Recommended checks:

```bash
source ~/.bashrc

bash -n ~/.config/dotfiles/shell/health.sh

shellcheck \
  ~/bootstrap/*.sh \
  ~/.config/dotfiles/shell/*.sh

dotfiles-health
dotfiles status -sb
dotfiles log --oneline --graph --decorate -10
```

## Troubleshooting

### Machine type is not configured

Check:

```bash
dotfiles config --local --get dotfiles.machine
```

Configure a work machine:

```bash
dotfiles config --local dotfiles.machine work
```

Configure a personal machine:

```bash
dotfiles config --local dotfiles.machine personal
```

Reload Bash:

```bash
source ~/.bashrc
```

### Docker group membership is not active

Check the current shell:

```bash
id -nG | tr ' ' '\n' | grep -x docker
```

Log out and back in.

For a temporary shell:

```bash
newgrp docker
```

Then verify:

```bash
docker info
```

### Work Docker registry login is missing

Run:

```bash
docker login hub.your-work.com
```

Then:

```bash
dotfiles-health
```

Do not commit:

```text
~/.docker/config.json
```

### kubectl is missing on a work machine

Rerun the Snap installer:

```bash
~/bootstrap/install-snap.sh
```

Or install it directly:

```bash
sudo snap install kubectl --classic
```

Verify:

```bash
kubectl version --client
```

### No kubectl context is configured

Check:

```bash
kubectl config current-context
```

Kubernetes normally reads configuration from:

```text
~/.kube/config
```

Obtain the correct kubeconfig through the approved work process.

Do not commit `~/.kube/`.

### VSCode extensions are missing

Run:

```bash
vscode-install-extensions
```

or:

```bash
~/bootstrap/install-vscode.sh
```

### GNOME settings do not apply

Confirm that:

- the system has a graphical GNOME session;
- `dconf` is installed;
- the tracked dump files exist;
- the apply script is executable.

Do not force GNOME restoration on a headless system.

## Updating tracked files

Stage only explicit paths:

```bash
dotfiles add \
  README.md \
  .bashrc \
  .gitignore \
  bootstrap/install.sh \
  bootstrap/install-dotfiles.sh \
  bootstrap/install-apt.sh \
  bootstrap/install-snap.sh \
  bootstrap/install-docker.sh \
  .config/dotfiles/packages/snap-work.txt \
  .config/dotfiles/shell/health.sh
```

Review before committing:

```bash
dotfiles diff --cached
```

Commit and push:

```bash
dotfiles commit -m "Add machine-aware work bootstrap"
dotfiles push
```

Never replace the explicit staging command above with:

```bash
dotfiles add .
dotfiles add -A
```

## Deferred improvements

Potential future work:

- test the bootstrap in a fresh Ubuntu VM or WSL installation;
- add non-Ubuntu operating-system guards if needed;
- refine GNOME interface and keybinding configuration;
- add per-project `.vscode/settings.json` or `tasks.json` files where useful;
- add project-specific `CLAUDE.md` or `.github/copilot-instructions.md`;
- track sanitized SSH configuration only when it is demonstrably safe;
- revisit chezmoi only if multiple operating systems or secret templating make the bare Git approach too cumbersome.

-----------------------------

# Miscellaneous

### Ledger Wallet

Ledger Wallet, formerly Ledger Live, is installed on personal machines through:

    ~/bootstrap/install-ledger-wallet.sh

The installer:

- downloads the current official Linux AppImage;
- installs it under `~/.local/opt/ledger-wallet/`;
- creates the `ledger-wallet` command under `~/.local/bin/`;
- creates a desktop application entry;
- installs the Linux USB rules required for Ledger hardware devices;
- skips work machines automatically.

Launch it from the application menu or run:

    ledger-wallet

Rerunning the installer replaces the installed AppImage with the current
official Linux release.

The downloaded binary's SHA-512 hash is printed during installation. It can
be checked against Ledger's official download-signatures page before first
launch.

Ledger application data and account metadata must remain untracked. Never
store a PIN, recovery phrase, private key, account export, or screenshot of a
recovery phrase in the dotfiles repository.

### Xpad

Xpad provides lightweight desktop sticky notes similar to Windows Sticky Notes.

It is installed through the base apt package manifest:

```text
~/.config/dotfiles/packages/apt-base.txt
```

Launch it from the application menu or run:

```bash
xpad
```

Useful commands include:

```bash
xpad --new
xpad --show
xpad --toggle
xpad --quit
```

Xpad stores notes and local application state under:

```text
~/.config/xpad/
```

This directory must remain untracked because it may contain private notes and machine-specific state. Xpad should be treated as a local scratch-note application rather than a synchronized or version-controlled knowledge store.

### Zotero

Zotero is installed through a dedicated bootstrap script:

```bash
~/bootstrap/install-zotero.sh
```

The installer configures the Zotero apt repository and installs Zotero through apt so it receives normal system updates.

After installation, open Zotero and sign in under:

```text
Edit → Settings → Sync
```

Use the same Zotero account as the web library to synchronize collections, references, notes, and attachments.

Zotero’s local library and application state must remain untracked:

```text
~/.zotero/
~/Zotero/
```

These directories may contain databases, PDFs, attachments, notes, logs, and account state.

Do not store the active Zotero database inside Dropbox, Google Drive, OneDrive, or another general filesystem-sync directory. Use Zotero Sync for library synchronization.

### Zotero and NotebookLM with NZBridge

[NZBridge](https://github.com/Rafael-Silva-Oliveira/NZBridge) provides bidirectional transfer between Zotero and Google NotebookLM.

It consists of:

* a Zotero plugin;
* an unpacked Chrome or Edge extension.

Prepare both components with:

```bash
~/bootstrap/install-nzbridge.sh
```

The downloaded files are stored under:

```text
~/.local/share/nzbridge/
```

#### Zotero plugin setup

In Zotero, open:

```text
Tools → Plugins → gear icon → Install Plugin From File
```

Select:

```text
~/.local/share/nzbridge/nz-bridge.xpi
```

Restart Zotero if requested.

#### Browser extension setup

Open:

```text
chrome://extensions
```

Then:

1. Enable **Developer mode**.
2. Select **Load unpacked**.
3. Choose:

```text
~/.local/share/nzbridge/browser-extension/
```

4. Pin NZBridge to the browser toolbar.
5. Open the extension’s site settings and allow local-network access if Chrome requests it.

Zotero must be running for the browser extension to communicate with the NZBridge plugin.

#### Updating NZBridge

Run the installer to download and prepare the latest NZBridge release:

```bash
~/bootstrap/install-nzbridge.sh
```

The installer updates both the Zotero plugin and the unpacked browser-extension files under:

```text
~/.local/share/nzbridge/
```

After the update:

1. Open `chrome://extensions` or `edge://extensions`.
2. Find NZBridge.
3. Click **Reload**.

You normally do not need to select **Load unpacked** again because the installer keeps the extension at the same path:

```text
~/.local/share/nzbridge/browser-extension/
```

To update the Zotero plugin, open Zotero and reinstall:

```text
~/.local/share/nzbridge/nz-bridge.xpi
```

using:

```text
Tools → Plugins → gear icon → Install Plugin From File
```

Check for an available update without installing it:

```bash
~/bootstrap/install-nzbridge.sh --check
```

Force a fresh reinstall:

```bash
~/bootstrap/install-nzbridge.sh --force
```

#### Research workflow

Zotero remains the canonical research library. NotebookLM is used for analysis, synthesis, and exploratory questioning.

A typical flow is:

```text
Zotero collection
        ↓
NotebookLM notebook
        ↓
Saved NotebookLM notes
        ↓
Imported back into Zotero
```

For Zotero to NotebookLM:

1. Create a Zotero collection for the project.
2. Add papers, PDFs, URLs, and metadata.
3. Open the corresponding NotebookLM notebook.
4. Use NZBridge’s **To NotebookLM** tab to transfer the sources.

Note that PDFs will not show up on the browser extension unless their metadata (eg. author, etc.) is retrieved and attached to the PDF in Zotero.

For NotebookLM to Zotero:

1. Save useful NotebookLM output as a note.
2. Open NZBridge’s **To Zotero** tab.
3. Select the originating Zotero collection.
4. Import the saved notes.
5. Add provenance and review tags where useful.

Example tags:

```text
origin:notebooklm
status:needs-review
project:<project-name>
```

Imported NotebookLM content should be treated as research notes, not as an authoritative citation source. Verify important claims against the original Zotero items before citing or publishing them.

Do not track:

```text
~/.zotero/
~/Zotero/
~/.local/share/nzbridge/
```

Also keep Zotero credentials, Google sessions, browser profiles, NotebookLM authentication state, and research-library data outside the dotfiles repository.