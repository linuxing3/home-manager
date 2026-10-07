## Shared Notion Memory Bootstrap

Notion is the canonical shared memory and instruction layer. Local agent files are pointers, not authority. Collaboration rules follow `本机 Agent ↔ Grok Bot 协作约定` (protocol v0.3, effective 2026-10-07): https://app.notion.com/p/3f13ec2d7aec81369154c87a969c7977 — seats and division of labor are listed only in `席位名册`: https://app.notion.com/p/3f23ec2d7aec819589c0dc19bbb84c05

Read/search Notion before work involving planning, operations, publishing, credentials, projects, or multi-agent coordination. Main anchors:

- `WORK PLAN`: https://app.notion.com/p/3d53ec2d7aec810987b0d44ed0006385
- `铁律`: https://app.notion.com/p/3d43ec2d7aec816cb0e3f8622f8283c7
- `席位名册`: https://app.notion.com/p/3f23ec2d7aec819589c0dc19bbb84c05
- `Context`: https://app.notion.com/p/3d43ec2d7aec81159ae3d37332eef3f4
- `PM Tasks` (task queue): https://app.notion.com/p/8feaef7031214743bfbcdf222dcc263d (`collection://ff92ba39-4975-4a01-81b6-f0893b6d935a`)
- `PM Projects`: https://app.notion.com/p/a889a7e43a754330851bacba53be740f
- `Sync Log`: https://app.notion.com/p/25f9101ad2c44c7894731da9b2f856e1 (`collection://98f840ae-bd1d-429b-8777-e3856666d49e`)
- `Agent 共享记忆 · 社媒发布 API`: https://app.notion.com/p/3e53ec2d7aec810cad73dac5ce34bfe1

Startup ritual: check `PM Tasks` for rows with `Bot` = `共享`, a title starting with your local-agent prefix (`[本机·Pi]`, `[本机·OMP]`, `[本机·Codex]`, `[本机·Cursor]`, `[本机·Grok]`), and `Status` = `Not started`; also resume your own `In progress` rows. Claim a row by setting `Status` to `In progress`. Finish with `Done` plus a one-line `Note` with evidence links, or `Blocked` plus a Sync Log `Blocker` row. Before starting, dedupe: search PM Tasks, Sync Log (last 14 days), and Context for existing work. `Missions` is a read-only archive since 2026-10-07; do not take work from it.

Degraded-query fallback: if the Notion Query Data Source quota is limited or exhausted, do not stop. Use `notion-search` scoped to the PM Tasks collection (your `[本机·X]` prefix or task keywords) or open the PM Tasks view, then `fetch` each candidate row to verify `Bot`, `Status`, and the five handoff fields before claiming it.

Write policy: `铁律`, `WORK PLAN` body, and the collaboration convention page are read-only. In `PM Tasks`, only update the Status/Note of the row you claimed. In `Sync Log`, only append new rows: `From=共享`, `To=孔明`, `Type=Update/Blocker/Ask/Handoff/Decision`, and `Entry` must start with one of `[本机·Pi]`, `[本机·OMP]`, `[本机·Codex]`, `[本机·Cursor]`, `[本机·Grok]`. Keep `Summary` to at most 3 sentences and include relevant paths, commits, or links.

Routing (铁律 §2/§3, 2026-10-07): heavy work, voice-over, editing, and publishing go to Pi / Cursor Pi; OMP handles browser automation when named or routed by the omp-jev rule.

Report results or blockers only to 孔明. `muse-notify`, `tell kongming`, and AgentMail are wake-up signals; the durable content belongs in `Sync Log`. Grok Bot web cannot read local files, so anything it needs must be in Notion.

Do not write secrets to Notion, chat, git, or local rules. Store paths and public IDs only; secret material goes through Agenix. Do not paste whole conversations or store temporary guesses.
