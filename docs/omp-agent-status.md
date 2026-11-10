# Plan: omp agent status in Zellij tabs

Status: **implemented 2026-11-10** (`.omp/extensions/agent-status.ts`,
`install/install-omp-agent-status`). Verified live in print mode: working →
done → end, and no badge flicker from a task subagent. Not yet exercised: the
🔔 waiting state in the interactive TUI. Differences from the plan below: the
`ask` tool also sends `waiting`, `tool_approval_resolved` sends `working`, and
`agent_end` is skipped when `willContinue` is set (all three copied from omp's
own `src/modes/warp-events.ts` bridge).

**Shipped in zellij-agent-status v0.1.8** (same day): the extension now
lives in the plugin repo (`scripts/omp-agent-status.ts`) and the plugin's
first-load installer writes it wherever `~/.omp/agent` exists. devconfig keeps
its symlink and tracked copy, which the plugin rewrites on version bumps.

Written 2026-11-10 after Adam noticed
omp (`@oh-my-pi/pi-coding-agent` 18.18.6) sessions never show an agent-status
badge. Everything below is verified against omp's installed source at
`~/.bun/install/global/node_modules/@oh-my-pi/pi-coding-agent/` unless marked
otherwise.

## Root cause

zellij-agent-status is driven by hooks in `~/.claude/settings.json`:
`UserPromptSubmit`/`PostToolUse` → working, `Notification` → waiting,
`Stop`/`SessionEnd` → done/end. Claude Code and Grok Build execute that file;
**omp never does**:

- omp imports `~/.claude/settings.json` only as *settings values*
  (`src/config/settings.ts` deep-merges it; `src/discovery/claude.ts`
  `loadSettings` just parses JSON). Grep for `UserPromptSubmit` /
  `PostToolUse` / `SessionEnd` across omp src: zero matches outside the
  settings-JSON files themselves.
- omp's Claude *hooks* discovery (`src/discovery/claude.ts` `loadHooks`) only
  scans `~/.claude/hooks/pre|post/` and only auto-loads `.ts/.js` hook-factory
  modules (`isExtensionFile`), never shell scripts.

So an omp tab pane pipes nothing to the plugin. The plugin itself, the
`agent-status` alias, the pin file, and the Alt+a jump all work — verified
2026-11-10: exactly one plugin instance (`plugin_url: "agent-status"`) is
running, other tabs (Claude/Grok) still badge correctly.

## Fix (one small omp extension)

Write a single omp extension that shells out to the existing
`~/.config/zellij/agent-status-hook.sh <state>`, reusing its no-op guards
(non-zellij), pane pin (`agent-status-plugin.url`), `timeout 2`, and
stdin handling. No changes to the hook script or the wasm plugin.

Why an *extension* and not a *hook module*: `tool_approval_requested` /
`tool_approval_resolved` exist only on `ExtensionAPI`
(`src/extensibility/extensions/types.ts` ~line 1933), not on the narrower
`HookAPI` (`src/extensibility/hooks/types.ts`). Waiting-state 🔔 coverage
needs them.

### Tracked file and install

- Source of truth in devconfig: `.omp/extensions/agent-status.ts`.
- Install = one symlink into omp's *user* extension dir:
  `mkdir -p ~/.omp/agent/extensions && ln -sfn
  ~/dev/devconfig/.omp/extensions/agent-status.ts
  ~/.omp/agent/extensions/agent-status.ts`
  - omp discovers `<agentDir>/extensions/*.{ts,js}` for every session
    (`src/discovery/builtin.ts` `loadExtensionModules`); symlinked files are
    accepted ("Symlinked *files* already match" in
    `src/discovery/helpers.ts`), and the loader realpaths them.
  - Caveat: with `--profile <name>` omp loads `~/.omp/profiles/<name>/agent`
    instead (see `getConfigDirs` in `src/discovery/builtin.ts`). Default
    profile (this machine, config at `~/.omp/agent/config.yml`) is covered.
  - No collision worry if an omp session runs *inside* devconfig: discovery
    dedupes by realpath.
- New `install/install-omp-agent-status` script (mirrors
  `install-zellij-agent-status` style: idempotent, symlink + message), called
  from both `install/install-arch.sh` and `install/install.sh` next to the
  existing agent-status step.
