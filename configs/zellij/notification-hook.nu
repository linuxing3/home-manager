# notification-hook.nu
# Agent completion notification hooks
# Source this file to enable notifications when agents complete tasks

# Hook for Codebuddy (Planner) completion
export def "hook planner-done" [] {
    let last_exit = $env.LAST_EXIT_CODE? | default 0

    if $last_exit == 0 {
        agents notify --agent "planner" "Planning completed! Ready for worker."
        # Play notification sound if available
        try { paplay /usr/share/sounds/freedesktop/stereo/complete.oga } catch {}
    } else {
        agents notify --agent "planner" "Planning failed or needs attention."
    }
}

# Hook for Codex (Worker) completion
export def "hook worker-done" [] {
    let last_exit = $env.LAST_EXIT_CODE? | default 0

    if $last_exit == 0 {
        agents notify --agent "worker" "Task execution completed! Ready for review."
        try { paplay /usr/share/sounds/freedesktop/stereo/complete.oga } catch {}
    } else {
        agents notify --agent "worker" "Execution failed or needs attention."
    }
}

# Hook for Cursor (Reviewer) completion
export def "hook reviewer-done" [] {
    let last_exit = $env.LAST_EXIT_CODE? | default 0

    if $last_exit == 0 {
        agents notify --agent "reviewer" "Review completed! Changes approved."
        try { paplay /usr/share/sounds/freedesktop/stereo/complete.oga } catch {}
    } else {
        agents notify --agent "reviewer" "Review found issues. Needs fixes."
    }
}

# Watch for changes in log files and notify
export def "agents watch" [] {
    print "Watching agent logs for changes..."

    # This is a simplified version - in production use watchexec or similar
    loop {
        sleep 5sec

        # Check each log file for new "DONE" markers
        for agent in ["planner" "worker" "reviewer"] {
            let log_file = $"($env.HOME)/.config/home-manager/.agent-logs/($agent).log"
            if ($log_file | path exists) {
                let last_line = open $log_file | lines | last
                if ($last_line | str contains "DONE") {
                    agents notify --agent $agent "Task completed!"
                }
            }
        }
    }
}

# OSC 9/99/777 terminal notification sequences (cmux-compatible)
export def "term-notify" [
    message: string
    --title: string = "Agent"
] {
    # OSC 9 - iTerm2/Ghostty compatible
    print $"(char -u 1b)]9;($title): ($message)(char -u 07)"

    # OSC 99 - Draft specification
    print $"(char -u 1b)]99;i=($env.USER);d=($title);p=body;($message)(char -u 07)"

    # OSC 777 - iTerm2 notify
    print $"(char -u 1b)]777;notify;($title);($message)(char -u 07)"
}

# Pre-command hook to track agent activity
export def --env "preexec-hook" [] {
    $env.AGENT_START_TIME = (date now)
}

# Post-command hook for notifications
export def --env "postexec-hook" [] {
    if "AGENT_START_TIME" in $env {
        let duration = (date now) - $env.AGENT_START_TIME
        let exit_code = $env.LAST_EXIT_CODE? | default 0

        # If command took more than 30 seconds and succeeded, notify
        if ($duration > 30sec) and ($exit_code == 0) {
            agents notify --agent "shell" "Long-running command completed."
        }
    }
}
