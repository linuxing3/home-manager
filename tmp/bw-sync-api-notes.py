#!/usr/bin/env python3
from __future__ import annotations
import json, os, re, subprocess, sys
from pathlib import Path

RT = Path(os.environ['XDG_RUNTIME_DIR'])
CANDS_PATH = RT / 'bw-api-candidates.json'
LOG_PATH = RT / 'bw-sync-api-notes.log'
META_PATH = RT / 'bw-created-notes.json'
LOCAL_ENV = RT / 'bw-synced-env'
AGENIX = RT / 'agenix' / 'api-keys-new.age'
SECRETSPEC = Path('/home/Designers/home-config/secrets/secretspec.toml')
HOME_ENV = Path('/home/Designers/home-config/.env')
BYBIT_ENV = RT / 'bybit-env'

SMART = {
  ('accounts.x.ai', 'ACCOUNTS_API_KEY'): 'XAI_API_KEY',
  ('dash.cloudflare.com', 'ACCOUNT_API_TOKEN'): 'CLOUDFLARE_ACCOUNT_API_TOKEN',
  ('whop.com', 'API_KEY'): 'WHOP_API_KEY',
  ('gumroad.com - overlabor77@efwmcapp.com', 'APP_SECRET'): 'GUMROAD_APP_SECRET',
  ('console.tailscale.com', 'AUTH_KEY'): 'TAILSCALE_AUTH_KEY',
  ('console.tailscale.com', 'CONSOLE_CLIENT_SECRET'): 'TAILSCALE_OAUTH_CLIENT_SECRET',
  ('cliproxyapi', 'CLIPROXYAPI_API_KEY'): 'CLIPROXYAPI_API_KEY',
  ('dash.cloudflare.com', 'COLLIE_API_TOKEN'): 'CLOUDFLARE_COLLIE_API_TOKEN',
  ('dashboard.ngrok.com', 'DASHBOARD_API'): 'NGROK_API_KEY',
  ('dashboard.ngrok.com', 'DASHBOARD_AUTHTOKEN'): 'NGROK_AUTHTOKEN',
  ('dash.better-auth.com', 'DASH_API'): 'BETTER_AUTH_DASH_API_KEY',
  ('vault.koofr.net', 'EFWMC_APP_KEY'): 'KOOFR_EFWMC_APP_KEY',
  ('dash.cloudflare.com', 'EFWMC_DASHBOARD_TOKEN'): 'CLOUDFLARE_EFWMC_DASHBOARD_TOKEN',
  ('fal.ai', 'FAL_API'): 'FAL_KEY',
  ('dash.cloudflare.com', 'FULL_READ_TOKEN'): 'CLOUDFLARE_FULL_READ_TOKEN',
  ('github.com', 'GITHUB_CLIENT_SECRETS'): 'GITHUB_OAUTH_CLIENT_SECRET',
  ('gumroad.com - overlabor77@efwmcapp.com', 'GUMROAD_ACCESS_TOKEN'): 'GUMROAD_ACCESS_TOKEN',
  ('account.live.com', 'LIVE_SECRET_ID'): 'MICROSOFT_LIVE_CLIENT_SECRET_ID',
  ('account.live.com', 'LIVE_SECRET_VALUE'): 'MICROSOFT_LIVE_CLIENT_SECRET',
  ('platform.kimi.com', 'PLATFORM_API_KEYS'): 'KIMI_API_KEY',
  ('platform.deepseek.com', 'PLATFORM_CLIPROXYAPI'): 'DEEPSEEK_CLIPROXYAPI_KEY',
  ('vault.koofr.net', 'SAFE_KEY'): None,
  ('dash.cloudflare.com', 'SERVICE_TOKEN_CLIENT_ID'): 'CLOUDFLARE_ACCESS_CLIENT_ID',
  ('dash.cloudflare.com', 'SERVICE_TOKEN_CLIENT_SECRETS'): 'CLOUDFLARE_ACCESS_CLIENT_SECRET',
  ('dash.cloudflare.com', 'SFU_TOKEN'): 'CLOUDFLARE_SFU_TOKEN',
  ('dash.cloudflare.com', 'SHORT_LIVED_KEY'): None,
  ('efwmcsyle.ccwu.cc', 'SSH_KEY'): None,
  ('dash.cloudflare.com', 'TURNSTILE_KEY'): 'CLOUDFLARE_TURNSTILE_SECRET_KEY',
  ('dash.cloudflare.com', 'TURNSTILE_SITE_KEY'): 'CLOUDFLARE_TURNSTILE_SITE_KEY',
  ('dash.cloudflare.com', 'TURN_API_TOKEN'): 'CLOUDFLARE_TURN_API_TOKEN',
  ('vercel', 'TYPESAFE_AI_API_KEY'): 'VERCEL_TYPESAFE_AI_API_KEY',
  ('vercel', 'VERCEL_API_KEY'): 'VERCEL_API_TOKEN',
  ('dash.cloudflare.com', 'WORKER_TOKEN'): 'CLOUDFLARE_WORKER_TOKEN',
  ('youmind.com', 'YOUMIND_API'): 'YOUMIND_API_KEY',
  ('youtube api v3 desktop', 'YOUTUBE_CLIENT_SECRET'): 'YOUTUBE_OAUTH_CLIENT_SECRET',
  ('YouTube OAuth — overlabor77 / project-ae468e19', 'OAUTH_TOKEN_JSON'): None,
  ('YouTube OAuth — overlabor77 / project-ae468e19', 'YOUTUBE_CLIENT_SECRET_JSON'): None,
  ('YouTube OAuth — overlabor77 / project-ae468e19', 'YOUTUBE_CLIENT_SECRET_PATH'): None,
  ('accounts.google.com', 'GOOGLE_APP_PASSWORD'): 'GOOGLE_APP_PASSWORD',
  ('cnb.cool', 'CNB_TOKEN'): 'CNB_TOKEN',
  ('casawarden.efwmc.ccwu.cc', 'CASAWARDEN_CLIENT_ID'): 'CASAWARDEN_CLIENT_ID',
  ('casawarden.efwmc.ccwu.cc', 'CASAWARDEN_CLIENT_SECRET'): 'CASAWARDEN_CLIENT_SECRET',
  ('app.notion.com', 'NOTION_API_KEY'): 'NOTION_API_KEY',
  ('www.workbuddy.cn', 'WORKBUDDY_API_KEY'): 'WORKBUDDY_API_KEY',
  ('grokbotx.linuxing3.ccwu.cc', 'KONGMING_WEBHOOK_KEY'): 'KONGMING_WEBHOOK_KEY',
  ('whop.com', 'WHOP_API_KEY'): 'WHOP_API_KEY',
  ('www.bybit.com -Brazil', 'BYBIT_API_KEY'): 'BYBIT_API_KEY',
  ('accounts.google.com', 'CURSOR_API_KEY'): 'CURSOR_API_KEY',
}

