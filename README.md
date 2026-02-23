# claude-office

A TUI companion for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — watch your AI coding sessions come alive as animated kaomoji characters in a virtual terminal office.

```
┌─ claude-office ─────────────────────────────────────────────┐
│                                                              │
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │
│  ░░ ┌─────┐           ┌─────┐           ┌─────┐        ░░  │
│  ░░ │ ▒▒▒ │           │ ▒▒▒ │           │ ▒▒▒ │        ░░  │
│  ░░ └──┬──┘           └──┬──┘           └──┬──┘        ░░  │
│  ░░  (o.o)~            (o.O)             (-.-)zzZ      ░░  │
│  ░░  "Edit app.rb"     "Reading tests"                  ░░  │
│  ░░  └─ (o_o)                                           ░░  │
│  ░░     "Sub: search"                                   ░░  │
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│ Agent 1: typing (1 sub) │ Agent 2: reading │ q: quit        │
└──────────────────────────────────────────────────────────────┘
```

## What it does

claude-office reads Claude Code's JSONL transcript files in real-time and renders an animated office where each Claude session is a kaomoji character sitting at a desk. Characters change expressions based on what tools Claude is using:

| Expression | State | Meaning |
|-----------|-------|---------|
| `(o_o)` | idle | Waiting between actions |
| `(o.o)~` | typing | Editing or writing files |
| `(o.O)` | reading | Reading files, searching code |
| `(>.<)` | running | Executing bash commands |
| `(-.-)zzZ` | waiting | Turn ended, needs your input |

Sub-agents spawned by the `Task` tool appear indented below their parent with a tree connector.

## Installation

```bash
gem install claude-office
```

**Requirements:** Ruby 3.2+

## Usage

```bash
# Watch Claude sessions in the current directory
claude-office

# Watch a specific project
claude-office ~/workspace/my-project

# Disable terminal bell notifications
claude-office --no-sound
```

Run this in a **separate terminal window** alongside your Claude Code session. The office updates in real-time at 30fps as Claude works.

Press `q` to quit.

## How it works

1. Claude Code writes JSONL transcripts to `~/.claude/projects/<project-slug>/`
2. claude-office polls that directory for new `.jsonl` files
3. Each file becomes an agent (kaomoji character) at a desk
4. Tool use events (`Read`, `Edit`, `Bash`, etc.) drive character animations
5. Sub-agents from `Task` tool calls appear as child characters
6. When a turn ends, the character enters a waiting state with a speech bubble

## Architecture

Built with the [Charm Ruby](https://github.com/nicholaides/charm-ruby) ecosystem:

- **[bubbletea](https://rubygems.org/gems/bubbletea)** — Elm Architecture TUI framework
- **[lipgloss](https://rubygems.org/gems/lipgloss)** — Terminal styling and layout
- **[harmonica](https://rubygems.org/gems/harmonica)** — Spring-based animation physics

### Components

| Component | Purpose |
|-----------|---------|
| `Transcript::Watcher` | Background thread polling JSONL files |
| `Transcript::Parser` | Converts JSONL lines into typed events |
| `Agents::Agent` | State machine: idle / working / waiting |
| `Agents::SubAgent` | Child agent tracking for Task tool |
| `Office::Grid` | 2D tile grid with auto-layout |
| `Office::Pathfinder` | BFS pathfinding for character movement |
| `Rendering::Renderer` | Composites grid + characters + status bar |
| `Animation::SpringMover` | Smooth position interpolation |

## Development

```bash
git clone https://github.com/fruizg0302/claude-office.git
cd claude-office
bundle install
bundle exec rspec
```

## License

[MIT](LICENSE)
