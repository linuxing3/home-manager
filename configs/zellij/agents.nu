#!/usr/bin/env nu

# agents.nu - Multi-Agent Workspace Management Scripts
# Usage: source this file or use individual commands

# Project root directory
let AGENT_ROOT = $"($env.HOME)/.config/home-manager"
let AGENT_LOGS = $"($env.HOME)/.config/home-manager/.agent-logs"

# Initialize agent workspace
export def "agents init" [] {
    # Create log directory
    if not ($AGENT_LOGS | path exists) {
        mkdir $AGENT_LOGS
    }

    # Create empty log files
    touch $"($AGENT_LOGS)/planner.log"
    touch $"($AGENT_LOGS)/worker.log"
    touch $"($AGENT_LOGS)/reviewer.log"
    touch $"($AGENT_LOGS)/tasks.json"

    # Initialize tasks.json
    {
        tasks: [],
        current: null,
        created_at: (date now | format date "%Y-%m-%d %H:%M:%S")
    } | to json | save -f $"($AGENT_LOGS)/tasks.json"

    print $"(ansi green)Agent workspace initialized(ansi reset)"
    print $"Logs: ($AGENT_LOGS)"
}

# Launch the multi-agent workspace
export def "agents start" [] {
    # Initialize if needed
    if not ($AGENT_LOGS | path exists) {
        agents init
    }

    # Launch zellij with agents layout
    zellij --layout agents attach --create "agents"
}

# Create a new task for the agents
export def "agents task" [
    description: string    # Task description
    --priority: string = "medium"  # Priority: low, medium, high
] {
    let tasks_file = $"($AGENT_LOGS)/tasks.json"
    let tasks = if ($tasks_file | path exists) {
        open $tasks_file | get tasks
    } else {
        []
    }

    let new_task = {
        id: (random uuid),
        description: $description,
        priority: $priority,
        status: "pending",
        created_at: (date now | format date "%Y-%m-%d %H:%M:%S"),
        planner_output: null,
        worker_output: null,
        reviewer_output: null
    }

    let updated_tasks = $tasks | append $new_task

    {
        tasks: $updated_tasks,
        current: (if ($tasks | is-empty) { $new_task.id } else { null }),
        created_at: (open $tasks_file | get created_at)
    } | to json | save -f $tasks_file

    # Log to planner
    $"# New Task: ($description)\n\nPriority: ($priority)\nStatus: pending\nCreated: ($new_task.created_at)\n" | save -a $"($AGENT_LOGS)/planner.log"

    print $"(ansi green)Task created:(ansi reset) ($description)"
    print $"ID: ($new_task.id)"
}

# Update task status
export def "agents update" [
    task_id: string
    status: string     # pending, planning, executing, reviewing, completed
    --output: string   # Optional output to log
] {
    let tasks_file = $"($AGENT_LOGS)/tasks.json"
    let data = open $tasks_file

    let updated_tasks = $data.tasks | each {|task|
        if $task.id == $task_id {
            let updated = $task | merge {
                status: $status,
                ($status + "_at"): (date now | format date "%Y-%m-%d %H:%M:%S")
            }

            # Add output if provided
            if $output != null {
                match $status {
                    "planning" => { $updated | merge { planner_output: $output } }
                    "executing" => { $updated | merge { worker_output: $output } }
                    "reviewing" => { $updated | merge { reviewer_output: $output } }
                    _ => $updated
                }
            } else {
                $updated
            }
        } else {
            $task
        }
    }

    { tasks: $updated_tasks, current: $data.current, created_at: $data.created_at }
        | to json
        | save -f $tasks_file

    print $"(ansi yellow)Task updated:(ansi reset) $task_id -> $status"
}

# List all tasks
export def "agents list" [] {
    let tasks_file = $"($AGENT_LOGS)/tasks.json"

    if not ($tasks_file | path exists) {
        print "No tasks found. Run 'agents init' first."
        return
    }

    let tasks = open $tasks_file | get tasks

    if ($tasks | is-empty) {
        print "No tasks."
        return
    }

    print $tasks | table -e
}

# Log output to agent's log file
export def "agents log" [
    agent: string      # planner, worker, or reviewer
    message: string    # Message to log
] {
    let log_file = $"($AGENT_LOGS)/($agent).log"
    let timestamp = date now | format date "%H:%M:%S"

    $"[($timestamp)] ($message)\n" | save -a $log_file
    print $"(ansi green)Logged to ($agent):(ansi reset) $message"
}

# Notify user (similar to cmux notify)
export def "agents notify" [
    message: string
    --agent: string = "system"
] {
    let timestamp = date now | format date "%H:%M:%S"

    # Print to terminal with highlight
    print $"(ansi reverse)(ansi yellow) [($agent | str upcase)] ($message) [($timestamp)] (ansi reset)"

    # Also log
    agents log $agent $message

    # Try desktop notification
    try {
        notify-send $"[$agent]" $message
    } catch {
        # Ignore if notify-send not available
    }
}

# Get current task
export def "agents current" [] {
    let tasks_file = $"($AGENT_LOGS)/tasks.json"

    if not ($tasks_file | path exists) {
        print "No tasks found."
        return
    }

    let data = open $tasks_file

    if $data.current == null {
        print "No current task."
        return
    }

    $data.tasks | where id == $data.current | first
}

# Complete current task
export def "agents complete" [] {
    let tasks_file = $"($AGENT_LOGS)/tasks.json"
    let data = open $tasks_file

    if $data.current == null {
        print "No current task to complete."
        return
    }

    agents update $data.current "completed"

    # Find next pending task
    let next = $data.tasks | where status == "pending" | first

    {
        tasks: $data.tasks,
        current: (if $next != null { $next.id } else { null }),
        created_at: $data.created_at
    } | to json | save -f $tasks_file

    agents notify --agent "system" "Task completed!"

    if $next != null {
        print $"(ansi green)Next task:(ansi reset) ($next.description)"
    }
}

# Show help
export def "agents help" [] {
    print "
(ansi bold)Multi-Agent Workspace Commands(ansi reset)

(ansi yellow)Workspace Management:(ansi reset)
  agents init          - Initialize agent workspace
  agents start         - Launch multi-agent zellij workspace

(ansi yellow)Task Management:(ansi reset)
  agents task <desc>   - Create new task
  agents list          - List all tasks
  agents current       - Show current task
  agents update <id> <status> - Update task status
  agents complete      - Complete current task

(ansi yellow)Logging:(ansi reset)
  agents log <agent> <msg>    - Log message to agent's log
  agents notify <msg> [--agent] - Send notification

(ansi yellow)Agents:(ansi reset)
  planner  - Codebuddy (planning/architecture)
  worker   - Codex (execution/code generation)
  reviewer - Cursor (review/feedback)
"
}

# Alias for quick start
export def "agents" [] {
    agents help
}
