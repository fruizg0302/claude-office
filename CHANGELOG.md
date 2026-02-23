# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-22

### Added

- Initial release
- JSONL transcript parser with 7 event types (AgentCreated, ToolStart, ToolDone, TurnEnd, SubAgentToolStart, SubAgentToolDone, TextOnly)
- Background file watcher with polling-based JSONL discovery
- Agent state machine with idle, working, and waiting states
- Sub-agent tracking for Task tool spawned agents
- Office grid with auto-layout (3 desks per row) and BFS pathfinding
- Kaomoji character sprites with tool-based animations
- Lipgloss-styled rendering with themed colors
- Spring-based movement animation via Harmonica
- Terminal bell notifications on turn end
- CLI with `--no-sound`, `--version`, and `--help` flags
- Full alt-screen TUI at 30fps via Bubbletea

[0.1.0]: https://github.com/fruizg0302/claude-office/releases/tag/v0.1.0
