const DEDUP_TTL = 600;
const enc = new TextEncoder();

async function safeEqual(a, b) {
  if (typeof a !== "string" || typeof b !== "string" || !a || !b) return false;
  const [x, y] = await Promise.all([
    crypto.subtle.digest("SHA-256", enc.encode(a)),
    crypto.subtle.digest("SHA-256", enc.encode(b))
  ]);
  return crypto.subtle.timingSafeEqual(x, y);
}

function json(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" }
  });
}

function titleOf(page) {
  const props = page?.properties || {};
  const title = props["Task name"] || Object.values(props).find((p) => p?.type === "title");
  const parts = title?.title || title?.rich_text || [];
  return parts.map((t) => t.plain_text ?? t.text?.content ?? "").join("");
}

function statusOf(page) {
  const s = page?.properties?.Status;
  return s?.select?.name ?? s?.status?.name ?? null;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method !== "POST" || url.pathname !== "/notion") {
      return json(404, { ok: false });
    }
    if (!(await safeEqual(request.headers.get("x-omp-hook-secret"), env.NOTION_HOOK_SECRET))) {
      return json(401, { ok: false });
    }

    let payload;
    try {
      payload = await request.json();
    } catch {
      return json(400, { ok: false, error: "bad_json" });
    }
    const page = payload?.data ?? payload;
    const pageId = String(page?.id || "").replace(/-/g, "");
    if (!/^[0-9a-f]{32}$/.test(pageId)) {
      return json(400, { ok: false, error: "no_page_id" });
    }
    const title = titleOf(page);
    const status = statusOf(page);
    if (title && !title.startsWith(env.TITLE_PREFIX)) {
      return json(200, { ok: true, skipped: "prefix" });
    }
    if (status && status !== "Not started") {
      return json(200, { ok: true, skipped: "status" });
    }

    const dedupKey = `dedup:${pageId}`;
    if (await env.OMP_HOOK_STATE.get(dedupKey)) {
      return json(200, { ok: true, skipped: "duplicate" });
    }
    await env.OMP_HOOK_STATE.put(dedupKey, "1", { expirationTtl: DEDUP_TTL });

    const headers = {
      "content-type": "application/json",
      "x-omp-hook-key": env.OMP_LOCAL_KEY
    };
    if (env.CF_ACCESS_CLIENT_ID && env.CF_ACCESS_CLIENT_SECRET) {
      headers["CF-Access-Client-Id"] = env.CF_ACCESS_CLIENT_ID;
      headers["CF-Access-Client-Secret"] = env.CF_ACCESS_CLIENT_SECRET;
    }
    let upstream;
    try {
      upstream = await fetch(env.UPSTREAM_URL, {
        method: "POST",
        headers,
        body: JSON.stringify({
          page_id: pageId,
          url: `https://www.notion.so/${pageId}`,
          title,
          event_id: payload?.source?.event_id ?? null
        })
      });
    } catch (err) {
      await env.OMP_HOOK_STATE.delete(dedupKey);
      console.log(JSON.stringify({ event: "upstream_error", pageId, error: String(err) }));
      return json(502, { ok: false, error: "upstream_unreachable" });
    }
    console.log(JSON.stringify({ event: "forwarded", pageId, upstream: upstream.status }));
    if (!upstream.ok) {
      await env.OMP_HOOK_STATE.delete(dedupKey);
      return json(502, { ok: false, upstream: upstream.status });
    }
    return json(200, { ok: true, forwarded: pageId });
  }
};
