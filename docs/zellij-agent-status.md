# zellij-agent-status — machine map and development flow

Written 2026-10-26 after an incident where the machine silently ran a locally
built plugin wasm instead of the published release. This is the handoff doc:
everything a fresh agent needs to work on the plugin here without rediscovering
it. The plugin repo's own README has the canonical "Development flow" section —
this file adds where things live on *this* machine.

## What it is

Zellij plugin (Rust → wasm) that shows each Claude Code / Grok agent's state
(⏳ working, 🔔 waiting, ✅ done) on its Zellij tab, with a jump key (Alt+a) and
focus-clearing. Omarchy runs Zellij, so this is the agent-status plugin for the
Omarchy terminal. Source and docs: `~/dev/zellij-agent-status` — its own git
repo (sibling of devconfig), origin `github.com/rek/zellij-agent-status`, MIT,
CI + release workflows on tag push.

## Where every piece lives

| Piece | Location | Notes |
|---|---|---|
| Plugin source | `~/dev/zellij-agent-status` | own git repo, pushed; `make test` / `make build` |
| Wasm the machine runs | `~/.config/zellij/plugins/zellij-agent-status.wasm` | **must be the published release artifact** — see below |
| Install/update script | devconfig `install/install-zellij-agent-status` | downloads latest GitHub release, clears the Zellij plugin cache, reloads |
| Zellij config | devconfig `.config/zellij/config.kdl` | one `agent-status` alias (`location="file:..."`) + `load_plugins` + Alt+a `MessagePlugin "agent-status"` |
| Hook script | devconfig `.config/zellij/agent-status-hook.sh` (live at `~/.config/zellij/`) | pipes `pane:state` to the plugin; written by the plugin's first-load installer from its template |
| Plugin pin file | devconfig `.config/zellij/agent-status-plugin.url` (live at `~/.config/zellij/`) | first line = the alias URL from config.kdl; the hook pipes `--plugin` to it alone. Keep in sync with config.kdl |
| Agent hooks | `~/.claude/settings.json` | UserPromptSubmit/PostToolUse → working, Notification → waiting, Stop → stop, SessionEnd → end. Written by the plugin's first-load installer; Grok Build uses the same file |
| Zellij plugin cache | `~/.cache/zellij/**` | compiled plugins cached by URL — must be dropped on update, or the old build keeps running |

## The rule: run the published release

The machine must always run the **wasm that CI published to GitHub Releases**,
never a local `make install` build. `make install` is a dev-only step for
testing changes live; after publishing, undo it by re-running
`install/install-zellij-agent-status` (or the repo's one-liner
`install.sh | sh -s -- --update`).

How to check which build is running:

```sh
# installed file vs the published release asset — must be byte-identical:
sha256sum ~/.config/zellij/plugins/zellij-agent-status.wasm
curl -sSL https://github.com/rek/zellij-agent-status/releases/latest/download/zellij-agent-status.wasm | sha256sum
# repo state vs remote (was anything committed but never pushed/tagged?):
git -C ~/dev/zellij-agent-status fetch origin && git status -sb
# what the running plugin thinks it is (version tag in the hook it wrote):
head -2 ~/.config/zellij/agent-status-hook.sh
```

The 2026-10-26 incident: after the Oct 19 session, the machine kept a locally
built wasm (built 11:01, eleven minutes *before* the final commit) while
`v0.1.5` — the same code, built by CI — sat published on GitHub. Nothing was
unpublished; the machine was just never switched back to the release artifact.
Symptom was "it's gone back to the old way" with nothing obviously wrong in
any config. Fixed by running `install/install-zellij-agent-status` and
verifying the hashes matched.

## Development flow (summary)

1. `make test`, then `make install` (local build → `~/.config/zellij/plugins/`).
2. Drop Zellij's plugin cache and reload, or you're testing the *old* build:
   `find ~/.cache/zellij -name '*zellij-agent-status*' -prune -exec rm -rf {} +`
   then `zellij action start-or-reload-plugin agent-status </dev/null`.
3. Exercise it live: `~/.config/zellij/agent-status-hook.sh working` flips your
   tab's badge, `... end` clears it; `/hooks` in a running agent re-arms hooks.
4. Publish: bump `version` in the repo's `Cargo.toml` (the hook's version tag
   is `CARGO_PKG_VERSION`), commit, `git tag vX.Y.Z && git push origin main
   --tags` — the release workflow publishes wasm + install.sh.
5. Put the machine back on the published artifact: re-run
   `install/install-zellij-agent-status` (it now also clears the Zellij cache
   and reloads).

## Gotchas that cost real time once

- **One identity.** Zellij's plugin instance identity is (location,
  configuration). The same wasm spelled as an `https://` URL, a `file://` URL
  and a bare path spawns three instances that fight over tab names. Everything
  (config alias, Alt+a `MessagePlugin`, hook's `--plugin` pin) must use the
  single `agent-status` alias form — see devconfig commit 8ccedf4.
- **The plugin cache.** Zellij caches compiled plugins by URL. Replacing the
  wasm file (or even re-downloading an `https:` plugin) changes nothing until
  the cache entry is deleted. `install.sh --update` and this repo's
  `install/install-zellij-agent-status` both do it.
- **The plugin rewrites the hook script.** On first load — and whenever the
  hook's version tag (`# zellij-agent-status vX.Y.Z`) is older than the
  running plugin — it rewrites `~/.config/zellij/agent-status-hook.sh` from
  its baked-in template and re-merges `~/.claude/settings.json`. Since
  **v0.1.6** the template itself reads the machine-local pin file
  `~/.config/zellij/agent-status-plugin.url` (this repo tracks it): present →
  the hook pipes `--plugin` to that exact URL alone; absent → the pipe
  broadcasts. So version bumps rewrite the hook *without* discarding this
  machine's pin — the only expected diff on a bump is the version-tag line.
  Never hand-edit the hook's pin back in; edit the `.url` file or the
  template in the plugin repo. (A `--plugin` URL that is not the running
  instance makes zellij *launch* a second copy — keep the `.url` in sync with
  config.kdl's alias.)
- **Closed stdin.** `zellij pipe` waits on stdin; every invocation must
  redirect `</dev/null` or the agent hangs until the `timeout 2` kills it.
- **devconfig pushes are on demand.** Commits to devconfig stay local until
  Adam asks for a push; the plugin repo pushes normally (tags trigger public
  releases, so never push a tag casually).
