const MAIL = "overlabor77@gmail.com";

const PRODUCTS = {
  launch: {
    name: "Launch Kit",
    mode: "payment",
    unit_amount: 2900,
    interval: null,
  },
  studio: {
    name: "Studio Seat",
    mode: "subscription",
    unit_amount: 7900,
    interval: "month",
  },
  command: {
    name: "Command",
    mode: "subscription",
    unit_amount: 19900,
    interval: "month",
  },
};

const CSS = `
:root{--ink:#0f172a;--muted:#475569;--line:#e2e8f0;--bg:#f8fafc;--card:#fff;--accent:#0d9488;--accent2:#0f766e}
*{box-sizing:border-box}
body{margin:0;font-family:system-ui,-apple-system,Segoe UI,sans-serif;color:var(--ink);background:var(--bg);line-height:1.55}
a{color:var(--accent2)}
header,main,footer{max-width:960px;margin:0 auto;padding:1.25rem}
header{display:flex;justify-content:space-between;align-items:center;gap:1rem}
.brand{font-weight:650;letter-spacing:.02em}
.hero{padding:2.5rem 1.25rem 1rem;max-width:960px;margin:0 auto}
.hero h1{font-size:clamp(1.8rem,4vw,2.6rem);line-height:1.15;margin:.25rem 0 1rem}
.lede{color:var(--muted);font-size:1.05rem;max-width:42rem}
.grid{display:grid;gap:1rem;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));padding:0 1.25rem 2rem;max-width:960px;margin:0 auto}
.card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:1.15rem 1.2rem}
.card h2{margin:.2rem 0 .4rem;font-size:1.15rem}
.price{font-size:1.45rem;font-weight:650;margin:.4rem 0}
.price span{font-size:.9rem;font-weight:500;color:var(--muted)}
ul{margin:.4rem 0 1rem;padding-left:1.1rem;color:var(--muted)}
.btn{display:inline-block;background:var(--accent);color:#fff;text-decoration:none;padding:.55rem .9rem;border-radius:8px;font-weight:600;border:0;cursor:pointer;font:inherit}
.btn.secondary{background:#fff;color:var(--accent2);border:1px solid var(--accent)}
footer{color:var(--muted);font-size:.9rem;border-top:1px solid var(--line);margin-top:1rem}
`;

