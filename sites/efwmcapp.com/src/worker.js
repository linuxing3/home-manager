const ADS_TXT = "google.com, pub-9109511803236012, DIRECT, f08c47fec0942fa0\n";

const PAGE_CSS =
  "body{font-family:system-ui,-apple-system,sans-serif;max-width:720px;margin:2rem auto;padding:0 1.25rem;line-height:1.55;color:#18181b}h1{font-size:1.6rem}h2{font-size:1.15rem;margin-top:1.75rem}a{color:#be185d}";

function page(title, body) {
  return new Response(
    `<!doctype html><html lang="en"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>${title}</title><style>${PAGE_CSS}</style></head><body>${body}<p><a href="/">← Home</a></p></body></html>`,
    {
      headers: {
        "content-type": "text/html; charset=utf-8",
        "cache-control": "public, max-age=300",
      },
    },
  );
}

function legalPage(path) {
  if (path === "/privacy") {
    return page(
      "Privacy Policy — efwmcapp",
      `<h1>Privacy Policy</h1>
<p><strong>Effective date:</strong> September 24, 2026</p>
<p>This policy covers <strong>efwmcapp</strong> websites (efwmcapp.com, glow.efwmcapp.com, cozy.efwmcapp.com, smart.efwmcapp.com) and the EFWMC Meta app <strong>overlabor77-reels</strong>, used to publish content to our own Instagram professional account.</p>
<h2>Who we are</h2>
<p>We run niche product landing pages and social publishing for our own brands. Contact: <a href="mailto:overlabor77@gmail.com">overlabor77@gmail.com</a>.</p>
<h2>What data we collect</h2>
<ul>
<li><strong>Site visitors:</strong> standard server/CDN logs (IP, user agent, pages viewed) and optional analytics cookies.</li>
<li><strong>Meta / Instagram:</strong> when the account owner authorizes the app, we receive an access token, the Facebook Page id, and the Instagram professional account id and username needed to publish Reels we own. We do not collect Facebook or Instagram passwords through this site.</li>
<li><strong>Pinterest API:</strong> OAuth tokens for our own business account only.</li>
<li><strong>Amazon Associates:</strong> product metadata and affiliate click attribution.</li>
</ul>
<h2>How we use data</h2>
<p>To operate landing pages, publish our own Pins and Instagram Reels, measure performance, and keep the integration working. We do not sell personal data and we do not use the Meta token to access other people's accounts.</p>
<h2>Data retention and deletion</h2>
<p>Tokens are stored on our systems and deleted when the integration is removed. Request deletion at <a href="/data-deletion">/data-deletion</a> or by email.</p>
<h2>Third parties</h2>
<p>Cloudflare hosts this site. Meta, Pinterest, and Amazon process data under their own policies when you use those services.</p>
<h2>Children</h2>
<p>Our sites are not directed to children under 13.</p>`,
    );
  }
  if (path === "/terms") {
    return page(
      "Terms — efwmcapp",
      `<h1>Terms of use</h1>
<p><strong>Effective date:</strong> September 24, 2026</p>
<p>efwmcapp.com and the Meta app overlabor77-reels are operated by EFWMC for our own storefronts and our own Instagram professional account.</p>
<p>By authorizing the app you allow EFWMC to call the Instagram Graph API within the scopes you grant, including publishing Reels to the connected professional account. You remain responsible for the content you ask us to publish.</p>
<p>The service is provided as-is. We may suspend it if Meta revokes access or the API terms change.</p>
<p>Contact: <a href="mailto:overlabor77@gmail.com">overlabor77@gmail.com</a>.</p>`,
    );
  }
  if (path === "/data-deletion") {
    return page(
      "Data deletion — efwmcapp",
      `<h1>User data deletion</h1>
<p>To delete data stored for the EFWMC Meta / Instagram app (access tokens, Page id, Instagram professional account id):</p>
<ol>
<li>Remove the app in Facebook Settings → Apps and websites, and in Instagram Settings → Apps and websites.</li>
<li>Email <a href="mailto:overlabor77@gmail.com">overlabor77@gmail.com</a> with the subject “Delete Meta app data”. We delete stored tokens and account ids within 30 days.</li>
</ol>
<p>This site does not keep a copy of your Facebook password.</p>`,
    );
  }
  if (path === "/oauth/callback") {
    return page(
      "EFWMC authorization",
      `<h1>Authorization received</h1>
<p>You can close this tab. The result stays in the browser address bar and is not stored on this website.</p>`,
    );
  }
  return null;
}

export default {
  async fetch(request, env) {
    const incoming = new URL(request.url);
    const host = incoming.hostname.toLowerCase();
    let path = incoming.pathname;

    if (path === "/ads.txt") {
      return new Response(ADS_TXT, {
        headers: {
          "content-type": "text/plain; charset=utf-8",
          "cache-control": "public, max-age=300",
        },
      });
    }

    if (host === "efwmcapp.com" || host === "www.efwmcapp.com") {
      const legal = legalPage(path);
      if (legal) return legal;
    }

    const sub = host.startsWith("glow.")
      ? "glow"
      : host.startsWith("smart.")
        ? "smart"
        : host.startsWith("cozy.")
          ? "cozy"
          : null;
    if (sub) {
      const passThrough =
        path.startsWith("/assets/") ||
        path === "/catalog.json" ||
        path.startsWith("/" + sub + "/");
      if (!passThrough) {
        if (path === "/" || path === "") {
          path = "/" + sub + "/";
        } else if (!path.startsWith("/" + sub)) {
          path = "/" + sub + (path.startsWith("/") ? path : "/" + path);
        }
      }
    }
    const url = new URL(request.url);
    url.pathname = path;
    return env.ASSETS.fetch(url.toString(), request);
  },
};
