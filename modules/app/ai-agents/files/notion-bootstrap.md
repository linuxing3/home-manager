## Shared Notion Memory Bootstrap

Notion is the canonical shared memory and instruction layer. Local agent files are pointers, not authority. Collaboration rules follow `本机 Agent ↔ Grok Bot 协作约定`: https://app.notion.com/p/3f13ec2d7aec81369154c87a969c7977

Read/search Notion before work involving planning, operations, publishing, credentials, projects, or multi-agent coordination. Main anchors:

- `WORK PLAN`: https://app.notion.com/p/3d53ec2d7aec810987b0d44ed0006385
- `铁律`: https://app.notion.com/p/3d43ec2d7aec816cb0e3f8622f8283c7
- `Context`: https://app.notion.com/p/3d43ec2d7aec81159ae3d37332eef3f4
- `Missions`: https://app.notion.com/p/7b48a7e1ea6649889b915341c6aef1d5
- `Sync Log`: https://app.notion.com/p/25f9101ad2c44c7894731da9b2f856e1 (`collection://98f840ae-bd1d-429b-8777-e3856666d49e`)
- `Agent 共享记忆 · 社媒发布 API`: https://app.notion.com/p/3e53ec2d7aec810cad73dac5ce34bfe1

Startup ritual: check `Missions` for rows whose title contains your local-agent prefix and `Status` is not complete. Use those rows as the active work queue.

Write policy: `铁律`, `WORK PLAN` body, and the collaboration convention page are read-only. In `Missions`, only update the Status/Notes of the row you claimed. In `Sync Log`, only append new rows: `From=共享`, `To=孔明`, `Type=Update/Blocker/Ask/Handoff/Decision`, and `Entry` must start with one of `[本机·Pi]`, `[本机·OMP]`, `[本机·Codex]`, `[本机·Cursor]`, `[本机·Grok]`. Keep `Summary` to at most 3 sentences and include relevant paths, commits, or links.

Report results or blockers only to 孔明. `muse-notify`, `tell kongming`, and AgentMail are wake-up signals; the durable content belongs in `Sync Log`. Grok Bot web cannot read local files, so anything it needs must be in Notion.

Do not write secrets to Notion, chat, git, or local rules. Store paths and public IDs only; secret material goes through Agenix. Do not paste whole conversations or store temporary guesses.
