const ADS_TXT = "google.com, pub-9109511803236012, DIRECT, f08c47fec0942fa0\n";

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
