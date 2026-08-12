/**
 * model-fallback.ts — pi extension
 *
 * Automatically falls back to the next model in a configured chain when the
 * current model is rate limited, overloaded, or out of quota.
 *
 * HOW IT WORKS
 * ------------
 * - HTTP-level detection via `after_provider_response`: a status in
 *   `statusCodes` (default 429/503/529) triggers a fallback.
 * - Message-level detection via `agent_end`: the last assistant message is an
 *   error whose text matches rate-limit/quota patterns (controlled by
 *   `triggerOn`). This is the primary path in practice — pi's stream layer
 *   converts non-2xx responses into error messages without firing
 *   `after_provider_response` — and it also covers providers that hide HTTP
 *   status, plus "out of quota / free tier exhausted" errors that a plain
 *   429 check would miss.
 * - The switch happens BEFORE pi's built-in exponential-backoff retry, so the
 *   automatic retry runs on the fallback model instead of the throttled one.
 * - Only ONE chain slot is consumed per turn (`switchedThisTurn`), so a burst
 *   of 429s drains the chain one model at a time instead of burning it all in
 *   a single request.
 * - `fallbackMode: "advance"` (default) steps down the chain permanently for
 *   the session. `fallbackMode: "cycle"` reverts to the original model after
 *   `cooldownMs` if nothing else changed.
 *
 * NOTES
 * -----
 * - `pi.setModel()` is used for the switch, so the fallback model also becomes
 *   the persistent default provider/model in settings.json (new sessions start
 *   on the fallback until changed or `/model-fallback reset`).
 * - `setModel` is not subject to the `enabledModels` cycling scoping, so chain
 *   entries may include models outside that list.
 *
 * CONFIG
 * ------
 * File: <agent-dir>/model-fallback.json
 *       (default: ~/.pi/agent/model-fallback.json; agent dir can be
 *        overridden with $PI_CODING_AGENT_DIR)
 *
 *   {
 *     "enabled": true,
 *     "fallbackMode": "advance",            // "advance" | "cycle"
 *     "cooldownMs": 60000,                  // cycle-mode revert delay
 *     "statusCodes": [429, 503, 529],       // HTTP statuses that trigger
 *     "triggerOn": "rate-limit",            // "rate-limit" | "retryable" | "any-error"
 *     "chain": [
 *       "opencode-go/deepseek-v4-flash",    // "provider/model"
 *       "deepseek-v4-pro"                   // bare id = same provider as current model
 *     ]
 *   }
 *
 * COMMANDS
 * --------
 *   /model-fallback               show chain + status
 *   /model-fallback set <...>     replace the chain (persists to the config file)
 *   /model-fallback reset         switch back to the first chain entry
 *   /model-fallback enable|disable
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { getAgentDir } from "@earendil-works/pi-coding-agent";
import type { AutocompleteItem } from "@earendil-works/pi-tui";
import type { Model } from "@earendil-works/pi-ai";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

// isRetryableAssistantError ships at runtime in the pi-ai compat entrypoint but
// is not in its public .d.ts — import it defensively.
import * as piAi from "@earendil-works/pi-ai";
const isRetryableAssistantError = (piAi as unknown as {
  isRetryableAssistantError: (message: {
    stopReason?: string;
    errorMessage?: string;
  }) => boolean;
}).isRetryableAssistantError;

// ────────────────────────────────────────────────────────────────────────────
// Types & config
// ────────────────────────────────────────────────────────────────────────────

interface ChainEntry {
  provider?: string;
  model: string;
}

interface FallbackConfig {
  enabled: boolean;
  fallbackMode: "advance" | "cycle";
  cooldownMs: number;
  statusCodes: number[];
  triggerOn: "rate-limit" | "retryable" | "any-error";
  chain: ChainEntry[];
}

interface AssistantErrorShape {
  role?: string;
  stopReason?: string;
  errorMessage?: string;
}

const DEFAULT_CONFIG: FallbackConfig = {
  enabled: true,
  fallbackMode: "advance",
  cooldownMs: 60_000,
  statusCodes: [429, 503, 529],
  triggerOn: "rate-limit",
  chain: normalizeChain(["opencode-go/deepseek-v4-flash", "opencode-go/deepseek-v4-pro"]),
};

const CONFIG_FILE = join(getAgentDir(), "model-fallback.json");

// Matches rate limiting, overloads, and quota/free-tier exhaustion. The quota
// half intentionally overlaps the "runs out" case from opencode-n style setups
// (e.g. "FreeUsageLimitError", "insufficient_quota", "available balance").
const FALLBACK_ERROR_PATTERN =
  /rate.?limit|too many requests|429|overloaded|resource.?exhausted|quota|insufficient_quota|out of budget|available balance|usage.?limit|limit reached|billing|free.?tier/i;

// ────────────────────────────────────────────────────────────────────────────
// State
// ────────────────────────────────────────────────────────────────────────────

let config: FallbackConfig = loadConfig();
let chain: ChainEntry[] = config.chain;
let switchedThisTurn = false;
let warnedNotInChain = false;
let lastKnownModel: { provider: string; id: string } | undefined;
let cycleTimer: ReturnType<typeof setTimeout> | undefined;

// ExtensionAPI is only available inside the factory; module-level handlers
// (tryFallback, cycle-revert timers) capture it here once the factory runs.
let api: ExtensionAPI | undefined;

// ────────────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────────────

function normalizeChain(raw: Array<string | ChainEntry>): ChainEntry[] {
  return (Array.isArray(raw) ? raw : [])
    .map((entry): ChainEntry => {
      if (typeof entry === "string") {
        const s = entry.trim();
        const slash = s.indexOf("/");
        if (slash > 0 && slash < s.length - 1) {
          return { provider: s.slice(0, slash), model: s.slice(slash + 1) };
        }
        return { model: s };
      }
      if (entry && typeof entry === "object") {
        return { provider: entry.provider, model: String(entry.model ?? "").trim() };
      }
      return { model: "" };
    })
    .filter((e) => e.model.length > 0);
}

function loadConfig(): FallbackConfig {
  const cfg: FallbackConfig = {
    ...DEFAULT_CONFIG,
    chain: [...DEFAULT_CONFIG.chain],
  };
  try {
    if (existsSync(CONFIG_FILE)) {
      const raw = JSON.parse(readFileSync(CONFIG_FILE, "utf8")) as Partial<FallbackConfig>;
      if (typeof raw.enabled === "boolean") cfg.enabled = raw.enabled;
      if (raw.fallbackMode === "advance" || raw.fallbackMode === "cycle") {
        cfg.fallbackMode = raw.fallbackMode;
      }
      if (typeof raw.cooldownMs === "number" && raw.cooldownMs >= 0) {
        cfg.cooldownMs = raw.cooldownMs;
      }
      if (Array.isArray(raw.statusCodes)) {
        cfg.statusCodes = raw.statusCodes.filter((n): n is number => typeof n === "number");
      }
      if (
        raw.triggerOn === "rate-limit" ||
        raw.triggerOn === "retryable" ||
        raw.triggerOn === "any-error"
      ) {
        cfg.triggerOn = raw.triggerOn;
      }
      if (Array.isArray(raw.chain)) cfg.chain = normalizeChain(raw.chain);
    }
  } catch (err) {
    console.error(`[model-fallback] failed to load ${CONFIG_FILE}:`, err);
  }
  return cfg;
}

function persistConfig() {
  try {
    writeFileSync(CONFIG_FILE, JSON.stringify({ ...config, chain }, null, 2) + "\n");
  } catch (err) {
    console.error(`[model-fallback] failed to write ${CONFIG_FILE}:`, err);
  }
}

function keyOf(m: { provider: string; id: string }): string {
  return `${m.provider}/${m.id}`;
}

function labelOf(entry: ChainEntry): string {
  return entry.provider ? `${entry.provider}/${entry.model}` : entry.model;
}

/** Resolve a chain entry to a concrete model. Bare ids prefer the active provider. */
function resolveChainEntry(
  ctx: ExtensionContext,
  entry: ChainEntry,
  activeProvider?: string,
): Model | undefined {
  if (entry.provider) {
    return ctx.modelRegistry.find(entry.provider, entry.model);
  }
  if (activeProvider) {
    const m = ctx.modelRegistry.find(activeProvider, entry.model);
    if (m) return m;
  }
  return ctx.modelRegistry.getAvailable().find((m) => m.id === entry.model);
}

