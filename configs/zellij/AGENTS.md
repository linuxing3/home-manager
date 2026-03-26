# AGENTS.md - Multi-Agent Workspace Configuration

## Overview

This workspace implements a three-role AI agent collaboration pattern inspired by [cmux](https://github.com/manaflow-ai/cmux):

```
┌─────────────────────────────────────────────────────────────┐
│  PLANNER (Codebuddy)                                        │
│  - 分析需求，制定计划                                        │
│  - 设计架构，拆分任务                                        │
│  - 输出: 任务清单、技术方案                                   │
└──────────────────────┬──────────────────────────────────────┘
                       │ Tasks
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  WORKER (Codex)                                             │
│  - 执行任务，生成代码                                        │
│  - 实现功能，修复问题                                        │
│  - 输出: 代码变更、实现结果                                   │
└──────────────────────┬──────────────────────────────────────┘
                       │ Code Changes
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  REVIEWER (Cursor)                                          │
│  - 审核代码质量                                              │
│  - 检查安全、性能、风格                                       │
│  - 输出: 审核意见、改进建议                                   │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# Initialize and start
./agents.sh init
./agents.sh start

# Or use nushell
source agents.nu
agents init
agents start
```

## Layout Structure

| Tab | Name | Purpose |
|-----|------|---------|
| 1 | planner | Codebuddy - 规划任务 |
| 2 | worker | Codex - 执行任务 |
| 3 | reviewer | Cursor - 审核代码 |
| 4 | tasks | 任务面板 - 查看所有输出 |
| 5 | shell | 备用终端 |

## Commands

### Task Management

```bash
# Create task
agents task "实现用户认证功能"

# List tasks
agents list

# Update task status
agents update <task-id> planning

# Complete current task
agents complete
```

### Notifications

```bash
# Manual notification
agents notify "Task completed!" --agent planner

# Terminal OSC notification (cmux-compatible)
term-notify "Review needed"
```

### Workspace Control

```bash
# Start workspace
agents start

# Check status
agents status

# Switch tabs
agents switch planner
agents switch worker
agents switch reviewer
```

## Files

```
configs/zellij/
├── agents.kdl           # Zellij 布局配置
├── agents.nu            # Nushell 管理脚本
├── agents.sh            # Bash 管理脚本
├── notification-hook.nu # 通知钩子
└── AGENTS.md            # 本文档
```

## Workflow

1. **Planner** 分析需求，创建任务清单
2. **Worker** 执行任务，生成代码
3. **Reviewer** 审核变更，提出改进
4. 循环直到完成

## Comparison with cmux

| Feature | cmux | This Setup |
|---------|------|------------|
| Terminal | Ghostty (macOS) | Zellij (Linux) |
| Notification | OSC sequences + CLI | notify-send + OSC |
| Layout | Native macOS app | Zellij KDL layout |
| Roles | Not defined | 3 agents defined |
| Control | Socket API | Zellij actions |

## Key Bindings

| Key | Action |
|-----|--------|
| Alt+1-5 | Go to tab 1-5 |
| Alt+z | Toggle lock mode |
| Alt+d | New pane down |
| Alt+v | New pane right |
| Alt+H/L | Previous/Next tab |
