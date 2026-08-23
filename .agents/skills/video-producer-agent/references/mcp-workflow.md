# MCP workflow recommendations for the Video Producer Agent

Use MCP servers to connect the agent to assets, planning tools, publishing channels, and browser automation. Only enable MCP servers you trust.

## Recommended MCP capabilities

### File system MCP

Use for:

- Creating project folders
- Saving scripts and briefs
- Organizing voiceovers, exports, thumbnails, and prompts
- Reading local brand guidelines

Suggested folder structure:

```text
video-projects/
  yyyy-mm-dd-topic-slug/
    01-brief/
    02-script/
    03-voiceover/
    04-visual-prompts/
    05-canva-assets/
    06-exports/
    07-publishing/
```

### Google Drive MCP

Use for:

- Pulling brand assets from Drive
- Saving final briefs and scripts
- Sharing drafts with collaborators
- Keeping client/project folders synced

### Browser automation MCP or agent-browser

Use for tools with limited public automation APIs:

- Canva layout tasks
- Google Vids/Flow prompt entry
- Downloading generated outputs
- Upload/draft workflows

Keep browser automation semi-supervised for account, payment, OAuth, or publishing actions.

### Notion / Airtable MCP

Use for:

- Content calendar
- Production pipeline
- Idea backlog
- Asset database
- Approval tracking

Pipeline fields:

```text
Idea | Platform | Status | Script | Voiceover | Visuals | Edit | Review | Publish Date | URL | Metrics
```

### YouTube MCP

Use for:

- Creating upload drafts
- Generating titles/descriptions/tags
- Reading comments for future video ideas
- Tracking published links

### ElevenLabs API/MCP wrapper

Use for:

- Creating voiceover clips
- Listing available voices
- Generating multilingual versions
- Saving audio files into project folders

If no MCP exists, use the skill to prepare voiceover-ready text and run ElevenLabs manually.

## Suggested agent chain

1. Research/strategy agent: finds angle, audience pains, competitor hooks.
2. Video Producer Agent: creates script, storyboard, prompts, and production brief.
3. Voice Agent: generates ElevenLabs clips.
4. Design Agent: creates Canva layout instructions and thumbnails.
5. Publishing Agent: prepares platform metadata and scheduling checklist.

## Safety and review

- Do not auto-publish without explicit user approval.
- Do not use copyrighted music, logos, or celebrity likenesses unless rights are clear.
- Label AI-generated or synthetic voice content when required by platform/client policy.
- Keep API keys and OAuth tokens out of project files.