/** Index of the active model within the chain, or -1 if not in the chain. */
function chainIndexOf(
  ctx: ExtensionContext,
  active: { provider: string; id: string },
): number {
  for (let i = 0; i < chain.length; i++) {
    const m = resolveChainEntry(ctx, chain[i], active.provider);
    if (m && m.provider === active.provider && m.id === active.id) return i;
  }
  return -1;
}

function isFallbackError(message: AssistantErrorShape): boolean {
  if (!message || message.stopReason !== "error" || !message.errorMessage) return false;
  switch (config.triggerOn) {
    case "retryable":
      return isRetryableAssistantError({
        stopReason: message.stopReason,
        errorMessage: message.errorMessage,
      });
    case "any-error":
      return true;
    case "rate-limit":
    default:
      return FALLBACK_ERROR_PATTERN.test(message.errorMessage);
  }
}

function lastAssistantMessage(messages: AssistantErrorShape[]): AssistantErrorShape | undefined {
  for (let i = messages.length - 1; i >= 0; i--) {
    if (messages[i].role === "assistant") return messages[i];
  }
  return undefined;
}

function syncStatus(ctx: ExtensionContext) {
  if (!config.enabled || !lastKnownModel) {
    ctx.ui.setStatus("model-fallback", undefined);
    return;
  }
  const idx = chainIndexOf(ctx, lastKnownModel);
  ctx.ui.setStatus(
    "model-fallback",
    idx >= 0
      ? `⇥ ${lastKnownModel.id} (chain ${idx + 1}/${chain.length})`
      : `⇥ ${lastKnownModel.id}`,
  );
}

