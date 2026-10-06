final: prev: {
  wrangler = prev.wrangler.overrideAttrs (old: rec {
    version = "4.147.0";
    src = prev.fetchFromGitHub {
      owner = "cloudflare";
      repo = "workers-sdk";
      rev = "wrangler@${version}";
      hash = "sha256-AFWhs+9BmSy69hAxV3HKUFCTwLc3TZBg+f/1wM4caUw=";
    };
    pnpmDeps = prev.fetchPnpmDeps {
      inherit (old) pname postPatch;
      inherit version src;
      pnpm = prev.pnpm_10;
      fetcherVersion = 3;
      hash = "sha256-dPLKa9/+wNsaOrEPcfzI6MnqZPBab/SmaNbOk/sIcZw=";
    };
    postBuild = ''
      NODE_ENV=production pnpm --filter wrangler... run build
    '';
  });
}
