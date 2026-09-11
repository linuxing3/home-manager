const ORIGIN = "https://pintor.efwmcapp.com";
const COMPANY = "EFWMC";
const APP_NAME = "EFWMC Pintor";
const CALLBACK = `${ORIGIN}/oauth/callback`;
const SCOPES = "user_accounts:read,boards:read,pins:read";

const CSS = `
:root { color-scheme: light; --ink:#1b1b1b; --muted:#5c5c5c; --line:#e6e1d8; --bg:#f7f4ee; --card:#fff; --accent:#bd081c; --ok:#0b7a3b; }
* { box-sizing: border-box; }
body { margin:0; font:16px/1.55 ui-sans-serif,system-ui,sans-serif; color:var(--ink); background:var(--bg); }
header, main, footer { max-width: 52rem; margin: 0 auto; padding: 1.15rem 1.25rem; }
header { display:flex; justify-content:space-between; align-items:baseline; gap:1rem; }
a { color:var(--accent); }
nav a { margin-right: 0.85rem; text-decoration:none; }
.card { background:var(--card); border:1px solid var(--line); border-radius:12px; padding:1.25rem 1.4rem; }
code, .mono { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: .92em; word-break: break-all; }
h1 { font-size: 1.7rem; margin: 0 0 .55rem; }
h2 { font-size: 1.12rem; margin: 1.25rem 0 .4rem; }
.muted { color: var(--muted); }
ul { padding-left: 1.2rem; }
footer { color: var(--muted); font-size: .9rem; }
.banner { background:#fff3c4; border:1px solid #ead38a; border-radius:10px; padding:.7rem .9rem; margin:0 0 1rem; font-weight:600; }
.ok { color: var(--ok); font-weight: 650; }
.btn { display:inline-block; background:var(--accent); color:#fff; text-decoration:none; border:0; border-radius:10px; padding:.7rem 1.1rem; font-weight:650; cursor:pointer; }
.btn.secondary { background:#fff; color:var(--accent); border:1px solid var(--accent); }
.grid { display:grid; gap:.75rem; }
@media (min-width: 720px) { .grid.two { grid-template-columns: 1fr 1fr; } }
.tile { border:1px solid var(--line); border-radius:10px; padding:.75rem .85rem; background:#fff; }
.thumb { width:100%; height:140px; object-fit:cover; border-radius:8px; background:#eee; }
.step { font-size:.92rem; color:var(--muted); margin:0 0 1rem; }
label { display:block; font-weight:650; margin:.7rem 0 .25rem; }
input, textarea, select { width:100%; padding:.55rem .65rem; border:1px solid var(--line); border-radius:8px; font:inherit; }
`;

const LAYOUT = (title, body) => `<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(title)} · ${COMPANY}</title>
  <meta name="description" content="EFWMC Pintor authenticates a Pinterest business account with OAuth and manages studio boards and Pins.">
  <style>${CSS}</style>
</head>
<body>
  <header>
    <strong>${COMPANY} Pintor</strong>
    <nav>
      <a href="/">Studio</a>
      <a href="/oauth/start">Connect</a>
      <a href="/privacy">Privacy</a>
      <a href="/terms">Terms</a>
    </nav>
  </header>
  <main class="card">${body}</main>
  <footer>Hosted by ${COMPANY} on efwmcapp.com · Pinterest OAuth redirect ${CALLBACK}</footer>
</body>
</html>`;

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function html(title, body, status = 200, headers = {}) {
  return new Response(LAYOUT(title, body), {
    status,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store",
      "x-content-type-options": "nosniff",
      ...headers,
    },
  });
}