def log(msg: str) -> None:
    line = msg.rstrip() + '\n'
    sys.stdout.write(line); sys.stdout.flush()
    with LOG_PATH.open('a') as f: f.write(line)

def bw(args, input_text=None):
    env = os.environ.copy()
    return subprocess.check_output(['bw', *args], input=input_text, env=env, text=True)

def mask(v):
    return f'{v[:5]}...{v[-4:]}' if len(v) > 9 else 'short'

def refine(cands):
    refined = {}
    for c in cands:
        key = (c['item_name'], c['env'])
        if key in SMART:
            new = SMART[key]
            if new is None: continue
            c = dict(c); c['env'] = new
        else:
            if c['env'] in {'API_KEY','APP_SECRET','AUTH_KEY','SAFE_KEY','SSH_KEY','SHORT_LIVED_KEY'}:
                continue
            if c['env'].endswith('_JSON') or c['env'].endswith('_PATH'):
                continue
        prev = refined.get(c['env'])
        if not prev or len(c['value']) > len(prev['value']):
            refined[c['env']] = c
    return refined

def existing_env_notes():
    items = json.loads(bw(['list','items']) or '[]')
    return {(it.get('name') or ''): it for it in items if it.get('type')==2 and re.fullmatch(r'[A-Z][A-Z0-9_]{2,}', it.get('name') or '')}

def create_missing(refined, existing):
    created, existed, failed = [], [], []
    for env_name, c in sorted(refined.items()):
        if env_name in existing:
            existed.append(env_name); continue
        item = {
            'type':2,'name':env_name,
            'notes':f"Extracted from Bitwarden item {c['item_name']!r} via {c['source']}",
            'favorite':False,'reprompt':0,
            'fields':[{'type':1,'name':'value','value':c['value']}],
            'secureNote':{'type':0},'login':None,'card':None,'identity':None,'folderId':None,
        }
        try:
            encoded = bw(['encode'], json.dumps(item)).strip()
            out = bw(['create','item', encoded])
            created_item = json.loads(out)
            ok = any(f.get('name')=='value' and bool(f.get('value')) for f in (created_item.get('fields') or []))
            log(f"CREATED {env_name} ok={ok} mask={mask(c['value'])} src={c['item_name']}")
            created.append(env_name); existing[env_name]=created_item
        except subprocess.CalledProcessError as e:
            log(f'FAILED {env_name}: {e}'); failed.append(env_name)
    return created, existed, failed

