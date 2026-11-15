#!/usr/bin/env bash

# ------------------------------------------------------------
# Dotfiles update / drift helpers
# ------------------------------------------------------------

_dotfiles_update_color() {
    [[ -t 1 ]] && printf '\033[%sm' "$1"
}

_dotfiles_update_reset() {
    [[ -t 1 ]] && printf '\033[0m'
}

_dotfiles_update_section() {
    printf '\n'
    _dotfiles_update_color '1;34'
    printf '==> %s\n' "$1"
    _dotfiles_update_reset
}

_dotfiles_update_ok() {
    _dotfiles_update_color '0;32'
    printf 'OK      '
    _dotfiles_update_reset
    printf ' %s\n' "$1"
}

_dotfiles_update_action() {
    issues=$((issues + 1))
    _dotfiles_update_color '0;33'
    printf 'UPDATE  '
    _dotfiles_update_reset
    printf ' %s\n' "$1"
}

_dotfiles_update_warn() {
    warnings=$((warnings + 1))
    _dotfiles_update_color '0;33'
    printf 'WARN    '
    _dotfiles_update_reset
    printf ' %s\n' "$1"
}

_dotfiles_update_check_dconf() {
    local dconf_path="$1"
    local tracked_file="$2"
    local label="$3"
    local tmp_file="$4"

    if [[ ! -f "$tracked_file" ]]; then
        _dotfiles_update_warn "$label snapshot is missing: $tracked_file"
        return 0
    fi

    if ! dconf dump "$dconf_path" > "$tmp_file" 2>/dev/null; then
        _dotfiles_update_warn "Could not read current $label settings"
        return 0
    fi

    if cmp -s "$tmp_file" "$tracked_file"; then
        _dotfiles_update_ok "$label matches the tracked snapshot"
    else
        _dotfiles_update_action "$label changed; run dotfiles-update-snapshots"
    fi
}

_dotfiles_update_check_tiling_shell() {
    local tracked_file="$HOME/.config/dotfiles/gnome/tiling-shell/layouts.json"
    local dconf_key='/org/gnome/shell/extensions/tilingshell/layouts-json'
    local raw_value

    [[ -f "$tracked_file" ]] || return 0

    if ! command -v python3 >/dev/null 2>&1; then
        _dotfiles_update_warn 'python3 is unavailable; cannot compare Tiling Shell layouts'
        return 0
    fi

    raw_value="$(dconf read "$dconf_key" 2>/dev/null || true)"
    if [[ -z "$raw_value" ]]; then
        _dotfiles_update_warn 'No live Tiling Shell layouts were found in dconf'
        return 0
    fi

    if RAW_VALUE="$raw_value" python3 - "$tracked_file" <<'PYTHON'
import ast
import json
import os
import pathlib
import sys

tracked_path = pathlib.Path(sys.argv[1])
tracked = json.loads(tracked_path.read_text(encoding="utf-8"))
current = json.loads(ast.literal_eval(os.environ["RAW_VALUE"]))
raise SystemExit(0 if current == tracked else 1)
PYTHON
    then
        _dotfiles_update_ok 'Tiling Shell layouts match the tracked snapshot'
    else
        _dotfiles_update_action 'Tiling Shell layouts changed; run dotfiles-update-snapshots'
    fi
}