// ────────────────────────────────────────────────────────────────────────────
// Fallback logic
// ────────────────────────────────────────────────────────────────────────────

async function tryFallback(ctx: ExtensionContext, reason: string) {
  if (!config.enabled || chain.length === 0) return;
  if (switchedThisTurn) return; // one slot per turn — drains gradually

  const active = ctx.model;
  if (!active) return;
  lastKnownModel = { provider: active.provider, id: active.id };

  const idx = chainIndexOf(ctx, active);
  if (idx < 0) {
    if (!warnedNotInChain) {
      warnedNotInChain = true;
      ctx.ui.notify(
        `model-fallback: ${keyOf(active)} is not in the fallback chain — configure with /model-fallback set`,
        "info",
      );
    }
    return;
  }

  const nextEntry = chain[idx + 1];
  if (!nextEntry) {
    ctx.ui.notify(
      `model-fallback: chain exhausted — ${keyOf(active)} is the last model`,
      "warning",
    );
    return;
  }

  const nextModel = resolveChainEntry(ctx, nextEntry, active.provider);
  if (!nextModel) {
    ctx.ui.notify(
      `model-fallback: fallback model "${labelOf(nextEntry)}" is not available`,
      "error",
    );
    return;
  }

  const prevKey = keyOf(active);
  const ok = await api!.setModel(nextModel);
  if (!ok) {
    ctx.ui.notify(`model-fallback: no API key for ${keyOf(nextModel)}`, "error");
    return;
  }

  switchedThisTurn = true;
  ctx.ui.setStatus("model-fallback", `⇥ ${active.id} → ${nextModel.id}`);

  if (config.fallbackMode === "cycle") {
    scheduleCycleRevert(active, keyOf(nextModel), ctx);
  }

  ctx.ui.notify(
    `model-fallback: ${reason} on ${prevKey} — switched to ${keyOf(nextModel)}`,
    "warning",
  );
}

function scheduleCycleRevert(prevModel: Model, fallbackKey: string, ctx: ExtensionContext) {
  if (cycleTimer) clearTimeout(cycleTimer);
  cycleTimer = setTimeout(() => {
    cycleTimer = undefined;
    void doCycleRevert(prevModel, fallbackKey, ctx);
  }, Math.max(config.cooldownMs, 1_000));
}

