#!/usr/bin/env python3
import json
import os
import subprocess
import sys


manifest_path, hermes, state_path = sys.argv[1:4]
with open(manifest_path, encoding="utf-8") as handle:
    desired = json.load(handle)["jobs"]


def list_jobs():
    try:
        with open(state_path, encoding="utf-8") as handle:
            payload = json.load(handle)
    except FileNotFoundError:
        return []
    return payload.get("jobs", payload if isinstance(payload, list) else [])


by_name = {job.get("name"): job for job in list_jobs()}
for job in desired:
    existing = by_name.get(job["name"])
    if existing:
        command = [
            hermes,
            "cron",
            "edit",
            existing["id"],
            "--schedule",
            job["schedule"],
            "--prompt",
            job["prompt"],
            "--name",
            job["name"],
            "--clear-skills",
        ]
        for skill in job.get("skills", []):
            command += ["--add-skill", skill]
    else:
        command = [
            hermes,
            "cron",
            "create",
            job["schedule"],
            job["prompt"],
            "--name",
            job["name"],
        ]
        for skill in job.get("skills", []):
            command += ["--skill", skill]
    deliver = existing.get("deliver") if existing else os.environ.get("HERMES_CRON_DELIVER")
    if deliver:
        command += ["--deliver", deliver]
    elif not existing:
        raise SystemExit(
            f"Set HERMES_CRON_DELIVER before restoring new job: {job['name']}"
        )
    command += [
        "--workdir",
        job["workdir"],
        "--model",
        job["model"],
        "--provider",
        job["provider"],
    ]
    subprocess.run(command, check=True)

    matched = next(item for item in list_jobs() if item.get("name") == job["name"])
    action = "resume" if job.get("enabled", True) else "pause"
    subprocess.run([hermes, "cron", action, matched["id"]], check=True)