- Update `docs/zellij-agent-status.md`'s "Where every piece lives" table with
  the new row.

### Event mapping

| omp event (ExtensionAPI) | action | Claude Code equivalent |
|---|---|---|
| `before_agent_start` | `working` | UserPromptSubmit |
| `tool_execution_end` | `working` | PostToolUse |
| `tool_approval_requested` | `waiting` | Notification(permission_prompt) |
| `agent_end` | `done` | Stop |
| `session_shutdown` | `end` | SessionEnd |

Notes:
- **Skip subagents.** Extensions are rebound to every subagent session
  (`ctx.agent.kind === "sub"`), and a monkey/task-tool subagent shares the
  pane's `ZELLIJ_PANE_ID` — its events would flicker the tab badge. Guard:
  `if (ctx.agent?.kind && ctx.agent.kind !== "main") return;`
- After an approval resolves, the next `tool_execution_end` / `agent_end`
  overwrites `waiting` — same recovery shape as Claude (a denied approval
  ends the turn → `done` ✅).
- `turn_start` (each LLM call) can optionally also send `working` to keep
  long thinking streaks fresh; decision at implementation time.

### Sketch (shape only)

```ts
// .omp/extensions/agent-status.ts — omp extension driving zellij-agent-status
export default function (pi /* ExtensionAPI */) {
	const state = (ctx) => {
		if (ctx.agent?.kind && ctx.agent.kind !== "main") return;
		Bun.spawn([`${process.env.HOME}/.config/zellij/agent-status-hook.sh`, s],
			{ stdin: "ignore", stdout: "ignore", stderr: "ignore" }); // fire & forget
	};
	pi.on("before_agent_start", (_e, ctx) => state(ctx, "working"));
	...
}
```

- **Imports** (verified 18.18.6, where the file lives decides what resolves —
  see `src/extensibility/plugins/legacy-pi-compat.ts`):
  - Root import `from "@oh-my-pi/pi-coding-agent"` resolves from anywhere,
    including `~/.omp/agent/extensions/`: the legacy-pi shim unconditionally
    reroutes the package root (on-disk shim:
    `src/extensibility/legacy-pi-coding-agent-shim.ts`).
  - **Subpath imports** (`.../extensibility/hooks` etc.) are **NOT** safe
    from `~/.omp/` in npm-install mode: bare-dependency resolution walks
    `node_modules` upward from the importer's directory and finds nothing
    (`findNodePackageRootUncached`). omp's own bundled examples use them only
    as `import type`, which Bun erases before resolution.
  - So: type `pi` as `any` (as in the sketch) or use only `import type`
    against the package root. `Bun` global is available inside extensions.
- Env is inherited: `ZELLIJ` / `ZELLIJ_PANE_ID` are set because omp's TUI runs
  in the pane; the hook script no-ops outside Zellij, so `omp -p` and
  non-Zellij terminals are safe.

## Verification (after implementing)

1. Symlink, then launch `omp` in a Zellij tab; send a prompt → tab flips to ⏳.
2. Let it finish → ✅; focus the pane → badge clears (plugin focus-clear).
3. Trigger a permission prompt (bash command needing approval) → 🔔.
4. `head -2 ~/.config/zellij/agent-status-hook.sh` — still `v0.1.7`; the script
   is shared and must not be modified.
5. Spawn a task in omp (subagent) → tab badge must NOT flicker.
6. Confirm no second plugin instance:
   `zellij action list-panes -a -j </dev/null | jq '.[] | select(.is_plugin) |
   select(.plugin_url | test("agent-status"))'` → exactly one.

## Risks / open points

- omp extension API is versioned with omp (18.18.6); we use only `pi.on`
  events, which omp re-exports as its stable compat surface (legacy-pi shim).
  If omp renames events, the extension fails silently at load and shows in
  `/extensions` — check there first if the badge stops appearing.
- `agent_end` ↔ `session_shutdown`: if omp's normal quit (not SIGINT) doesn't
  emit `session_shutdown`, the badge stays on ✅ until focus-clear — the same
  visible behavior Claude Code had pre-SessionEnd; acceptable, note it.
- devconfig commits stay local until Adam asks for a push.