function randomState() {
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  return [...bytes].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function clientId(env) {
  return env.PINTEREST_CLIENT_ID || "1608367";
}

function parseCookies(request) {
  const raw = request.headers.get("cookie") || "";
  const out = {};
  for (const part of raw.split(";")) {
    const idx = part.indexOf("=");
    if (idx === -1) continue;
    out[part.slice(0, idx).trim()] = decodeURIComponent(part.slice(idx + 1).trim());
  }
  return out;
}

function cookie(name, value, extra = "HttpOnly; Secure; SameSite=Lax; Path=/") {
  return `${name}=${encodeURIComponent(value)}; ${extra}`;
}

function oauthAuthorizeUrl(env, state) {
  const url = new URL("https://www.pinterest.com/oauth/");
  url.searchParams.set("client_id", clientId(env));
  url.searchParams.set("redirect_uri", CALLBACK);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", SCOPES);
  url.searchParams.set("state", state);
  return url.toString();
}

async function exchangeCode(env, code) {
  const secret = env.PINTEREST_CLIENT_SECRET;
  if (!secret) throw new Error("missing_client_secret");
  const basic = btoa(`${clientId(env)}:${secret}`);
  const body = new URLSearchParams({
    grant_type: "authorization_code",
    code,
    redirect_uri: CALLBACK,
  });
  const res = await fetch("https://api.pinterest.com/v5/oauth/token", {
    method: "POST",
    headers: {
      Authorization: `Basic ${basic}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body,
  });
  const data = await res.json();
  if (!res.ok || !data.access_token) {
    throw new Error(data.message || data.error || `token_http_${res.status}`);
  }
  return data;
}

async function pinterestGet(token, path) {
  const res = await fetch(`https://api.pinterest.com/v5${path}`, {
    headers: {Authorization: `Bearer ${token}`, Accept: "application/json"},
  });
  const data = await res.json();
  return {ok: res.ok, status: res.status, data};
}

function homePage(connected) {
  return html(
    APP_NAME,
    `
  <div class="banner">步骤 1 · 认证 Pinterest 用户：点击「用 Pinterest 连接」打开官方 OAuth 授权页</div>
  <p class="step">EFWMC Pintor uses Pinterest OAuth 2.0 only. It never asks for your Pinterest password.</p>
  <h1>${APP_NAME}</h1>
  <p>EFWMC 工作室用这个应用连接 Pinterest 商务账号，读取图板和 Pin，并准备发布微距静物内容。</p>
  <p>${
    connected
      ? '<span class="ok">已连接 Pinterest。</span> <a href="/studio">打开工作室</a> · <a href="/logout">断开</a>'
      : `<a class="btn" href="/oauth/start">用 Pinterest 连接</a>`
  }</p>
  <h2>用户会用到的主要 Pinterest 功能</h2>
  <div class="grid two">
    <div class="tile"><strong>OAuth 认证</strong><p class="muted">跳转到 pinterest.com/oauth，授权后回到 ${CALLBACK}</p></div>
    <div class="tile"><strong>读取图板</strong><p class="muted">GET /v5/boards — 列出工作室图板</p></div>
    <div class="tile"><strong>读取 Pin</strong><p class="muted">GET /v5/pins — 查看已发布内容</p></div>
    <div class="tile"><strong>创建与定时发布</strong><p class="muted">Standard 通过后用 pins:write 发布工作室 Pin</p></div>
  </div>
  <h2>注册信息</h2>
  <ul>
    <li>Website: <span class="mono">${ORIGIN}/</span></li>
    <li>Privacy: <span class="mono">${ORIGIN}/efwmc/privacy</span></li>
    <li>Redirect URI: <span class="mono">${CALLBACK}</span></li>
  </ul>
`,
  );
}

function privacyPage() {
  return html(
    "Privacy policy",
    `
  <h1>EFWMC privacy policy</h1>
  <p class="muted">Effective 4 September 2026. Operator: EFWMC, domain efwmcapp.com.</p>
  <p>This privacy policy is published by <strong>EFWMC</strong> for the EFWMC Pinterest developer application hosted at ${ORIGIN}.</p>
  <h2>Data we collect</h2>
  <ul>
    <li>Pinterest account identifiers and display name after you authorize the app.</li>
    <li>OAuth authorization codes and access or refresh tokens issued by Pinterest.</li>
    <li>Board and Pin metadata you choose to read or publish through the API.</li>
    <li>Basic request logs (time, path, status) on this Cloudflare Worker.</li>
  </ul>
  <h2>How EFWMC uses the data</h2>
  <p>EFWMC uses this data only to operate the Pinterest integration: complete OAuth, manage Pins for the EFWMC studio, and debug failed API calls. EFWMC does not sell Pinterest user data.</p>
  <h2>Sharing</h2>
  <p>Tokens stay with EFWMC infrastructure. We share data only when required by law or when Pinterest must process the API request you initiated.</p>
  <h2>Retention</h2>
  <p>OAuth tokens are kept until you disconnect the app or they expire. Server logs are retained for a short operational window.</p>
  <h2>Your choices</h2>
  <p>Revoke access from your Pinterest account settings. You can also email EFWMC at <a href="mailto:contact@efwmcapp.com">contact@efwmcapp.com</a> to delete stored tokens.</p>
  <h2>Contact</h2>
  <p>EFWMC · <a href="mailto:contact@efwmcapp.com">contact@efwmcapp.com</a> · ${ORIGIN}</p>
`,
  );
}

function termsPage() {
  return html(
    "Terms",
    `
  <h1>EFWMC terms of use</h1>
  <p>These terms cover the EFWMC Pinterest developer app on efwmcapp.com.</p>
  <p>By authorizing the app you allow EFWMC to call the Pinterest API on your behalf within the scopes you grant. You remain responsible for content you ask EFWMC to publish.</p>
  <p>The service is provided as-is for EFWMC studio operations and Pinterest trial or standard API access. EFWMC may suspend the integration if Pinterest access is revoked or the API terms change.</p>
  <p>Contact: <a href="mailto:contact@efwmcapp.com">contact@efwmcapp.com</a>.</p>
`,
  );
}

function startOAuth(env) {
  const state = randomState();
  return new Response(null, {
    status: 302,
    headers: {
      Location: oauthAuthorizeUrl(env, state),
      "set-cookie": cookie("pintor_oauth_state", state, "HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=600"),
    },
  });
}

async function studioPage(token, extras = "") {
  const [account, boards, pins] = await Promise.all([
    pinterestGet(token, "/user_account"),
    pinterestGet(token, "/boards?page_size=8"),
    pinterestGet(token, "/pins?page_size=8"),
  ]);
  const user = account.ok ? account.data : {};
  const boardItems = boards.ok ? boards.data.items || [] : [];
  const pinItems = pins.ok ? pins.data.items || [] : [];
  const boardCards = boardItems
    .map((b) => {
      const img = (b.media && b.media.image_cover_url) || "";
      return `<div class="tile">${img ? `<img class="thumb" src="${escapeHtml(img)}" alt="">` : ""}<strong>${escapeHtml(b.name || "Board")}</strong><p class="muted">${escapeHtml(String(b.pin_count ?? 0))} Pins · GET /v5/boards</p></div>`;
    })
    .join("");
  const pinCards = pinItems
    .map((p) => {
      const img = (p.media && (p.media.images?.["400x300"]?.url || p.media.cover_image_url)) || "";
      return `<div class="tile">${img ? `<img class="thumb" src="${escapeHtml(img)}" alt="">` : ""}<strong>${escapeHtml(p.title || p.id || "Pin")}</strong><p class="muted">GET /v5/pins · ${escapeHtml(p.id || "")}</p></div>`;
    })
    .join("");
  return html(
    "Studio",
    `
  <div class="banner">步骤 3–4 · OAuth 已完成，正在用访问令牌调用 Pinterest API：用户资料、图板、Pin</div>
  ${extras}
  <p class="ok">Pinterest user authenticated with OAuth 2.0.</p>
  <h1>工作室 · ${escapeHtml(user.username || "Pinterest user")}</h1>
  <p>${escapeHtml(user.business_name || "")} · ${escapeHtml(user.account_type || "")} · ${escapeHtml(String(user.board_count ?? "?"))} boards · ${escapeHtml(String(user.pin_count ?? "?"))} Pins</p>
  <p class="muted">Live GET /v5/user_account ${account.status} · GET /v5/boards ${boards.status} · GET /v5/pins ${pins.status}</p>
  <h2>主要功能：图板</h2>
  <div class="grid two">${boardCards || "<p>No boards returned.</p>"}</div>
  <h2>主要功能：Pin 图</h2>
  <div class="grid two">${pinCards || "<p>No Pins returned.</p>"}</div>
  <h2>主要功能：创建与定时发布</h2>
  <p class="muted">Trial 目前是只读作用域。升级 Standard 并获得 pins:write / boards:write 后，这个表单会调用 POST /v5/pins。</p>
  <form>
    <label>标题</label>
    <input value="EFWMC miniature ramen still life" readonly>
    <label>描述</label>
    <textarea rows="3" readonly>Micro chef on a desktop table cooking ramen. EFWMC studio Pin scheduled after Standard access.</textarea>
    <label>链接</label>
    <input value="${ORIGIN}/" readonly>
    <p><button class="btn" type="button" disabled>发布 Pin（待 Standard）</button></p>
  </form>
  <p><a class="btn secondary" href="/logout">断开 Pinterest</a></p>
`,
  );
}

async function callbackPage(request, env, url) {
  const error = url.searchParams.get("error") || "";
  const errorDesc = url.searchParams.get("error_description") || "";
  const code = url.searchParams.get("code") || "";
  const state = url.searchParams.get("state") || "";
  const cookies = parseCookies(request);
  if (error) {
    return html(
      "OAuth error",
      `<div class="banner">OAuth 未完成</div><p>${escapeHtml(error)}: ${escapeHtml(errorDesc)}</p><p><a class="btn" href="/oauth/start">重试连接</a></p>`,
      400,
    );
  }
  if (!code) {
    return html(
      "OAuth callback",
      `<h1>Pinterest OAuth callback</h1><p>Waiting for Pinterest. Redirect URI: <span class="mono">${CALLBACK}</span></p>`,
    );
  }
  if (cookies.pintor_oauth_state && state && cookies.pintor_oauth_state !== state) {
    return html("OAuth error", `<p>State mismatch. <a href="/oauth/start">Restart</a></p>`, 400);
  }
  try {
    const token = await exchangeCode(env, code);
    const extras = `
      <div class="banner">步骤 2–3 · Pinterest 已授权并重定向回 ${CALLBACK}。授权码已换成 access token（不在页面显示）。</div>
      <p>Authorization code received: <span class="mono">${escapeHtml(code.slice(0, 12))}…</span></p>
    `;
    const page = await studioPage(token.access_token, extras);
    const headers = new Headers(page.headers);
    headers.append("set-cookie", cookie("pintor_token", token.access_token, "HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=86400"));
    headers.append("set-cookie", cookie("pintor_oauth_state", "", "HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=0"));
    return new Response(page.body, {status: 200, headers});
  } catch (err) {
    return html(
      "OAuth callback",
      `
      <div class="banner">收到 Pinterest 授权码，但换取令牌失败</div>
      <p>code: <span class="mono">${escapeHtml(code.slice(0, 16))}…</span></p>
      <p class="muted">${escapeHtml(String(err.message || err))}</p>
      <p><a class="btn" href="/oauth/start">重试</a></p>
    `,
      502,
    );
  }
}

function logout() {
  return new Response(null, {
    status: 302,
    headers: {
      Location: "/",
      "set-cookie": cookie("pintor_token", "", "HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=0"),
    },
  });
}

function normalizePath(pathname) {
  if (pathname.length > 1 && pathname.endsWith("/")) return pathname.slice(0, -1);
  return pathname;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = normalizePath(url.pathname);
    const cookies = parseCookies(request);

    if (path === "/health") {
      return new Response("ok\n", {headers: {"content-type": "text/plain; charset=utf-8"}});
    }
    if (path === "/" || path === "/index.html") return homePage(Boolean(cookies.pintor_token));
    if (path === "/privacy" || path === "/efwmc/privacy") return privacyPage();
    if (path === "/terms") return termsPage();
    if (path === "/oauth/start") return startOAuth(env);
    if (path === "/oauth/callback") return callbackPage(request, env, url);
    if (path === "/studio") {
      if (!cookies.pintor_token) {
        return html("Studio", `<p>未连接。</p><p><a class="btn" href="/oauth/start">用 Pinterest 连接</a></p>`);
      }
      return studioPage(cookies.pintor_token);
    }
    if (path === "/logout") return logout();

    return html("Not found", `<h1>Not found</h1><p>No page at <span class="mono">${escapeHtml(path)}</span>.</p>`, 404);
  },
};
