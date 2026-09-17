# Omarchy Agents plugin — next steps (OpenRouter + Grok Business)

Written 2026-09-16 at the end of a session that built a custom fork of Omarchy's
"Agents" bar-widget plugin. This doc is a handoff: everything below is what a
fresh agent needs to pick this up cold, plus a concrete plan for the two
things Adam asked for next. Read the whole "Current state" section before
touching anything — several bits of this are non-obvious and cost real time
to figure out once already.

## Current state

**What exists:** `~/.config/omarchy/plugins/adam.agents/` — a clone of the
first-party `omarchy.agents` plugin (made via `omarchy plugin clone
omarchy.agents`), heavily modified:

- `Panel.qml` — adds an inline bar-widget mode (percentages + `(Xh)`/`(Xd)`
  reset countdowns spelled out directly in the top bar, not just an icon you
  have to click), a "FLEET" summary section and per-provider percentage chips
  in the popup, and an "EST. COST TODAY" section (currently inert for real
  providers — only the removed mock-data path populated `estCostToday`).
- `manifest.json` — adds an `inlineExpanded` boolean setting.
- Bar config lives in `~/.config/omarchy/shell.json`, under
  `bar.layout.right`, the `adam.agents` entry:
  ```json
  {
    "id": "adam.agents",
    "inlineExpanded": true,
    "providers": { "fireworks": { "enabled": false } }
  }
  ```

**⚠️ Nothing above is version-controlled.** `~/.config/omarchy/` is not
tracked by this devconfig repo at all (`git ls-files | grep '^\.config/omarchy'`
returns nothing). The plugin clone and `shell.json` edits exist only as live
files on this machine. If this machine were reimaged tonight, all of it would
be gone. Worth fixing before doing much more — either bring
`~/.config/omarchy/plugins/adam.agents/` into this repo (e.g. under
`config-omarchy/` or similar, symlinked into place the way `.config/systemd/user/`
already is), or jump straight to the standalone repo Adam mentioned wanting
eventually (see "Later, not urgent" below). Either works; just don't leave it
un-backed-up much longer.

**What's tracked in devconfig (uncommitted, nothing pushed):**
- `bin/omarchy-agent-usage-grok` — the Grok collector (below).
- `.config/systemd/user/omarchy-agent-usage-grok.{service,timer}` — its
  schedule, symlinked live into `~/.config/systemd/user/` and already
  `systemctl --user enable --now`'d.
- `bin/__pycache__/` — stray, untracked, should just be deleted and
  `__pycache__/` added to `.gitignore`.

**Providers currently showing, with real data:**
- **Claude** — real, via the official `omarchy-agent-usage-claude` collector.
  Bar/inline now shows the **Session (5-hour)** window specifically, not
  whichever window has the highest percent — Adam asked for "the current
  window, not the whole week reset."
- **Codex** — also real (confirmed: 87 total prompts, 4 sessions, 3 active
  days, tier "free" — genuine low-volume usage, not a stub). Official
  `omarchy-agent-usage-codex` collector.