function html(title, body) {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>${title}</title>
<meta name="description" content="EFWMC Social: virtual products for social media management — calendars, caption kits, scheduling seats, and playbooks."/>
<style>${CSS}</style>
</head>
<body>${body}</body>
</html>`;
}

function page(title, body) {
  return new Response(html(title, body), {
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "public, max-age=60",
    },
  });
}

const NAV = `<header>
  <div class="brand">EFWMC Social</div>
  <nav><a href="/">Shop</a> · <a href="/privacy">Privacy</a> · <a href="/terms">Terms</a></nav>
</header>`;

const FOOT = `<footer>
  <p>Virtual products only. Checkout is Stripe-hosted. Operator: EFWMC</p>
  <p><a href="mailto:${MAIL}">${MAIL}</a></p>
</footer>`;

function buyForm(sku, label) {
  return `<form action="/checkout" method="POST">
    <input type="hidden" name="sku" value="${sku}"/>
    <button class="btn" type="submit">${label}</button>
  </form>`;
}

function home() {
  return page(
    "EFWMC Social — social media management kits",
    `${NAV}
<section class="hero">
  <p class="lede">Mini SaaS for operators who ship content every week.</p>
  <h1>Social media management, sold as virtual products.</h1>
  <p class="lede">Buy a kit or a seat. No physical goods. You get playbooks, calendars, caption packs, and a scheduling workspace for new social channels (short video, carousels, newsletters, and community posts).</p>
</section>
<section class="grid">
  <article class="card">
    <p>Digital kit</p>
    <h2>Launch Kit</h2>
    <p class="price">$29 <span>one-time</span></p>
    <ul>
      <li>30-day content calendar (CSV + Notion template)</li>
      <li>90 captions for Reels / Shorts / carousels</li>
      <li>Hook, CTA, and hashtag sheets</li>
    </ul>
    ${buyForm("launch", "Buy kit")}
  </article>
  <article class="card">
    <p>Workspace seat</p>
    <h2>Studio Seat</h2>
    <p class="price">$79 <span>/ month</span></p>
    <ul>
      <li>1 brand workspace, 3 seats</li>
      <li>Queue + calendar for 4 networks</li>
      <li>Monthly performance snapshot (PDF)</li>
    </ul>
    ${buyForm("studio", "Start seat")}
  </article>
  <article class="card">
    <p>Operator bundle</p>
    <h2>Command</h2>
    <p class="price">$199 <span>/ month</span></p>
    <ul>
      <li>Up to 5 brands, 10 seats</li>
      <li>Cross-post playbooks and crisis scripts</li>
      <li>Weekly digest + competitor watchlist</li>
    </ul>
    ${buyForm("command", "Subscribe")}
  </article>
</section>
<section class="hero">
  <h2>How delivery works</h2>
  <p class="lede">Pay on Stripe Checkout. Kits arrive by email within one business day. Seats get a workspace invite. Cancel seats from Stripe; kits stay yours.</p>
  <p><a class="btn secondary" href="mailto:${MAIL}">Talk to EFWMC</a></p>
</section>
${FOOT}`,
  );
}

function success() {
  return page(
    "Payment received — EFWMC Social",
    `${NAV}<main>
<h1>Payment received</h1>
<p>Stripe confirmed this checkout. We email kit files or a seat invite to the address you used on Checkout.</p>
<p><a class="btn" href="/">Back to shop</a></p>
</main>${FOOT}`,
  );
}

function cancel() {
  return page(
    "Checkout canceled — EFWMC Social",
    `${NAV}<main>
<h1>Checkout canceled</h1>
<p>No charge was made. You can pick a product again.</p>
<p><a class="btn" href="/">Back to shop</a></p>
</main>${FOOT}`,
  );
}

function privacy() {
  return page(
    "Privacy — EFWMC Social",
    `${NAV}<main>
<h1>Privacy Policy</h1>
<p>Effective 29 September 2026. This site sells virtual social-media products for EFWMC.</p>
<p>We collect the name, email, and payment details Stripe needs to complete Checkout. Stripe processes cards. We use your email to deliver kits and seats. We do not sell personal data.</p>
<p>Contact: <a href="mailto:${MAIL}">${MAIL}</a>.</p>
</main>${FOOT}`,
  );
}

function terms() {
  return page(
    "Terms — EFWMC Social",
    `${NAV}<main>
<h1>Terms of use</h1>
<p>Products are digital. No physical shipment. Seats are a license for the billed month. Kits are delivered once. Payments run through Stripe Checkout.</p>
<p>You remain responsible for content you publish with these tools. EFWMC may refuse orders that violate platform rules.</p>
<p>Contact: <a href="mailto:${MAIL}">${MAIL}</a>.</p>
</main>${FOOT}`,
  );
}

function encodeForm(fields) {
  const body = new URLSearchParams();
  for (const [k, v] of Object.entries(fields)) {
    if (v != null && v !== "") body.set(k, String(v));
  }
  return body;
}

async function createCheckout(request, env) {
  const origin = new URL(request.url).origin;
  const form = await request.formData();
  const sku = String(form.get("sku") || "");
  const product = PRODUCTS[sku];
  if (!product) return new Response("Unknown product", {status: 400});
  const key = env.STRIPE_SECRET_KEY;
  if (!key) {
    return page(
      "Checkout unavailable — EFWMC Social",
      `${NAV}<main>
<h1>Checkout is not configured</h1>
<p>Set the Stripe secret on this Worker, then retry.</p>
<p><a class="btn" href="/">Back to shop</a></p>
</main>${FOOT}`,
    );
  }

  const fields = {
    "mode": product.mode,
    "success_url": `${origin}/success?session_id={CHECKOUT_SESSION_ID}`,
    "cancel_url": `${origin}/cancel`,
    "customer_creation": product.mode === "payment" ? "always" : undefined,
    "billing_address_collection": "auto",
    "line_items[0][quantity]": "1",
    "line_items[0][price_data][currency]": "usd",
    "line_items[0][price_data][unit_amount]": String(product.unit_amount),
    "line_items[0][price_data][product_data][name]": product.name,
    "metadata[sku]": sku,
  };
  if (product.interval) {
    fields["line_items[0][price_data][recurring][interval]"] = product.interval;
  }

  const res = await fetch("https://api.stripe.com/v1/checkout/sessions", {
    method: "POST",
    headers: {
      authorization: "Bearer " + key,
      "content-type": "application/x-www-form-urlencoded",
    },
    body: encodeForm(fields),
  });
  const data = await res.json();
  if (!res.ok || !data.url) {
    return page(
      "Checkout error — EFWMC Social",
      `${NAV}<main>
<h1>Checkout could not start</h1>
<p>Stripe rejected this session. Try again or email <a href="mailto:${MAIL}">${MAIL}</a>.</p>
<p><a class="btn" href="/">Back to shop</a></p>
</main>${FOOT}`,
    );
  }
  return Response.redirect(data.url, 303);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname.replace(/\/$/, "") || "/";
    if (request.method === "POST" && path === "/checkout") {
      return createCheckout(request, env);
    }
    if (path === "/") return home();
    if (path === "/success") return success();
    if (path === "/cancel") return cancel();
    if (path === "/privacy") return privacy();
    if (path === "/terms") return terms();
    return new Response("Not found", {status: 404});
  },
};
