# print-cli

Canonical source: `skills/print-cli/SKILL.md`.

Use these core commands:

```bash
lp -d HP-Color-LaserJet-Pro-M252n -o media=A4 /path/to/file.pdf
lpoptions -p HP-Color-LaserJet-Pro-M252n -l | rg media
lpstat -o
cancel <job-id>
```