- **Fireworks** — disabled per Adam's request (`providers.fireworks.enabled:
  false` in shell.json). Not shown.
- **Grok** — real, but currently pinned at "100% used" because Adam's xAI
  team is over its **API/Console monthly spending limit** right now (see
  Task 2 — this is very likely a *different* limit than the SuperGrok
  subscription pool, and the current label is probably misleading).

**Key architectural fact learned this session:** the panel/bar auto-discovers
*any* `<id>.json` file dropped into
`${XDG_STATE_HOME:-~/.local/state}/omarchy/agents/usage/` — it doesn't care
who wrote it. Main.qml just `find`s that directory and watches whatever's
there via `FileView`. This is how Grok was added with **zero QML changes**:
`bin/omarchy-agent-usage-grok` writes `grok.json` there directly, on its own
systemd timer, completely decoupled from the official
`omarchy-agent-usage-update` runner (which only globs the root-owned
`$OMARCHY_PATH/bin/`, not writable without touching the system package). Use
this exact pattern for OpenRouter too.

**A real, load-bearing bug fixed this session, worth knowing about:** the
plugin's root QML item used to be `visible: providers.length > 0`. Real
provider data loads *asynchronously* (Main.qml scans usage files on
`Component.onCompleted`, takes under a second but not zero), so the item
started at `providers.length === 0` / invisible / zero width, then grew once
data arrived. Omarchy's bar (`Bar.qml`'s `ModuleSlot`) does NOT reliably
re-layout for that kind of late growth from an initially-invisible/zero-width
slot — confirmed via `Component.onCompleted`/`onImplicitWidthChanged` console
logging showing the item correctly reaching `visible=true,
implicitWidth=248, providers=2` internally while remaining genuinely absent
on screen. Mock data (a static array) never hit this because it was populated
instantly. **Fix:** `visible: true` unconditionally now, so the widget is
non-zero-sized from frame one even while `providers` is still empty. If a
future change reintroduces a "hide when truly empty" gate, expect this bug
back — test with a full `omarchy restart shell` (not just a hot-reload/save,
which does NOT re-run `Component.onCompleted` and will hide this class of
bug), and give it a couple seconds before judging.

**Also worth knowing:** `omarchy-shell <target> open/close/toggle` (IPC) does
not reliably work for this plugin — the disabled original `omarchy.agents`
plugin still holds an inert `IpcHandler` registration that silently wins
against the clone's, even when the original is fully disabled. Don't rely on
it for automation; a real click bypasses this fine (`BarIconButton.onPressed`
calls `root.toggle()` directly, no IPC involved).

## Task 1 — OpenRouter collector

**Goal:** show OpenRouter's free-model daily request usage (and remaining
credit balance) in the bar/panel, same as Claude/Codex/Grok.

**Blocked on:** Adam needs to put his OpenRouter API key in a file on disk —
do NOT ask for it in chat. Suggested path: `~/.config/openrouter/api_key`
(plain text, just the key, `chmod 600`). Check for it first
(`test -f ~/.config/openrouter/api_key`); if it's not there, ask Adam where
he put it or ask him to create it.

**Confirmed API details** (verified against OpenRouter's own docs this
session, not guessed):

- `GET https://openrouter.ai/api/v1/key`
- Header: `Authorization: Bearer <OPENROUTER_API_KEY>`
- Response:
  ```jsonc
  {
    "data": {
      "label": "...",
      "limit": number | null,           // credit cap, null = unlimited
      "limit_remaining": number | null,
      "usage": number,                   // all-time credits used
      "usage_daily": number,
      "is_free_tier": boolean,
      "free_model_daily_requests": {
        "used": number,
        "limit": number,                 // 50 (no credits bought) or 1000 (bought $10+, ever)
        "remaining": number
      }
    }
  }
  ```
- Free-model requests reset **daily on a UTC day boundary** — unlike Grok,
  this reset time is exactly computable locally (next `00:00 UTC`), no need
  to parse it out of a response. `resetsAt` can just be
  `datetime.now(UTC).replace(hour=0,minute=0,second=0,microsecond=0) +
  timedelta(days=1)`.
- Also confirmed: per-minute limit is 20 RPM always, but that's not a
  meaningful thing to show as a bar percentage (too fast-moving) — skip it,
  just track the daily counter.

**Plan:**

1. Confirm the key file exists and read it (same pattern as
   `bin/omarchy-agent-usage-grok`'s `load_token()` — copy the general shape
   of that script, it's a good template: `base_record()`, `write_record()`
   with atomic temp-file + `os.replace`, `waiting_for_auth()` for the
   no-key/bad-key case).
2. Before writing the parser, do a **one-off live test call** with the real
   key (`curl -H "Authorization: Bearer $(cat ~/.config/openrouter/api_key)"
   https://openrouter.ai/api/v1/key | python3 -m json.tool`) and eyeball the
   actual response — the shape above is from docs, not a live capture on
   Adam's own key, so double check before trusting field names blindly (this
   bit us slightly with Grok — build in that verification step, don't skip
   it).
