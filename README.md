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
        │   └── terminal/
        │       ├── profiles.dconf
        │       ├── save.sh
        │       └── apply.sh
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

# Miscellaneous Things

### `install-zotero.sh`

Installs Zotero from the Debian/Ubuntu-compatible Zotero apt repository.

It:

* configures the repository signing key;
* adds the Zotero apt source;
* installs Zotero through apt;
* allows Zotero to receive updates through the normal system package upgrade process.

Run it independently with:

```bash
~/bootstrap/install-zotero.sh
```

Zotero account authentication and library synchronization remain manual. After installation:

1. Open Zotero.
2. Go to **Edit → Settings → Sync**.
3. Sign in with the same Zotero account used for the online library.
4. Enable automatic data and attachment syncing.
5. Run the initial sync.

Zotero stores local application and research-library state under paths such as:

```text
~/.zotero/
~/Zotero/
```

These directories may contain the Zotero database, PDFs, attachments, notes, logs, translators, styles, and account state. They must remain untracked.

Do not place the active Zotero database inside a general filesystem-sync directory such as Dropbox, Google Drive, or OneDrive. Use Zotero Sync for the active library and a separate backup process for recovery.

### `install-nzbridge.sh`

Prepares [NZBridge](https://github.com/Rafael-Silva-Oliveira/NZBridge), which provides bidirectional research transfer between Zotero and Google NotebookLM.

NZBridge has two components:

* a Zotero plugin that exposes collections and items through a local Zotero endpoint;
* a Chrome or Edge extension that transfers sources and saved notes between Zotero and NotebookLM.

The installer:

* downloads the NZBridge Zotero plugin;
* downloads and extracts the browser extension;
* verifies the published SHA-256 checksums;
* stores the prepared files under:

```text
~/.local/share/nzbridge/
```

Run it independently with:

```bash
~/bootstrap/install-nzbridge.sh
```

The installer prepares the files but cannot complete the browser and Zotero UI steps automatically.

#### One-time Zotero setup

Open Zotero and select:

```text
Tools
└── Plugins
    └── gear icon
        └── Install Plugin From File
```

Choose:

```text
~/.local/share/nzbridge/nz-bridge.xpi
```

Restart Zotero if prompted.

The NZBridge local endpoint is available only while Zotero is running and the plugin is enabled.

#### One-time Chrome setup

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

On Chrome or Edge 142 and later, also open the NZBridge extension details and configure:

```text
Site settings
└── Local network access
    └── Allow
```

NotebookLM must currently use English as its interface language for NZBridge automation.

#### Research workflow

Zotero should remain the canonical research library. NotebookLM is the analysis and synthesis layer.

A recommended project structure is:

```text
Zotero collection
        ↓
NotebookLM notebook
        ↓
Saved NotebookLM notes
        ↓
Imported Zotero document and child note
```

For Zotero to NotebookLM:

1. Create a Zotero collection for the research project.
2. Add the relevant papers, PDFs, URLs, metadata, and notes.
3. Create or open the matching NotebookLM notebook.
4. Open NZBridge.
5. Select the Zotero collection in the **To NotebookLM** tab.
6. Review the selected PDFs and URLs.
7. Start the sync.

NZBridge can upload local PDF attachments, transfer suitable URLs, skip previously synchronized items, and associate a Zotero collection with a NotebookLM notebook.

For NotebookLM to Zotero:

1. Save useful NotebookLM output as a Studio note.
2. Open NZBridge’s **To Zotero** tab.
3. Select the originating Zotero collection.
4. Add useful project or provenance tags.
5. Select the notes to preserve.
6. Import them into Zotero.

Suggested tags include:

```text
origin:notebooklm
status:needs-review
project:<project-name>
```

NZBridge imports saved NotebookLM notes, not the complete disposable chat history. Important claims must still be checked against the original source before being cited or published.

The NotebookLM notebook URL and imported-note metadata provide workflow provenance, but they do not guarantee a structured citation link from every generated statement to an individual Zotero item.

### Zotero and NZBridge bootstrap order

The complete bootstrap order is:

```text
install-dotfiles.sh
install-apt.sh
install-snap.sh
install-uv.sh
install-docker.sh
install-zotero.sh
install-nzbridge.sh
install-vscode.sh
install-gnome.sh
```

Zotero is installed before NZBridge because NZBridge’s Zotero component requires Zotero.

### Zotero and NZBridge health checks

The health check should verify:

* that the `zotero` command is available;
* that the NZBridge version file exists;
* that the downloaded Zotero plugin file exists;
* that the unpacked browser extension contains `manifest.json`;
* that the NZBridge Zotero endpoint responds while Zotero is running.

Run:

```bash
source ~/.bashrc
dotfiles-health
```

An unavailable NZBridge endpoint is only a warning when Zotero is closed. Start Zotero before diagnosing the plugin installation.

### Zotero and NZBridge local state

Do not track:

```text
~/.zotero/
~/Zotero/
~/.local/share/nzbridge/
```

Also do not track:

* Zotero account credentials;
* Zotero databases or attachments;
* Google account cookies or browser sessions;
* Chrome or Edge profiles;
* NZBridge collection-to-notebook mappings stored in browser state;
* NotebookLM authentication state.

The bootstrap tracks only the installer and reproducible configuration logic. Application data, credentials, research content, and browser state remain local or are synchronized through their respective services.
