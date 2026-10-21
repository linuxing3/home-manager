import {expect, test} from "bun:test";
import {mkdtempSync, readFileSync, writeFileSync} from "node:fs";
import {tmpdir} from "node:os";
import {join} from "node:path";
import * as failover from "./model-failover.ts";

const chainText = readFileSync(new URL("./model-failover.yml", import.meta.url));

function isolate() {
  const dir = mkdtempSync(join(tmpdir(), "omp-failover-"));
  process.env.OMP_FAILOVER_DIR = dir;
  writeFileSync(join(dir, "model-failover.yml"), chainText);
  return dir;
}

test("quota wording switches and short rate limits do not", () => {
  expect(failover.isQuotaExhausted("usage limit exceeded")).toBe(true);
  expect(failover.isQuotaExhausted("insufficient_quota")).toBe(true);
  expect(failover.isQuotaExhausted("billing_hard_limit_reached")).toBe(true);
  expect(failover.isQuotaExhausted("quota exceeded")).toBe(true);
  expect(failover.isQuotaExhausted("out of credits")).toBe(true);
  expect(failover.isQuotaExhausted("spend limit reached")).toBe(true);
  expect(failover.isQuotaExhausted("payment_required")).toBe(true);
  expect(failover.isQuotaExhausted("resource_exhausted")).toBe(true);
  expect(failover.isQuotaExhausted("Monthly usage limit reached")).toBe(true);
  expect(failover.isQuotaExhausted("FreeUsageLimitError: plan")).toBe(true);
  expect(failover.isQuotaExhausted("HTTP 402 payment required")).toBe(true);
  expect(failover.isQuotaExhausted("429 Too Many Requests")).toBe(false);
  expect(failover.isQuotaExhausted("rate limit exceeded")).toBe(false);
  expect(failover.isQuotaExhausted("500 internal server error")).toBe(false);
  expect(failover.isQuotaExhausted("502 bad gateway")).toBe(false);
  expect(failover.isQuotaExhausted("")).toBe(false);
  expect(failover.isQuotaExhausted(null)).toBe(false);
});

test("the chain walks forward and skips cooled-down ids", () => {
  const chain = failover.parseChain(chainText.toString());
  const order = chain.order;
  expect(order).toEqual([
    "magpie/grok/grok-4.7",
    "magpie/grok/grok-4.6",
    "magpie/deepseek/deepseek-v4-pro",
  ]);
  expect(failover.nextSelector(order, order[0], new Set())).toBe(order[1]);
  expect(failover.nextSelector(order, order[0], new Set([order[1]]))).toBe(order[2]);
  expect(failover.nextSelector(order, order[2], new Set())).toBeUndefined();
  expect(failover.nextSelector(order, "magpie/other", new Set())).toBe(order[0]);
  expect(chain.cooldownHours).toBe(6);
});

test("a reset hint beats the default cooldown", () => {
  const now = 1_000_000;
  expect(failover.parseCooldownMs("usage limit, retry after 120 seconds", now, 99)).toBe(now + 120_000);
  expect(failover.parseCooldownMs("resets in 2 hours", now, 99)).toBe(now + 7_200_000);
  expect(failover.parseCooldownMs("usage limit", now, 50)).toBe(now + 50);
});

function session() {
  const notes = [];
  const models = [
    {provider: "magpie", id: "grok/grok-4.7"},
    {provider: "magpie", id: "grok/grok-4.6"},
    {provider: "magpie", id: "deepseek/deepseek-v4-pro"},
  ];
  const ctx = {
    model: models[0],
    modelRegistry: {getAvailable: () => models},
    ui: {notify: (text) => notes.push(text)},
  };
  const pi = {
    handlers: {},
    on(name, fn) {
      this.handlers[name] = fn;
    },
    async setModel(model) {
      ctx.model = model;
      return {success: true};
    },
  };
  failover.default(pi);
  return {pi, ctx, notes, models};
}

test("a quota retry hops once and a 5xx retry does not", async () => {
  const dir = isolate();
  const {pi, ctx, notes} = session();
  await pi.handlers.auto_retry_start({errorMessage: "500 internal server error"}, ctx);
  expect(ctx.model.id).toBe("grok/grok-4.7");
  expect(notes).toEqual([]);

  await pi.handlers.auto_retry_start({errorMessage: "usage limit exceeded"}, ctx);
  expect(`${ctx.model.provider}/${ctx.model.id}`).toBe("magpie/grok/grok-4.6");
  expect(notes[0]).toContain("switched to magpie/grok/grok-4.6");
  const cooled = JSON.parse(readFileSync(join(dir, "model-cooldowns.json"), "utf8"));
  expect(cooled["magpie/grok/grok-4.7"]).toBeGreaterThan(Date.now());
});

test("the next exhaustion skips a model that is still cooling down", async () => {
  isolate();
  const {pi, ctx} = session();
  await pi.handlers.auto_retry_start({errorMessage: "usage limit exceeded"}, ctx);
  await pi.handlers.auto_retry_start({errorMessage: "quota exceeded"}, ctx);
  expect(`${ctx.model.provider}/${ctx.model.id}`).toBe("magpie/deepseek/deepseek-v4-pro");
});

test("the end of the chain does not wrap", async () => {
  isolate();
  const {pi, ctx, notes, models} = session();
  ctx.model = models[2];
  pi.handlers.model_select({model: models[2]}, ctx);
  await pi.handlers.auto_retry_start({errorMessage: "out of credits"}, ctx);
  expect(ctx.model.id).toBe("deepseek/deepseek-v4-pro");
  expect(notes.at(-1)).toContain("no fallback model available");
});

test("a manual model select clears that model's cooldown", async () => {
  const dir = isolate();
  const {pi, ctx, models} = session();
  await pi.handlers.auto_retry_start({errorMessage: "usage limit exceeded"}, ctx);
  pi.handlers.model_select({model: models[0]}, ctx);
  ctx.model = models[0];
  const cooled = JSON.parse(readFileSync(join(dir, "model-cooldowns.json"), "utf8"));
  expect(cooled["magpie/grok/grok-4.7"]).toBeUndefined();
  await pi.handlers.session_start({model: models[0]}, ctx);
  expect(`${ctx.model.provider}/${ctx.model.id}`).toBe("magpie/grok/grok-4.7");
});

test("a new session skips a model that is still cooling down", async () => {
  isolate();
  const first = session();
  await first.pi.handlers.auto_retry_start({errorMessage: "usage limit exceeded"}, first.ctx);
  const next = session();
  next.ctx.model = next.models[0];
  await next.pi.handlers.session_start({model: next.models[0]}, next.ctx);
  expect(`${next.ctx.model.provider}/${next.ctx.model.id}`).toBe("magpie/grok/grok-4.6");
});
