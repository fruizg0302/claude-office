# claude-office - Design Document

A Ruby TUI companion app that watches Claude Code's JSONL transcript files and renders animated kaomoji characters in a virtual terminal office. Built with Charm Ruby.

## Decisions

- **Usage mode:** Separate terminal window (fullscreen alt_screen)
- **Scope:** Single project at a time (auto-detect from CWD or explicit path)
- **Visual style:** Unicode + kaomoji-inspired characters
- **MVP scope:** Full animated office with pathfinding, sub-agents, and notifications
- **Distribution:** Standalone Ruby gem (`gem install claude-office`)
- **Layout:** Fixed smart auto-layout (desks arranged by agent count)
- **Architecture:** Pure Charm Ruby (bubbletea + lipgloss + harmonica + bubbles)

## Architecture

Elm Architecture via Bubbletea:

```
ClaudeOffice (Bubbletea::Model)
  init()   → start JSONL watcher thread, schedule tick at 30fps
  update() → handle TickMessage, AgentEvent, KeyMessage, WindowResize
  view()   → render grid + characters + status bar via Lipgloss
```

### Components

| Component | Responsibility |
|-----------|----------------|
| `ClaudeOffice` | Main Bubbletea model, orchestrates everything |
| `TranscriptWatcher` | Background thread, reads JSONL files, emits AgentEvent messages |
| `TranscriptParser` | JSONL line parsing into typed events |
| `Agent` | State machine per agent: idle, walking, working, waiting |
| `SubAgent` | Child agent spawned by Task tool, linked to parent |
| `OfficeGrid` | 2D tile grid (floor, desk, wall), auto-generated |
| `Pathfinder` | BFS on the grid for character movement |
| `SpringAnimator` | Wraps Harmonica springs for smooth position interpolation |
| `Renderer` | Composes grid + characters + bubbles + status bar |

## Data Flow

### Transcript location

```
~/.claude/projects/<project-slug>/*.jsonl
```

Slug is the project path with `/` replaced by `-`.

### Watcher flow

```
TranscriptWatcher (background thread)
  ├─ Scan project dir every 2s for new .jsonl files
  │   └─ New file → create Agent, emit AgentCreated
  └─ Per active file: read from last byte offset
      ├─ type: "assistant" + tool_use → emit ToolStart
      ├─ type: "user" + tool_result   → emit ToolDone
      ├─ type: "system" + turn_duration → emit TurnEnd
      ├─ type: "progress" (Task tool)  → emit SubAgentActivity
      └─ type: "assistant" + text only → idle timer → emit Waiting
```

### Agent state machine

```
idle → walking → working (typing/reading/running) → waiting → idle
```

- `idle`: No active tools, no recent activity
- `walking`: Pathfinding to desk, animated kaomoji
- `working`: Typing, reading, or running based on tool type
- `waiting`: Turn ended, needs user input

### Tool-to-animation mapping

| Tool | Animation | Status text |
|------|-----------|-------------|
| Read | reading | "Reading foo.rb" |
| Edit, Write | typing | "Editing foo.rb" |
| Bash | running | "Running: git status" |
| Glob, Grep | reading | "Searching files/code" |
| WebFetch, WebSearch | reading | "Fetching/searching web" |
| Task | spawns sub-agent | "Subtask: description" |
| AskUserQuestion | waiting | "Waiting for your answer" |

## Visual Design

### Screen layout

```
┌─ claude-office ── ~/my-project ──────────────────────────────┐
│                                                               │
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │
│  ░░ ┌─────┐           ┌─────┐           ┌─────┐        ░░  │
│  ░░ │ ▒▒▒ │           │ ▒▒▒ │           │ ▒▒▒ │        ░░  │
│  ░░ └──┬──┘           └──┬──┘           └──┬──┘        ░░  │
│  ░░  (o.o)~            (o.O)                            ░░  │
│  ░░  "Edit app.rb"     "Reading tests"                  ░░  │
│  ░░  └─ (o_o)                                           ░░  │
│  ░░     "Sub: search"                                   ░░  │
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │
│                                                               │
├───────────────────────────────────────────────────────────────┤
│ Agent 1: typing (2 subs) │ Agent 2: reading │ q: quit  🔔 on │
└───────────────────────────────────────────────────────────────┘
```

