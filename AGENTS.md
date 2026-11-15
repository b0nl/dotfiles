# Steward dotfiles

Steward maintains reproducible Ubuntu/Debian workstation configuration
and shared agent tooling. These instructions apply to this repository.

Use [README.md](README.md) for repository layout, setup, package ownership,
and maintenance workflows. Read the sections relevant to the task.

## Git and scope

- On an installed workstation, the Git directory is `$HOME/.dotfiles`
  and the worktree is `$HOME`.
- In an ordinary clone or cloud checkout, use that checkout's normal Git
  repository. Do not treat the runner's home directory as the workstation.

For the installed layout, use explicit bare-repository arguments:

```bash
/usr/bin/git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" \
  -C "$HOME" status -sb
```

Use the same prefix for other Steward Git operations. The interactive
`dotfiles` function may be unavailable in an agent's shell.

- Inspect status before editing and preserve unrelated changes.
- Limit discovery to tracked files and explicitly requested new paths;
  avoid recursive searches across the entire home directory.
- Stage explicit paths and review the staged diff before committing.
  Never bulk-stage the home directory with `add .` or `add -A`.
- Do not initialize `$HOME/.git` or perform destructive Git cleanup
  without explicit authorization.
- Keep credentials, application profiles, caches, and downloaded binaries
  untracked.

## Changes

- Prefer focused changes using existing Bash and native tooling.
- Preserve work/personal machine distinctions. Machine selection lives
  in the installed bare repository's local `dotfiles.machine` setting.
- Keep package manifests curated.
- Keep Copilot optional; do not introduce Claude-specific configuration
  into shared setup.
- Update README.md when behavior, setup, or maintenance workflows change.
  Keep bootstrap, health, and update-tool integration aligned when affected.

## Verification

- Validate changed Bash scripts with `bash -n` and ShellCheck.
- Use focused checks appropriate to the change.
- Run installers or apply desktop settings only when the requested task
  requires workstation changes.
- Review worktree and staged diffs before finishing. Commit or push only
  when authorized by the task or session.