dotfiles-update-check() {
    local issues=0
    local warnings=0
    local status_output=''
    local branch=''
    local upstream=''
    local counts=''
    local behind=0
    local ahead=0
    local tmp_dir=''
    local current_extensions=''
    local tracked_extensions=''
    local added_extensions=''
    local missing_extensions=''
    local installer=''
    local helper=''
    local name=''
    local machine=''
    local bootstrap_missing=0
    local readme_missing=0
    local readme_missing_names=()
    local shell_missing=0

    if ! declare -F dotfiles >/dev/null 2>&1; then
        printf 'ERROR: dotfiles function is not loaded\n' >&2
        return 1
    fi

    if [[ ! -d "$HOME/.dotfiles" ]]; then
        printf 'ERROR: bare dotfiles repository not found at %s/.dotfiles\n' "$HOME" >&2
        return 1
    fi

    printf 'Dotfiles update audit\n'
    printf 'Tracked files are not modified by this command.\n'

    _dotfiles_update_section 'Repository state'

    status_output="$(dotfiles status --short --untracked-files=no 2>/dev/null || true)"
    if [[ -n "$status_output" ]]; then
        _dotfiles_update_action 'Tracked dotfiles contain local changes'
        printf '%s\n' "$status_output" | sed 's/^/          /'
    else
        _dotfiles_update_ok 'No tracked local changes'
    fi

    if dotfiles remote get-url origin >/dev/null 2>&1; then
        if dotfiles fetch --quiet origin 2>/dev/null; then
            branch="$(dotfiles symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
            upstream="$(dotfiles rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"

            if [[ -z "$upstream" && -n "$branch" ]] && \
                dotfiles show-ref --verify --quiet "refs/remotes/origin/$branch"; then
                upstream="origin/$branch"
            fi

            if [[ -n "$upstream" ]]; then
                counts="$(dotfiles rev-list --left-right --count "$upstream...HEAD" 2>/dev/null || true)"
                if [[ -n "$counts" ]]; then
                    read -r behind ahead <<< "$counts"

                    if (( behind == 0 && ahead == 0 )); then
                        _dotfiles_update_ok "Local branch matches $upstream"
                    elif (( behind > 0 && ahead == 0 )); then
                        _dotfiles_update_action "Local branch is $behind commit(s) behind $upstream"
                    elif (( behind == 0 && ahead > 0 )); then
                        _dotfiles_update_action "Local branch is $ahead commit(s) ahead of $upstream; run dotfiles push"
                    else
                        _dotfiles_update_warn "Local branch diverged from $upstream ($behind behind, $ahead ahead)"
                    fi
                else
                    _dotfiles_update_warn 'Could not calculate branch divergence'
                fi
            else
                _dotfiles_update_warn 'No upstream branch is configured'
            fi
        else
            _dotfiles_update_warn 'Could not fetch origin; remote status is unknown'
        fi
    else
        _dotfiles_update_warn 'No origin remote is configured'
    fi

    _dotfiles_update_section 'VSCode snapshot'

    if ! command -v code >/dev/null 2>&1; then
        _dotfiles_update_warn "VSCode CLI 'code' is unavailable"
    elif [[ ! -f "$HOME/.config/Code/User/extensions.txt" ]]; then
        _dotfiles_update_action 'VSCode extensions snapshot is missing; run vscode-save-extensions'
    else
        tmp_dir="$(mktemp -d)"
        current_extensions="$tmp_dir/current.txt"
        tracked_extensions="$tmp_dir/tracked.txt"
        added_extensions="$tmp_dir/added.txt"
        missing_extensions="$tmp_dir/missing.txt"

        code --list-extensions 2>/dev/null \
            | tr '[:upper:]' '[:lower:]' \
            | LC_ALL=C sort -u > "$current_extensions"

        grep -vE '^[[:space:]]*(#|$)' "$HOME/.config/Code/User/extensions.txt" \
            | sed 's/\r$//' \
            | tr '[:upper:]' '[:lower:]' \
            | LC_ALL=C sort -u > "$tracked_extensions"

        comm -23 "$current_extensions" "$tracked_extensions" > "$added_extensions"
        comm -13 "$current_extensions" "$tracked_extensions" > "$missing_extensions"

        if [[ ! -s "$added_extensions" && ! -s "$missing_extensions" ]]; then
            _dotfiles_update_ok 'Installed extensions match extensions.txt'
        else
            _dotfiles_update_action 'extensions.txt is out of sync; run vscode-save-extensions'

            if [[ -s "$added_extensions" ]]; then
                printf '          Installed but not tracked:\n'
                sed 's/^/            + /' "$added_extensions"
            fi

            if [[ -s "$missing_extensions" ]]; then
                printf '          Tracked but not installed:\n'
                sed 's/^/            - /' "$missing_extensions"
            fi
        fi

        rm -rf "$tmp_dir"
        tmp_dir=''
    fi

    _dotfiles_update_section 'GNOME snapshots'

    if ! command -v dconf >/dev/null 2>&1; then
        _dotfiles_update_warn 'dconf is unavailable; skipping GNOME checks'
    elif [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" && -z "${XDG_CURRENT_DESKTOP:-}" ]]; then
        _dotfiles_update_warn 'No graphical desktop session detected; skipping GNOME checks'
    else
        tmp_dir="$(mktemp -d)"

        _dotfiles_update_check_dconf \
            '/org/gnome/terminal/legacy/profiles:/' \
            "$HOME/.config/dotfiles/gnome/configs/profiles.dconf" \
            'GNOME Terminal profiles' \
            "$tmp_dir/profiles.dconf"

        _dotfiles_update_check_dconf \
            '/org/gnome/desktop/interface/' \
            "$HOME/.config/dotfiles/gnome/configs/desktop-interface.dconf" \
            'GNOME desktop interface' \
            "$tmp_dir/interface.dconf"

        _dotfiles_update_check_dconf \
            '/org/gnome/desktop/wm/keybindings/' \
            "$HOME/.config/dotfiles/gnome/configs/wm-keybindings.dconf" \
            'GNOME window-manager keybindings' \
            "$tmp_dir/wm.dconf"

        _dotfiles_update_check_dconf \
            '/org/gnome/settings-daemon/plugins/media-keys/' \
            "$HOME/.config/dotfiles/gnome/configs/media-keys.dconf" \
            'GNOME media/custom keybindings' \
            "$tmp_dir/media.dconf"

        _dotfiles_update_check_tiling_shell
        rm -rf "$tmp_dir"
        tmp_dir=''
    fi

    _dotfiles_update_section 'Repo consistency'

    if [[ -f "$HOME/bootstrap/install.sh" ]]; then
        for installer in "$HOME"/bootstrap/install-*.sh; do
            [[ -e "$installer" ]] || continue
            name="$(basename "$installer")"

            grep -Fq "$name" "$HOME/bootstrap/install.sh" || bootstrap_missing=$((bootstrap_missing + 1))
            if [[ ! -f "$HOME/README.md" ]] || ! grep -Fq "$name" "$HOME/README.md"; then
                readme_missing=$((readme_missing + 1))
                readme_missing_names+=("$name")
            fi
        done

        if (( bootstrap_missing == 0 )); then
            _dotfiles_update_ok 'All bootstrap installers are referenced by bootstrap/install.sh'
        else
            _dotfiles_update_action "$bootstrap_missing bootstrap installer(s) are not referenced by bootstrap/install.sh"
        fi
    else
        _dotfiles_update_warn 'bootstrap/install.sh is missing'
    fi

    if [[ -f "$HOME/.bashrc" ]]; then
        for helper in "$HOME"/.config/dotfiles/shell/*.sh; do
            [[ -e "$helper" ]] || continue
            name="$(basename "$helper")"

            grep -Fq ".config/dotfiles/shell/$name" "$HOME/.bashrc" || shell_missing=$((shell_missing + 1))
            if [[ ! -f "$HOME/README.md" ]] || ! grep -Fq "$name" "$HOME/README.md"; then
                readme_missing=$((readme_missing + 1))
                readme_missing_names+=("$name")
            fi
        done

        if (( shell_missing == 0 )); then
            _dotfiles_update_ok 'All shell helpers are sourced by .bashrc'
        else
            _dotfiles_update_action "$shell_missing shell helper(s) are not sourced by .bashrc"
        fi

        machine="$(dotfiles config --local --get dotfiles.machine 2>/dev/null || true)"
        if [[ "$machine" == 'work' || "$machine" == 'personal' ]]; then
            _dotfiles_update_ok "dotfiles.machine is configured as $machine"
        else
            _dotfiles_update_warn 'dotfiles.machine is not configured as work or personal'
        fi
    else
        _dotfiles_update_warn '.bashrc is missing'
    fi

    if (( readme_missing == 0 )); then
        _dotfiles_update_ok 'README mentions every bootstrap installer and shell helper'
    else
        _dotfiles_update_action \
            "$readme_missing installer/helper reference(s) are missing from README.md"

        printf '          Missing:\n'
        printf '            - %s\n' "${readme_missing_names[@]}"
    fi

    _dotfiles_update_section 'Summary'

    if (( issues == 0 )); then
        _dotfiles_update_ok 'No dotfiles updates are required by this audit'
    else
        printf '%d update item(s) found.\n' "$issues"
        printf 'After making only the intended changes, review with:\n'
        printf '  dotfiles status -sb\n'
        printf '  dotfiles diff\n'
        printf '  dotfiles add -u\n'
        printf '  dotfiles diff --cached\n'
        printf '  dotfiles commit -m "Update workstation configuration"\n'
        printf '  dotfiles push\n'
    fi

    (( warnings > 0 )) && printf '%d warning(s) could not be fully checked.\n' "$warnings"

    # Keep $HOME literal in this guidance.
    # shellcheck disable=SC2016
    printf '\nSafety: never use dotfiles add . or dotfiles add -A from $HOME.\n'
}

dotfiles-update-snapshots() {
    printf '==> Saving tracked workstation snapshots\n'

    if declare -F vscode-save-extensions >/dev/null 2>&1; then
        vscode-save-extensions
    elif command -v code >/dev/null 2>&1; then
        mkdir -p "$HOME/.config/Code/User"
        code --list-extensions | LC_ALL=C sort -u > "$HOME/.config/Code/User/extensions.txt"
        printf '==> Saved VSCode extensions\n'
    else
        printf "WARN: VSCode CLI 'code' unavailable; extensions were not saved\n" >&2
    fi

    if [[ -x "$HOME/.config/dotfiles/gnome/save.sh" ]] && \
        command -v dconf >/dev/null 2>&1 && \
        [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}${XDG_CURRENT_DESKTOP:-}" ]]; then
        "$HOME/.config/dotfiles/gnome/save.sh"
    fi

    printf '\n==> Snapshot save complete; nothing was staged, committed, or pushed\n'
    dotfiles status -sb
}