async function doCycleRevert(prevModel: Model, fallbackKey: string, ctx: ExtensionContext) {
  try {
    if (lastKnownModel && keyOf(lastKnownModel) !== fallbackKey) return; // user moved on
    if (!ctx.isIdle()) return; // don't yank the model mid-run
    const ok = await api!.setModel(prevModel);
    if (ok) {
      ctx.ui.notify(`model-fallback: cooldown elapsed — restored ${keyOf(prevModel)}`, "info");
    }
  } catch {
    // ctx may be stale after a session switch — ignore
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Extension
// ────────────────────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  api = pi;

  pi.on("session_start", async (_event, ctx) => {
    switchedThisTurn = false;
    warnedNotInChain = false;
    if (ctx.model) {
      lastKnownModel = { provider: ctx.model.provider, id: ctx.model.id };
    }
    syncStatus(ctx);
  });

  pi.on("turn_start", async () => {
    switchedThisTurn = false;
  });

  pi.on("model_select", async (event, ctx) => {
    lastKnownModel = { provider: event.model.provider, id: event.model.id };
    syncStatus(ctx);
  });

  pi.on("after_provider_response", async (event, ctx) => {
    if (!config.enabled) return;
    if (config.statusCodes.includes(event.status)) {
      await tryFallback(ctx, `HTTP ${event.status}`);
    }
  });

  pi.on("agent_end", async (event, ctx) => {
    if (!config.enabled) return;
    const last = lastAssistantMessage(event.messages as AssistantErrorShape[]);
    if (last && isFallbackError(last)) {
      await tryFallback(ctx, "provider error");
    }
  });

  pi.on("session_shutdown", () => {
    if (cycleTimer) {
      clearTimeout(cycleTimer);
      cycleTimer = undefined;
    }
  });

  pi.registerCommand("model-fallback", {
    description: "Inspect or configure the model fallback chain (rate-limit fallback)",
    getArgumentCompletions(prefix: string): AutocompleteItem[] | null {
      const sub = prefix.trim().split(/\s+/)[0] ?? "";
      const items = ["status", "reset", "set", "enable", "disable"].map((v) => ({
        value: v,
        label: v,
      }));
      const filtered = items.filter((i) => i.value.startsWith(sub));
      return filtered.length > 0 ? filtered : null;
    },
    handler: async (args, ctx) => {
      const parts = args.trim().split(/\s+/).filter(Boolean);
      const [cmd, ...rest] = parts;

      switch (cmd) {
        case "reset": {
          if (chain.length === 0) {
            ctx.ui.notify("model-fallback: no chain configured", "info");
            return;
          }
          const target = resolveChainEntry(ctx, chain[0]);
          if (!target) {
            ctx.ui.notify(`model-fallback: "${labelOf(chain[0])}" is not available`, "error");
            return;
          }
          const ok = await pi.setModel(target);
          ctx.ui.notify(
            ok
              ? `model-fallback: switched back to ${keyOf(target)}`
              : `model-fallback: no API key for ${keyOf(target)}`,
            ok ? "info" : "error",
          );
          return;
        }

        case "set": {
          if (rest.length === 0) {
            ctx.ui.notify("usage: /model-fallback set provider/model ...", "info");
            return;
          }
          const newChain = normalizeChain(rest);
          if (newChain.length === 0) {
            ctx.ui.notify("model-fallback: no valid entries in chain", "error");
            return;
          }
          const missing = newChain.filter((e) => !resolveChainEntry(ctx, e));
          chain = newChain;
          config.chain = newChain;
          persistConfig();
          syncStatus(ctx);
          ctx.ui.notify(
            missing.length > 0
              ? `model-fallback: chain saved (${newChain.length}); unresolvable: ${missing
                  .map(labelOf)
                  .join(", ")}`
              : `model-fallback: chain saved — ${newChain.map(labelOf).join(" → ")}`,
            missing.length > 0 ? "warning" : "info",
          );
          return;
        }

        case "enable": {
          config.enabled = true;
          persistConfig();
          syncStatus(ctx);
          ctx.ui.notify("model-fallback: enabled", "info");
          return;
        }

        case "disable": {
          config.enabled = false;
          persistConfig();
          ctx.ui.setStatus("model-fallback", undefined);
          ctx.ui.notify("model-fallback: disabled", "info");
          return;
        }

        default: {
          const active = ctx.model;
          let msg = `model-fallback: ${config.enabled ? "enabled" : "disabled"} (${config.fallbackMode})`;
          if (chain.length === 0) msg += " — no chain configured";
          if (active) {
            const idx = chainIndexOf(ctx, active);
            msg += `\nactive: ${keyOf(active)}${
              idx >= 0 ? ` (chain position ${idx + 1}/${chain.length})` : " (not in chain)"
            }`;
          }
          msg += `\nchain: ${chain.map(labelOf).join(" → ") || "(empty)"}`;
          msg += `\ntrigger: HTTP ${config.statusCodes.join("/")}, triggerOn=${config.triggerOn}`;
          if (config.fallbackMode === "cycle") msg += `, cooldown=${config.cooldownMs}ms`;
          msg += `\nconfig: ${CONFIG_FILE}`;
          ctx.ui.notify(msg, "info");
          return;
        }
      }
    },
  });
}
