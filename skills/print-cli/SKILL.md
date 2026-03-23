---
name: print-cli
description: Print files from terminal with explicit A4 media settings, including queue checks, job cancellation, and basic CUPS diagnostics.
---

# print-cli

Print files from CLI with explicit A4 paper size.

## Use this skill when
- User asks to print from terminal.
- User asks to enforce A4 page size.
- User asks to check queue, cancel jobs, or inspect printer options.

## Required inputs
- Printer name (example: `HP-Color-LaserJet-Pro-M252n`)
- File path

## Primary commands

### Print PDF/text on A4
```bash
lp -d HP-Color-LaserJet-Pro-M252n -o media=A4 /path/to/file.pdf
```

### Show printer media options
```bash
lpoptions -p HP-Color-LaserJet-Pro-M252n -l | rg media
```

### Check queue / jobs
```bash
lpstat -o
```

### Cancel a job
```bash
cancel <job-id>
```

## Image workflow (recommended)
Convert image to PDF first, then print A4:
```bash
convert input.png -page A4 output.pdf
lp -d HP-Color-LaserJet-Pro-M252n -o media=A4 output.pdf
```

## Quick diagnostics
```bash
systemctl status cups --no-pager
lpstat -p -d
```