### Character sprites

```ruby
FACES = {
  idle:     "(o_o)",
  typing:   "(o.o)~",
  reading:  "(o.O)",
  running:  "(>.<)",
  waiting:  "(-.-)zzZ",
  walking:  ["(o_o)/", "(o_o)\\"],
}

SUB_AGENT_FACES = {
  active:  "(o_o)",
  waiting: "(-.-)",
}
```

### Desk and grid tiles

```ruby
DESK  = ["┌─────┐", "│ ▒▒▒ │", "└──┬──┘"]
FLOOR = "░░"
WALL  = "██"
```

### Speech bubbles

Lipgloss rounded border style for waiting/notification messages:

```ruby
def speech_bubble(text)
  Lipgloss::Style.new
    .border(:rounded)
    .border_foreground("#874BFD")
    .padding(0, 1)
    .render(text)
end
```

### Sub-agent display

Sub-agents appear indented below their parent with a tree connector:

```
(o.o)~  "Editing auth.rb"
└─ (o_o) "Subtask: explore"
```

### Color scheme

- Floor background: `#2D2D2D`
- Desk border: `#8B6914`
- Active agent: `#00D4AA`
- Waiting agent: `#FFD700`
- Speech bubble: `#874BFD`
- Status bar background: `#555555`

### Auto-layout algorithm

1. Count active agents
2. Arrange desks in rows (3 per row, evenly spaced)
3. Each desk has a chair position below it
4. Characters pathfind (BFS) to their assigned desk
5. Grid expands/contracts as agents join/leave

### Rendering pipeline (30fps)

1. Render base grid (floor + walls)
2. Place desks at computed positions
3. Overlay character sprites at current positions (spring-interpolated)
4. Render speech bubbles above waiting characters
5. Render sub-agents below parents with tree connector
6. Compose status bar
7. `Lipgloss.join_vertical(grid, separator, status_bar)`

## Notifications

- Terminal bell (`\a`) when agent enters waiting state
- Optional `--no-sound` flag to disable
- Future: system notification via terminal-notifier (macOS)

## Project Structure

```
claude-office/
├── bin/
│   └── claude-office
├── lib/
│   ├── claude_office.rb
│   └── claude_office/
│       ├── cli.rb
│       ├── app.rb
│       ├── transcript/
│       │   ├── watcher.rb
│       │   ├── parser.rb
│       │   └── events.rb
│       ├── agents/
│       │   ├── agent.rb
│       │   ├── sub_agent.rb
│       │   └── registry.rb
│       ├── office/
│       │   ├── grid.rb
│       │   ├── pathfinder.rb
│       │   └── desk.rb
│       ├── rendering/
│       │   ├── sprites.rb
│       │   ├── renderer.rb
│       │   └── theme.rb
│       ├── animation/
│       │   ├── spring_mover.rb
│       │   └── frame_cycle.rb
│       └── notification.rb
├── spec/
│   ├── transcript/
│   │   ├── parser_spec.rb
│   │   └── watcher_spec.rb
│   ├── agents/
│   │   └── agent_spec.rb
│   ├── office/
│   │   ├── grid_spec.rb
│   │   └── pathfinder_spec.rb
│   └── spec_helper.rb
├── claude-office.gemspec
├── Gemfile
├── Rakefile
├── LICENSE
└── README.md
```

## Dependencies

```ruby
spec.add_dependency "bubbletea", "~> 0.1"
spec.add_dependency "lipgloss", "~> 0.1"
spec.add_dependency "harmonica", "~> 0.1"
spec.add_dependency "bubbles", "~> 0.1"
```

Runtime requirements: Ruby 3.2+, Go 1.23+ (for native extension compilation).

## CLI

```
$ claude-office                    # auto-detect project from CWD
$ claude-office ~/workspace/myproj # explicit project path
$ claude-office --no-sound         # disable terminal bell
$ claude-office --version
$ claude-office --help
```
