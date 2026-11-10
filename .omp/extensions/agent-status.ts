// zellij-agent-status v0.1.8
// omp (oh-my-pi coding agent) extension: drive zellij-agent-status tab badges.
//
// Claude Code and Grok reach the plugin through hooks in ~/.claude/settings.json,
// which omp never executes. This extension maps omp's own events onto the same
// hook script, so the script's guards (non-Zellij no-op, plugin pin file,
// `timeout 2`) apply unchanged.
//
// Written to ~/.omp/agent/extensions/agent-status.ts by the plugin on first
// load, and rewritten when the plugin version changes: edits here are lost.
// No imports on purpose: bare subpath imports do not resolve from ~/.omp/,
// and `pi` only needs `on`.

type State = "working" | "waiting" | "done" | "end";

const HOOK = `${process.env.HOME}/.config/zellij/agent-status-hook.sh`;

export default function (pi: any) {
	// Outside Zellij there is no tab to badge; register nothing.
	if (!process.env.ZELLIJ || !process.env.ZELLIJ_PANE_ID) return;

	// One hook process at a time, in event order: a slow `working` must never
	// land after the `done` that followed it.
	let queue: Promise<unknown> = Promise.resolve();

	const send = (ctx: any, state: State): Promise<unknown> => {
		// Extensions are rebound to every subagent session, and subagents share
		// this pane's ZELLIJ_PANE_ID. Only the top-level agent owns the badge.
		if (ctx?.agent?.kind && ctx.agent.kind !== "main") return queue;
		queue = queue.then(async () => {
			try {
				const proc = Bun.spawn([HOOK, state], {
					stdin: "ignore",
					stdout: "ignore",
					stderr: "ignore",
				});
				await proc.exited;
			} catch {
				// Missing hook script or spawn failure: badges are best-effort.
			}
		});
		return queue;
	};

	// Handlers return nothing, so omp never waits on the hook (fire and forget).
	pi.on("before_agent_start", (_e: any, ctx: any) => {
		send(ctx, "working");
	});
	pi.on("tool_execution_start", (e: any, ctx: any) => {
		// The `ask` tool blocks on the user, with no approval event of its own.
		if (e?.toolName === "ask") send(ctx, "waiting");
	});
	pi.on("tool_execution_end", (_e: any, ctx: any) => {
		send(ctx, "working");
	});
	pi.on("tool_approval_requested", (_e: any, ctx: any) => {
		send(ctx, "waiting");
	});
	pi.on("tool_approval_resolved", (_e: any, ctx: any) => {
		send(ctx, "working");
	});
	pi.on("agent_end", (e: any, ctx: any) => {
		// willContinue: omp is about to start another run (queued message, loop).
		if (e?.willContinue) return;
		send(ctx, "done");
	});
	// Awaited so the badge clears before the process exits (omp caps this at 2s).
	pi.on("session_shutdown", (_e: any, ctx: any) => send(ctx, "end"));
}