def parse_env_file(path: Path):
    if not path.exists(): return {}
    out = {}
    key_re = re.compile(r'^(?:export\s+)?([A-Z][A-Z0-9_]{2,})\s*=\s*(.*)$')
    for ln in path.read_text(errors='replace').splitlines():
        s=ln.strip()
        if not s or s.startswith('#'): continue
        m=key_re.match(s)
        if not m: continue
        k,v=m.group(1), m.group(2)
        if (v.startswith("'") and v.endswith("'")) or (v.startswith('"') and v.endswith('"')):
            v=v[1:-1]
        out[k]=v
    return out

def note_value(it):
    for f in it.get('fields') or []:
        if f.get('name')=='value' and f.get('value'):
            return f['value']
    return ''

def local_key_names():
    names=set()
    for p in [AGENIX, HOME_ENV, BYBIT_ENV, LOCAL_ENV, Path('/home/Designers/.env')]:
        names.update(parse_env_file(p))
    return names

def append_missing_local(notes, refined):
    local = local_key_names(); existing_sync = parse_env_file(LOCAL_ENV)
    appended, untouched, lines_to_add = [], [], []
    for name in sorted(set(refined)|set(notes)):
        if not re.search(r'(API|SECRET|TOKEN|KEY|PASSWORD|PASS|CLIENT)', name):
            continue
        if name in local or name in existing_sync:
            untouched.append(name); continue
        it = notes.get(name); val = note_value(it) if it else ''
        if not val and name in refined: val = refined[name]['value']
        if not val: continue
        esc = val.replace("'", "'\\''")
        lines_to_add.append(f"export {name}='{esc}'\n"); appended.append(name)
    if lines_to_add:
        if not LOCAL_ENV.exists():
            LOCAL_ENV.write_text('# append-only synced from Bitwarden secure notes\n# DO NOT overwrite existing keys elsewhere\n')
            LOCAL_ENV.chmod(0o600)
        with LOCAL_ENV.open('a') as f:
            f.write(f'# sync append {len(lines_to_add)} keys\n')
            for ln in lines_to_add: f.write(ln)
        LOCAL_ENV.chmod(0o600)
    return appended, untouched

def update_secretspec(new_names):
    text = SECRETSPEC.read_text()
    existing = set(re.findall(r'^([A-Z][A-Z0-9_]*)\s*=', text, re.M))
    m = re.search(r'\[profiles\.default\]\n', text)
    if not m: return []
    next_sec = re.search(r'\n\[profiles\.[^\]]+\]', text[m.end():])
    insert_at = m.end() + next_sec.start() if next_sec else len(text)
    lines, added = [], []
    for name in sorted(set(new_names)):
        if name in existing or name == 'SECRETSPEC_BW_TEST': continue
        desc = name.replace('_',' ').title()
        lines.append(f'{name} = {{ description = "{desc}", providers = ["bitwarden"], ref = {{ item = "{name}", field = "value" }} }}\n')
        added.append(name)
    if not lines: return []
    prefix, suffix = text[:insert_at], text[insert_at:]
    if not prefix.endswith('\n'): prefix += '\n'
    SECRETSPEC.write_text(prefix + ''.join(lines) + suffix)
    return added

def main():
    LOG_PATH.write_text(''); LOG_PATH.chmod(0o600)
    if 'BW_SESSION' not in os.environ and (RT/'bw-session').exists():
        os.environ['BW_SESSION'] = (RT/'bw-session').read_text().strip()
    log('status=' + bw(['status']).strip())
    try: bw(['sync'])
    except subprocess.CalledProcessError: pass
    refined = refine(json.loads(CANDS_PATH.read_text()))
    log(f'refined={len(refined)}')
    existing = existing_env_notes(); log(f'existing_env_notes={len(existing)}')
    created, existed, failed = create_missing(refined, existing)
    try: bw(['sync'])
    except subprocess.CalledProcessError: pass
    existing = existing_env_notes()
    appended, untouched = append_missing_local(existing, refined)
    spec_added = update_secretspec(sorted(set(created)|set(refined)))
    meta = {
      'created': created, 'already_existed': existed, 'failed': failed,
      'local_appended': appended, 'local_untouched_count': len(untouched),
      'secretspec_added': spec_added, 'refined_count': len(refined),
      'env_notes_total': len(existing),
    }
    META_PATH.write_text(json.dumps(meta, indent=2)); META_PATH.chmod(0o600)
    log('SUMMARY ' + json.dumps({
      'created': created, 'created_count': len(created),
      'already_existed_count': len(existed), 'failed': failed,
      'local_appended': appended, 'local_untouched_count': len(untouched),
      'secretspec_added': spec_added, 'env_notes_total': len(existing),
    }))
    log('DONE')
    return 0 if not failed else 1

if __name__ == '__main__':
    raise SystemExit(main())
