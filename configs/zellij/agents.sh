#!/usr/bin/env bash
# agents.sh - Multi-Agent Workspace Launcher
# Usage: ./agents.sh [command]

set -e

AGENT_ROOT="$HOME/.config/home-manager"
AGENT_LOGS="$AGENT_ROOT/.agent-logs"
ZELLIX_PATH="$HOME/.config/home-manager/configs/zellij"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize agent workspace
agents_init() {
    mkdir -p "$AGENT_LOGS"
    touch "$AGENT_LOGS/planner.log"
    touch "$AGENT_LOGS/worker.log"
    touch "$AGENT_LOGS/reviewer.log"

    if [[ ! -f "$AGENT_LOGS/tasks.json" ]]; then
        cat > "$AGENT_LOGS/tasks.json" << EOF
{
    "tasks": [],
    "current": null,
    "created_at": "$(date '+%Y-%m-%d %H:%M:%S')"
}
EOF
    fi

    echo -e "${GREEN}Agent workspace initialized${NC}"
    echo "Logs: $AGENT_LOGS"
}

# Start the workspace
agents_start() {
    if [[ ! -d "$AGENT_LOGS" ]]; then
        agents_init
    fi

    # Check if session exists
    if zellij list-sessions 2>/dev/null | grep -q "^agents"; then
        echo -e "${YELLOW}Attaching to existing 'agents' session${NC}"
        zellij attach agents
    else
        echo -e "${GREEN}Starting new 'agents' workspace${NC}"
        zellij --layout agents attach --create agents
    fi
}

# Create a new task
agents_task() {
    local description="$1"
    local priority="${2:-medium}"

    if [[ -z "$description" ]]; then
        echo -e "${RED}Error: Task description required${NC}"
        exit 1
    fi

    local task_id=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "task-$(date +%s)")
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Append to tasks.json (simple approach - in production use jq)
    echo "# New Task: $description
Priority: $priority
Status: pending
Created: $timestamp
ID: $task_id
" >> "$AGENT_LOGS/planner.log"

    echo -e "${GREEN}Task created:${NC} $description"
    echo "ID: $task_id"
}

# Notify user
agents_notify() {
    local message="$1"
    local agent="${2:-system}"
    local timestamp=$(date '+%H:%M:%S')

    echo -e "\033[7m\033[33m [$agent | $timestamp] $message \033[0m"

    # Log it
    echo "[$timestamp] [$agent] $message" >> "$AGENT_LOGS/${agent}.log"

    # Desktop notification if available
    if command -v notify-send &> /dev/null; then
        notify-send "[$agent]" "$message"
    fi
}

# Show status
agents_status() {
    echo -e "${BLUE}=== Agent Workspace Status ===${NC}"
    echo ""

    if [[ -d "$AGENT_LOGS" ]]; then
        echo -e "${YELLOW}Logs:${NC}"
        for log in planner worker reviewer; do
            if [[ -f "$AGENT_LOGS/${log}.log" ]]; then
                local lines=$(wc -l < "$AGENT_LOGS/${log}.log")
                echo "  $log.log: $lines lines"
            fi
        done
    else
        echo "Not initialized. Run: $0 init"
    fi

    echo ""
    echo -e "${YELLOW}Zellij Sessions:${NC}"
    zellij list-sessions 2>/dev/null || echo "  No active sessions"
}

# Quick switch to agent tab
agents_switch() {
    local agent="$1"
    case "$agent" in
        planner|p|1)
            zellij action go-to-tab-name planner
            ;;
        worker|w|2)
            zellij action go-to-tab-name worker
            ;;
        reviewer|r|3)
            zellij action go-to-tab-name reviewer
            ;;
        tasks|t|4)
            zellij action go-to-tab-name tasks
            ;;
        *)
            echo -e "${RED}Unknown agent: $agent${NC}"
            echo "Options: planner, worker, reviewer, tasks"
            ;;
    esac
}

# Help
agents_help() {
    echo "
${GREEN}Multi-Agent Workspace${NC}

${YELLOW}Usage:${NC} $0 <command>

${YELLOW}Commands:${NC}
  init          Initialize agent workspace
  start         Launch zellij multi-agent workspace
  status        Show workspace status
  task <desc>   Create a new task
  notify <msg>  Send notification
  switch <agent> Switch to agent tab (planner|worker|reviewer|tasks)
  help          Show this help

${YELLOW}Agents:${NC}
  ${GREEN}planner${NC}  - Codebuddy (planning/architecture)
  ${YELLOW}worker${NC}   - Codex (execution/code generation)
  ${BLUE}reviewer${NC} - Cursor (review/feedback)

${YELLOW}Layout:${NC}
  Tab 1: Planner (Codebuddy) - Plan tasks
  Tab 2: Worker (Codex)      - Execute tasks
  Tab 3: Reviewer (Cursor)   - Review code
  Tab 4: Tasks Dashboard     - View all outputs
"
}

# Main
case "${1:-help}" in
    init)
        agents_init
        ;;
    start)
        agents_start
        ;;
    status)
        agents_status
        ;;
    task)
        agents_task "$2" "$3"
        ;;
    notify)
        agents_notify "$2" "$3"
        ;;
    switch)
        agents_switch "$2"
        ;;
    help|--help|-h)
        agents_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        agents_help
        exit 1
        ;;
esac