3. Write `bin/omarchy-agent-usage-openrouter` (Python, executable,
   `#!/usr/bin/env python3`), writing to
   `~/.local/state/omarchy/agents/usage/openrouter.json` with:
   - `limits: [{ "label": "Free model requests", "title": "Daily", "percent": used/limit, "resetsAt": <next UTC midnight, computed> }]`
   - If `data.limit` (credit cap) is non-null, also consider a `balance`
     entry (`remaining`/`funded`/`spent` — see the schema Main.qml's
     `balanceValue()` expects, already documented in
     `~/.config/omarchy/plugins/adam.agents/Main.qml` if it still exists, or
     re-derive from `Panel.qml`'s `balanceDetailText`/`formatMoney`). Only
     bother with this if `limit` is actually set — most users run OpenRouter
     unlimited/pay-as-you-go, in which case just skip the balance section
     entirely (`limit: null` case) and only show the free-model daily limit.
   - `tierLabel`: something like `"Free tier"` if `is_free_tier` else
     `"Pay-as-you-go"` — cosmetic, don't overthink it.
4. Set up the same systemd oneshot+timer pair as Grok's, named
   `omarchy-agent-usage-openrouter.{service,timer}`, under
   `.config/systemd/user/` in this repo, symlinked into
   `~/.config/systemd/user/` and `systemctl --user enable --now`'d. Copy
   `omarchy-agent-usage-grok.timer`'s cadence (`OnStartupSec=15
   OnUnitActiveSec=900`).

   **Consider instead:** rather than a third (and future fourth, fifth...)
   near-identical systemd unit pair, it's worth generalizing to ONE runner
   script + ONE timer that loops over every executable in a
   `bin/omarchy-agent-usage-collectors.d/`-style directory (mirroring the
   *not-yet-merged* upstream PR #11967 that adds exactly this
   `~/.config/omarchy/agents/collectors/` concept to the official plugin).
   Not required for OpenRouter alone to work, but worth doing once there's a
   third provider, to stop the systemd-unit sprawl. Judgment call — do
   OpenRouter the simple way first if that's faster, refactor after if it
   starts to feel repetitive.
5. `systemctl --user start omarchy-agent-usage-openrouter.service` once,
   confirm `openrouter.json` lands with sane values, then `omarchy restart
   shell` and confirm the bar shows it (remember: hot-reload alone won't
   reliably show a *newly appearing* provider the first time — see the
   visibility-bug note above. A restart is the reliable way to verify).
6. No QML changes needed — Main.qml picks up the new file automatically.

## Task 2 — the "$30 Grok Business thing"

Adam mentioned having a flat-rate ~$30/month Grok plan that is **not** the
API/Console monthly spending limit that's currently blocking every billing
call (confirmed via `curl` this session: `cli-chat-proxy.grok.com` returns a
blanket 403 "reached its monthly spending limit" on `/v1/billing`,
`/v1/user`, everything — Adam confirmed in chat this really is happening,
not a bug on our end). He wasn't sure what the $30 plan actually is.

**What we know:**
- xAI's own Grok account clarified (via X, cited in chat) that there are two
  *separate* systems: the **SuperGrok subscription pool** (Settings → Usage
  in the Grok app/web UI; resets weekly; covers Grok Build CLI usage) versus
  the **API/Console spending limit** (prepaid credits or invoiced billing,
  Console → Billing → Credits). Adam said the browser "doesn't show anything
  either" — but it's worth double-checking *which* page he looked at. He may
  have only checked Console → Billing (the API side, which we already know
  is capped and unhelpful) rather than the Settings → Usage page (the
  subscription side, which is a different UI entirely and might actually
  show the $30 plan's own weekly reset countdown).
- No published, API-discoverable reset date exists for the monthly spending
  limit (checked `docs.x.ai/console/billing` and
  `docs.x.ai/console/faq/billing` directly — neither names a reset day).

**Plan:**

1. Ask Adam directly (don't guess): "When you check usage in a browser, is
   that at `console.x.ai` (Billing/Credits) or somewhere under
   `grok.com/settings` or the Grok app itself?" — these are different
   products with different data, and it changes what's actually knowable
   here.
2. If Adam has a SuperGrok subscription (the $30/mo thing) separate from the
   Team API account whose credits are exhausted, that subscription almost
   certainly has its OWN weekly usage pool, checkable either in the app UI or
   possibly via the *same* `~/.grok/auth.json` session once the current
   403 block clears (the collector already opportunistically calls
   `/v1/user?include=subscription` for `tierLabel` — once that call succeeds
   instead of 403ing, its response will likely reveal the actual plan name
   and may include subscription-specific usage fields worth adding as a
   second limit window on the same `grok` record).
3. **Rename/reframe regardless of the above:** the current `grok.json`
   record's one limit entry is labeled `"Weekly"` (borrowed from the
   community-PR terminology for the *subscription* pool), but it's actually
   reporting the **API/Console spending-limit block**, which is a different
   thing entirely and may not even be weekly (we don't know its cadence).
   Relabel it to something honest like `"API credits"` or `"Spending
   limit"` so it doesn't get confused with a real SuperGrok weekly pool if/
   when that becomes trackable too — see `bin/omarchy-agent-usage-grok`, the
   403 branch of `main()`.
4. Once it's clear which product the $30 plan is and whether it's
   API-observable at all, decide: is it worth a second limit window on the
   same Grok record, or is this fundamentally not machine-readable (in which
   case, say so plainly in the panel rather than guessing).

## Later, not urgent

- Adam wants this whole plugin eventually pushed to a clean, generic, public
  GitHub repo ("one day I'll be able to publish it") — his words suggest the
  *repo* could exist soon but the actual public *announcement*/publish step
  is for later. Worth a quick check-in on timing/visibility (public now vs.
  private-until-ready) before just pushing something world-readable.
  Whatever the answer, extracting `~/.config/omarchy/plugins/adam.agents/`
  into a standalone repo would also solve the "nothing here is
  version-controlled" problem above in one move — could make sense to do
  this *before* OpenRouter/Grok-Business, not after, so the new work lands
  in the real repo from the start instead of needing to be moved later.
  Ask Adam which order he'd rather do this in.
- `EST. COST TODAY` section in the popup is currently dead code for every
  real provider (only the old mock-data path ever set `estCostToday`) — either
  wire it up with real per-model pricing or remove it; leaving it as an
  always-invisible section is the kind of half-finished thing worth cleaning
  up once there's a natural moment.
- `bin/__pycache__/` should be deleted and `__pycache__/` added to
  `.gitignore` before any of this gets committed.

## Quick reference

```
# Live (untracked) plugin source:
~/.config/omarchy/plugins/adam.agents/{Panel.qml,manifest.json,Agent.qml,Main.qml}
~/.config/omarchy/shell.json                    # bar layout + this plugin's settings

# Tracked in devconfig (uncommitted):
bin/omarchy-agent-usage-grok
.config/systemd/user/omarchy-agent-usage-grok.{service,timer}

# Usage data both the panel and bar read (provider-agnostic, file-watched):
~/.local/state/omarchy/agents/usage/{claude,codex,fireworks,grok}.json

# Test a collector standalone:
~/dev/devconfig/bin/omarchy-agent-usage-grok && cat ~/.local/state/omarchy/agents/usage/grok.json | python3 -m json.tool

# Apply a QML/manifest edit:
omarchy restart shell   # NOT just editing-and-waiting — see visibility bug note above
journalctl --user --since "10 seconds ago" | grep -i error   # sanity check, ignore the
                                                              # harmless recurring "Handler
                                                              # was registered but will not
                                                              # be used" WARN spam and the
                                                              # portal-registration WARN

# Manage the Grok timer:
systemctl --user status omarchy-agent-usage-grok.timer
systemctl --user start omarchy-agent-usage-grok.service   # run it once, right now
```

No commits have been made for any of this yet — everything is sitting in the
working tree (and, for the plugin itself, entirely outside git). Commit only
when explicitly asked, per Adam's standing preference.
