# Global Codex working rules
- Prefer small, focused changes.
- Explain what files you changed and why.
- Do not edit unrelated files.
- Do not expose secrets.
- Ask before adding new production dependencies.
- Run relevant tests when possible.
- If a task is complex, make a short plan before editing.

## Application and source layout — iron rule
- Store third-party AI and desktop application source repositories and build trees under `/share/data/sources/ai/<project>`.
- Install runnable AppImages and other self-contained application artifacts under `/home/Designers/Applications`.
- After a successful remote build, download and install the artifact, then move any temporary source checkout into `/share/data/sources/ai`.
- Do not leave source repositories in `/home/Designers` or mix source trees with installed artifacts.

@/home/Designers/.codex/RTK.md
