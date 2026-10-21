// @ts-nocheck
// Switches the live OMP session model when the current one is usage-exhausted.
// Loaded by every OMP process, including ones Orca and Herdr spawn, so each
// session changes only its own model. Does not write modelRoles.default.
// 5xx and short rate limits stay on the current model and use OMP's own retry.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const QUOTA_RE =
  /insufficient[_\s-]?quota|billing[_\s-]?hard[_\s-]?limit|usage limit|quota exceeded|out of credits|run out of credits|spend(?:ing)? limit|payment_required|usage_limit_reached|resource_exhausted|credits exhausted|gousagelimiterror|freeusagelimiterror|monthly usage limit reached|available balance|out of budget/i;

export function isQuotaExhausted(message) {
  const text = String(message ?? "");
  if (!text || QUOTA_RE.test(text)) return Boolean(text);
  return /\b402\b/.test(text) && /payment|quota|billing|credit|usage|insufficient/i.test(text);
}

export function parseChain(text) {
  const order = [];
  let cooldownHours = 6;
  let inOrder = false;
  for (const raw of String(text ?? "").split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || line.startsWith("#")) continue;
    const hours = /^cooldownHours:\s*([0-9]+(?:\.[0-9]+)?)\s*$/.exec(line);
    if (hours) {
      cooldownHours = Number(hours[1]);
      inOrder = false;
      continue;
    }
    if (line === "order:") {
      inOrder = true;
      continue;
    }
    if (!inOrder) continue;
    const item = /^-\s+(\S+)\s*$/.exec(line);
    if (item) order.push(item[1]);
    else inOrder = false;
  }
  return {cooldownHours, order};
}

// Next chain entry after `current` that is not cooling down.
// An active model that is not in the chain starts at the first entry.
export function nextSelector(order, current, cooled) {
  const start = order.indexOf(current);
  const tail = start >= 0 ? order.slice(start + 1) : order;
  return tail.find((id) => id !== current && !cooled.has(id));
}

export function parseCooldownMs(message, now, fallbackMs) {
  const text = String(message ?? "");
  let match = /retry[- ]after[^0-9]{0,16}(\d+)/i.exec(text);
  if (match) return now + Number(match[1]) * 1000;
  match = /resets? in[^0-9]{0,12}(\d+)\s*h/i.exec(text);
  if (match) return now + Number(match[1]) * 3600 * 1000;
  match = /resets? in[^0-9]{0,12}(\d+)\s*m/i.exec(text);
  if (match) return now + Number(match[1]) * 60 * 1000;
  return now + fallbackMs;
}

function agentFile(name) {
  const root = process.env.OMP_FAILOVER_DIR || path.join(os.homedir(), ".omp", "agent");
  return path.join(root, name);
}

function selectorOf(model) {
  if (!model || typeof model === "string") return typeof model === "string" ? model : "";
  if (model.provider && model.id) return `${model.provider}/${model.id}`;
  return "";
}

function readCooldowns(now) {
  try {
    const parsed = JSON.parse(fs.readFileSync(agentFile("model-cooldowns.json"), "utf8"));
    const live = {};
    if (!parsed || typeof parsed !== "object") return live;
    for (const [id, until] of Object.entries(parsed)) {
      if (typeof until === "number" && until > now) live[id] = until;
    }
    return live;
  } catch {
    return {};
  }
}

function writeCooldowns(map) {
  const file = agentFile("model-cooldowns.json");
  fs.mkdirSync(path.dirname(file), {recursive: true});
  const tmp = `${file}.${process.pid}.tmp`;
  fs.writeFileSync(tmp, JSON.stringify(map), {mode: 0o600});
  fs.renameSync(tmp, file);
}

function remember(selector, until) {
  const map = readCooldowns(Date.now());
  map[selector] = until;
  writeCooldowns(map);
}

function forget(selector) {
  if (!selector) return;
  const map = readCooldowns(Date.now());
  if (map[selector] === undefined) return;
  delete map[selector];
  writeCooldowns(map);
}

function notify(ctx, text) {
  try {
    if (typeof ctx?.ui?.notify === "function") {
      ctx.ui.notify(text, "warning");
      return;
    }
  } catch {
    // A missing UI is not a failed hop.
  }
  console.error(`model-failover: ${text}`);
}

export default function modelFailover(pi) {
  let applying = false;
  let active = "";

  function currentSelector(ctx, event) {
    return (
      selectorOf(event?.model) ||
      (typeof event?.modelId === "string" ? event.modelId : "") ||
      selectorOf(ctx?.model) ||
      active
    );
  }

  async function applySelector(ctx, selector) {
    const models = ctx?.modelRegistry?.getAvailable?.() ?? [];
    const model = models.find((candidate) => selectorOf(candidate) === selector);
    if (!model || typeof pi.setModel !== "function") return false;
    applying = true;
    try {
      const result = await pi.setModel(model);
      if (result && result.success === false) return false;
      active = selector;
      try {
        if (ctx) ctx.model = model;
      } catch {
        // Some sessions expose a read-only model snapshot.
      }
      return true;
    } catch {
      return false;
    } finally {
      applying = false;
    }
  }

  async function hop(ctx, event, record) {
    if (applying) return;
    let chain;
    try {
      chain = parseChain(fs.readFileSync(agentFile("model-failover.yml"), "utf8"));
    } catch {
      return;
    }
    if (chain.order.length === 0) return;
    const current = currentSelector(ctx, event);
    if (!current) {
      notify(ctx, "usage exhausted; active model unknown, not switching");
      return;
    }
    if (record) {
      const until = parseCooldownMs(
        event?.errorMessage,
        Date.now(),
        chain.cooldownHours * 3600 * 1000,
      );
      remember(current, until);
    }
    const cooled = new Set(Object.keys(readCooldowns(Date.now())));
    let selector = nextSelector(chain.order, current, cooled);
    while (selector) {
      if (await applySelector(ctx, selector)) {
        notify(ctx, `usage exhausted on ${current}; switched to ${selector}`);
        return;
      }
      cooled.add(selector);
      const from = chain.order.indexOf(selector);
      const rest = from >= 0 ? chain.order.slice(from + 1) : [];
      selector = rest.find((id) => id !== current && !cooled.has(id));
    }
    notify(ctx, `usage exhausted on ${current}; no fallback model available`);
  }

  pi.on("model_select", (event, ctx) => {
    const selected = currentSelector(ctx, event);
    if (selected) active = selected;
    if (!applying) forget(selected);
  });

  pi.on("session_start", async (event, ctx) => {
    const current = currentSelector(ctx, event);
    if (current) active = current;
    if (!current || readCooldowns(Date.now())[current] === undefined) return;
    await hop(ctx, event, false);
  });

  pi.on("auto_retry_start", async (event, ctx) => {
    if (!isQuotaExhausted(event?.errorMessage)) return;
    await hop(ctx, event, true);
  });
}
