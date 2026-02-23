# claude-office Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Ruby TUI app that watches Claude Code's JSONL transcripts and renders animated kaomoji characters in a virtual terminal office.

**Architecture:** Elm Architecture via Charm Ruby's bubbletea gem. A background thread polls JSONL files and pushes events into the Bubbletea event loop. The view renders a 2D office grid with characters, desks, speech bubbles, and a status bar using lipgloss for layout/styling and harmonica for spring-based movement animation.

**Tech Stack:** Ruby 3.2+, bubbletea (TUI framework), lipgloss (styling/layout), harmonica (spring physics), bubbles (pre-built components), rspec (testing)

---

### Task 1: Project Scaffold — Gemspec, Gemfile, Rakefile, CLI Entry Point

**Files:**
- Create: `claude-office.gemspec`
- Create: `Gemfile`
- Create: `Rakefile`
- Create: `bin/claude-office`
- Create: `lib/claude_office.rb`
- Create: `lib/claude_office/version.rb`
- Create: `.gitignore`
- Create: `.rspec`
- Create: `spec/spec_helper.rb`

**Step 1: Create .gitignore**

```gitignore
*.gem
*.rbc
/.config
/coverage/
/InstalledFiles
/pkg/
/spec/reports/
/spec/examples.txt
/test/tmp/
/test/version_tmp/
/tmp/
/.bundle/
/vendor/bundle
*.bundle
*.so
*.o
*.a
mkmf.log
Gemfile.lock
```

**Step 2: Create version file**

```ruby
# lib/claude_office/version.rb
module ClaudeOffice
  VERSION = "0.1.0"
end
```

**Step 3: Create gemspec**

```ruby
# claude-office.gemspec
require_relative "lib/claude_office/version"

Gem::Specification.new do |spec|
  spec.name = "claude-office"
  spec.version = ClaudeOffice::VERSION
  spec.authors = ["Your Name"]
  spec.summary = "A TUI companion for Claude Code — animated kaomoji agents in a virtual office"
  spec.description = "Watch Claude Code sessions come alive as kaomoji characters in a terminal office. " \
                     "Characters walk, type, read, and wait based on real-time JSONL transcript data."
  spec.homepage = "https://github.com/yourusername/claude-office"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.files = Dir["lib/**/*", "bin/*", "LICENSE", "README.md"]
  spec.bindir = "bin"
  spec.executables = ["claude-office"]

  spec.add_dependency "bubbletea", "~> 0.1"
  spec.add_dependency "lipgloss", "~> 0.2"
  spec.add_dependency "harmonica", "~> 0.1"

  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rake", "~> 13.0"
end
```

**Step 4: Create Gemfile**

```ruby
# Gemfile
source "https://rubygems.org"
gemspec
```

**Step 5: Create Rakefile**

```ruby
# Rakefile
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)
task default: :spec
```

**Step 6: Create .rspec**

```
--format documentation
--color
--require spec_helper
```

**Step 7: Create spec_helper**

```ruby
# spec/spec_helper.rb
require "claude_office"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand config.seed
end
```

**Step 8: Create main require file**

```ruby
# lib/claude_office.rb
require_relative "claude_office/version"

module ClaudeOffice
end
```

**Step 9: Create CLI entry point**

```ruby
#!/usr/bin/env ruby
# bin/claude-office

require_relative "../lib/claude_office"
require_relative "../lib/claude_office/cli"

ClaudeOffice::CLI.run(ARGV)
```

**Step 10: Create CLI stub**

```ruby
# lib/claude_office/cli.rb
module ClaudeOffice
  class CLI
    def self.run(args)
      if args.include?("--version")
        puts "claude-office #{ClaudeOffice::VERSION}"
        return
      end

      if args.include?("--help")
        puts <<~HELP
          Usage: claude-office [PROJECT_PATH] [OPTIONS]

          Watch Claude Code sessions as animated characters in a terminal office.

          Arguments:
            PROJECT_PATH    Path to project (default: current directory)

          Options:
            --no-sound      Disable terminal bell notifications
            --version       Show version
            --help          Show this help
        HELP
        return
      end

      project_path = args.reject { |a| a.start_with?("--") }.first || Dir.pwd
      sound = !args.include?("--no-sound")

      puts "claude-office #{ClaudeOffice::VERSION}"
      puts "Project: #{project_path}"
      puts "Sound: #{sound ? "on" : "off"}"
      puts "(TUI not yet implemented)"
    end
  end
end
```

**Step 11: Install dependencies and verify**

Run: `cd /Volumes/MacintoshEDD/workspace/claude-office && bundle install`
Expected: Successful gem resolution and install.

**Step 12: Run the CLI to verify scaffold works**

Run: `cd /Volumes/MacintoshEDD/workspace/claude-office && ruby bin/claude-office --version`
Expected: `claude-office 0.1.0`

Run: `cd /Volumes/MacintoshEDD/workspace/claude-office && ruby bin/claude-office --help`
Expected: Help text with usage info.

**Step 13: Run specs (empty but should pass)**

Run: `cd /Volumes/MacintoshEDD/workspace/claude-office && bundle exec rspec`
Expected: 0 examples, 0 failures

**Step 14: Commit**

```bash
git add -A
git commit -m "feat: scaffold gem structure with CLI entry point"
```

---

### Task 2: Transcript Event Types and Parser

**Files:**
- Create: `lib/claude_office/transcript/events.rb`
- Create: `lib/claude_office/transcript/parser.rb`
- Create: `spec/transcript/parser_spec.rb`

**Step 1: Write the event types**

These are simple data classes representing parsed JSONL events.

```ruby
# lib/claude_office/transcript/events.rb
module ClaudeOffice
  module Transcript
    class AgentCreated
      attr_reader :session_id, :jsonl_path

      def initialize(session_id:, jsonl_path:)
        @session_id = session_id
        @jsonl_path = jsonl_path
      end
    end

    class ToolStart
      attr_reader :session_id, :tool_id, :tool_name, :status_text

      def initialize(session_id:, tool_id:, tool_name:, status_text:)
        @session_id = session_id
        @tool_id = tool_id
        @tool_name = tool_name
        @status_text = status_text
      end
    end

    class ToolDone
      attr_reader :session_id, :tool_id

      def initialize(session_id:, tool_id:)
        @session_id = session_id
        @tool_id = tool_id
      end
    end

    class TurnEnd
      attr_reader :session_id, :duration_ms

      def initialize(session_id:, duration_ms:)
        @session_id = session_id
        @duration_ms = duration_ms
      end
    end

    class SubAgentToolStart
      attr_reader :session_id, :parent_tool_id, :tool_id, :tool_name, :status_text

      def initialize(session_id:, parent_tool_id:, tool_id:, tool_name:, status_text:)
        @session_id = session_id
        @parent_tool_id = parent_tool_id
        @tool_id = tool_id
        @tool_name = tool_name
        @status_text = status_text
      end
    end

    class SubAgentToolDone
      attr_reader :session_id, :parent_tool_id, :tool_id

      def initialize(session_id:, parent_tool_id:, tool_id:)
        @session_id = session_id
        @parent_tool_id = parent_tool_id
        @tool_id = tool_id
      end
    end

    class TextOnly
      attr_reader :session_id

      def initialize(session_id:)
        @session_id = session_id
      end
    end
  end
end
```

**Step 2: Write parser tests**

```ruby
# spec/transcript/parser_spec.rb
require "spec_helper"
require "claude_office/transcript/parser"
require "claude_office/transcript/events"
require "json"

RSpec.describe ClaudeOffice::Transcript::Parser do
  let(:session_id) { "test-session-123" }
  let(:parser) { described_class.new(session_id) }

  describe "#parse_line" do
    it "returns ToolStart for assistant message with tool_use" do
      line = JSON.generate({
        type: "assistant",
        message: {
          role: "assistant",
          content: [
            {
              type: "tool_use",
              id: "tool_abc",
              name: "Read",
              input: { file_path: "/path/to/foo.rb" }
            }
          ]
        }
      })

      events = parser.parse_line(line)
      expect(events.length).to eq(1)
      expect(events.first).to be_a(ClaudeOffice::Transcript::ToolStart)
      expect(events.first.tool_name).to eq("Read")
      expect(events.first.status_text).to eq("Reading foo.rb")
      expect(events.first.tool_id).to eq("tool_abc")
    end

    it "returns ToolDone for user message with tool_result" do
      line = JSON.generate({
        type: "user",
        message: {
          role: "user",
          content: [
            {
              type: "tool_result",
              tool_use_id: "tool_abc"
            }
          ]
        }
      })

      events = parser.parse_line(line)
      expect(events.length).to eq(1)
      expect(events.first).to be_a(ClaudeOffice::Transcript::ToolDone)
      expect(events.first.tool_id).to eq("tool_abc")
    end

    it "returns TurnEnd for system turn_duration" do
      line = JSON.generate({
        type: "system",
        subtype: "turn_duration",
        durationMs: 5000
      })

      events = parser.parse_line(line)
      expect(events.length).to eq(1)
      expect(events.first).to be_a(ClaudeOffice::Transcript::TurnEnd)
      expect(events.first.duration_ms).to eq(5000)
    end

    it "returns TextOnly for assistant message with only text" do
      line = JSON.generate({
        type: "assistant",
        message: {
          role: "assistant",
          content: [
            { type: "text", text: "Hello world" }
          ]
        }
      })

      events = parser.parse_line(line)
      expect(events.length).to eq(1)
      expect(events.first).to be_a(ClaudeOffice::Transcript::TextOnly)
    end

    it "returns multiple ToolStart events for multiple tool_use blocks" do
      line = JSON.generate({
        type: "assistant",
        message: {
          role: "assistant",
          content: [
            { type: "tool_use", id: "t1", name: "Read", input: { file_path: "/a.rb" } },
            { type: "tool_use", id: "t2", name: "Bash", input: { command: "ls" } }
          ]
        }
      })

      events = parser.parse_line(line)
      expect(events.length).to eq(2)
      expect(events[0].tool_name).to eq("Read")
      expect(events[1].tool_name).to eq("Bash")
    end

    it "formats Edit tool status correctly" do
      line = JSON.generate({
        type: "assistant",
        message: {
          role: "assistant",
          content: [
            { type: "tool_use", id: "t1", name: "Edit", input: { file_path: "/path/to/app.rb" } }
          ]
        }
      })

      events = parser.parse_line(line)
      expect(events.first.status_text).to eq("Editing app.rb")
    end

    it "formats Bash tool status with truncated command" do
      long_command = "a" * 60
      line = JSON.generate({
        type: "assistant",
        message: {
          role: "assistant",
          content: [
            { type: "tool_use", id: "t1", name: "Bash", input: { command: long_command } }
          ]
        }
      })

      events = parser.parse_line(line)
      expect(events.first.status_text.length).to be <= 55
      expect(events.first.status_text).to end_with("…")
    end

    it "formats Task tool status with description" do
      line = JSON.generate({
        type: "assistant",
        message: {
          role: "assistant",
          content: [
            { type: "tool_use", id: "t1", name: "Task", input: { description: "explore codebase" } }
          ]
        }
      })

      events = parser.parse_line(line)
      expect(events.first.status_text).to eq("Subtask: explore codebase")
    end

    it "returns empty array for malformed JSON" do
      events = parser.parse_line("not json at all")
      expect(events).to eq([])
    end

    it "returns empty array for irrelevant record types" do
      line = JSON.generate({ type: "file-history-snapshot" })
      events = parser.parse_line(line)
      expect(events).to eq([])
    end

    it "handles new user text prompt (string content)" do
      line = JSON.generate({
        type: "user",
        message: {
          role: "user",
          content: "Fix the auth bug"
        }
      })

      events = parser.parse_line(line)
      # New user prompt is informational, no event needed
      expect(events).to eq([])
    end

    context "sub-agent progress events" do
      it "returns SubAgentToolStart for progress with Task tool_use" do
        line = JSON.generate({
          type: "progress",
          parentToolUseID: "parent_task_1",
          data: {
            type: "agent_progress",
            message: {
              type: "assistant",
              message: {
                content: [
                  { type: "tool_use", id: "sub_t1", name: "Read", input: { file_path: "/sub/file.rb" } }
                ]
              }
            }
          }
        })

        # Parser needs to know parent_task_1 is a Task tool
        parser.register_active_tool("parent_task_1", "Task")
        events = parser.parse_line(line)
        expect(events.length).to eq(1)
        expect(events.first).to be_a(ClaudeOffice::Transcript::SubAgentToolStart)
        expect(events.first.parent_tool_id).to eq("parent_task_1")
        expect(events.first.tool_name).to eq("Read")
      end

      it "returns SubAgentToolDone for progress with tool_result" do
        line = JSON.generate({
          type: "progress",
          parentToolUseID: "parent_task_1",
          data: {
            type: "agent_progress",
            message: {
              type: "user",
              message: {
                content: [
                  { type: "tool_result", tool_use_id: "sub_t1" }
                ]
              }
            }
          }
        })

        parser.register_active_tool("parent_task_1", "Task")
        events = parser.parse_line(line)
        expect(events.length).to eq(1)
        expect(events.first).to be_a(ClaudeOffice::Transcript::SubAgentToolDone)
        expect(events.first.tool_id).to eq("sub_t1")
      end
    end
  end
end
```

**Step 3: Run tests to verify they fail**

Run: `cd /Volumes/MacintoshEDD/workspace/claude-office && bundle exec rspec spec/transcript/parser_spec.rb`
Expected: FAIL — `cannot load such file -- claude_office/transcript/parser`

**Step 4: Write the parser implementation**

```ruby
# lib/claude_office/transcript/parser.rb
require "json"
require_relative "events"

module ClaudeOffice
  module Transcript
    class Parser
      BASH_COMMAND_MAX_LENGTH = 40
      TASK_DESCRIPTION_MAX_LENGTH = 40

      def initialize(session_id)
        @session_id = session_id
        @active_tools = {} # tool_id => tool_name
      end

      def register_active_tool(tool_id, tool_name)
        @active_tools[tool_id] = tool_name
      end

      def unregister_active_tool(tool_id)
        @active_tools.delete(tool_id)
      end

      def parse_line(line)
        record = JSON.parse(line)
        type = record["type"]

        case type
        when "assistant"
          parse_assistant(record)
        when "user"
          parse_user(record)
        when "system"
          parse_system(record)
        when "progress"
          parse_progress(record)
        else
          []
        end
      rescue JSON::ParserError
        []
      end

      private

      def parse_assistant(record)
        content = record.dig("message", "content")
        return [] unless content.is_a?(Array)

        tool_uses = content.select { |b| b["type"] == "tool_use" }

        if tool_uses.any?
          tool_uses.map do |block|
            tool_name = block["name"] || ""
            input = block["input"] || {}
            status = format_tool_status(tool_name, input)

            register_active_tool(block["id"], tool_name)

            ToolStart.new(
              session_id: @session_id,
              tool_id: block["id"],
              tool_name: tool_name,
              status_text: status
            )
          end
        elsif content.any? { |b| b["type"] == "text" }
          [TextOnly.new(session_id: @session_id)]
        else
          []
        end
      end

      def parse_user(record)
        content = record.dig("message", "content")

        if content.is_a?(Array)
          tool_results = content.select { |b| b["type"] == "tool_result" }

          tool_results.map do |block|
            tool_id = block["tool_use_id"]
            unregister_active_tool(tool_id)
            ToolDone.new(session_id: @session_id, tool_id: tool_id)
          end
        else
          []
        end
      end

      def parse_system(record)
        return [] unless record["subtype"] == "turn_duration"

        [TurnEnd.new(
          session_id: @session_id,
          duration_ms: record["durationMs"]
        )]
      end

      def parse_progress(record)
        parent_tool_id = record["parentToolUseID"]
        return [] unless parent_tool_id
        return [] unless @active_tools[parent_tool_id] == "Task"

        data = record["data"]
        return [] unless data.is_a?(Hash)

        message = data.dig("message")
        return [] unless message.is_a?(Hash)

        msg_type = message["type"]
        inner_content = message.dig("message", "content")
        return [] unless inner_content.is_a?(Array)

        case msg_type
        when "assistant"
          inner_content.select { |b| b["type"] == "tool_use" }.map do |block|
            tool_name = block["name"] || ""
            input = block["input"] || {}
            status = format_tool_status(tool_name, input)

            SubAgentToolStart.new(
              session_id: @session_id,
              parent_tool_id: parent_tool_id,
              tool_id: block["id"],
              tool_name: tool_name,
              status_text: status
            )
          end
        when "user"
          inner_content.select { |b| b["type"] == "tool_result" }.map do |block|
            SubAgentToolDone.new(
              session_id: @session_id,
              parent_tool_id: parent_tool_id,
              tool_id: block["tool_use_id"]
            )
          end
        else
          []
        end
      end

      def format_tool_status(tool_name, input)
        case tool_name
        when "Read"
          "Reading #{basename(input["file_path"])}"
        when "Edit"
          "Editing #{basename(input["file_path"])}"
        when "Write"
          "Writing #{basename(input["file_path"])}"
        when "Bash"
          cmd = (input["command"] || "").to_s
          truncated = cmd.length > BASH_COMMAND_MAX_LENGTH ? "#{cmd[0...BASH_COMMAND_MAX_LENGTH]}…" : cmd
          "Running: #{truncated}"
        when "Glob"
          "Searching files"
        when "Grep"
          "Searching code"
        when "WebFetch"
          "Fetching web content"
        when "WebSearch"
          "Searching the web"
        when "Task"
          desc = (input["description"] || "").to_s
          truncated = desc.length > TASK_DESCRIPTION_MAX_LENGTH ? "#{desc[0...TASK_DESCRIPTION_MAX_LENGTH]}…" : desc
          truncated.empty? ? "Running subtask" : "Subtask: #{truncated}"
        when "AskUserQuestion"
          "Waiting for your answer"
        when "EnterPlanMode"
          "Planning"
        when "NotebookEdit"
          "Editing notebook"
        else
          "Using #{tool_name}"
        end
      end

      def basename(path)
        return "" unless path.is_a?(String)

        File.basename(path)
      end
    end
  end
end
```

**Step 5: Update main require**

```ruby
# lib/claude_office.rb
require_relative "claude_office/version"
require_relative "claude_office/transcript/events"
require_relative "claude_office/transcript/parser"

module ClaudeOffice
end
```

**Step 6: Run tests to verify they pass**

Run: `cd /Volumes/MacintoshEDD/workspace/claude-office && bundle exec rspec spec/transcript/parser_spec.rb`
Expected: All tests pass

**Step 7: Commit**

```bash
git add lib/claude_office/transcript/ spec/transcript/ lib/claude_office.rb
git commit -m "feat: add JSONL transcript parser with event types"
```

---

### Task 3: Transcript Watcher (Background Thread + File Polling)

**Files:**
- Create: `lib/claude_office/transcript/watcher.rb`
- Create: `spec/transcript/watcher_spec.rb`

**Step 1: Write the watcher tests**

```ruby
# spec/transcript/watcher_spec.rb
require "spec_helper"
require "claude_office/transcript/watcher"
require "tmpdir"
require "json"

RSpec.describe ClaudeOffice::Transcript::Watcher do
  let(:tmpdir) { Dir.mktmpdir("claude-office-test") }
  let(:event_queue) { Queue.new }
  let(:watcher) { described_class.new(tmpdir, event_queue) }

  after do
    watcher.stop
    FileUtils.remove_entry(tmpdir)
  end

  describe "#resolve_project_dir" do
    it "converts a path to Claude project slug" do
      slug = described_class.project_slug("/Volumes/MacintoshEDD/workspace")
      expect(slug).to eq("-Volumes-MacintoshEDD-workspace")
    end

    it "handles simple paths" do
      slug = described_class.project_slug("/home/user/project")
      expect(slug).to eq("-home-user-project")
    end
  end

  describe "file scanning" do
    it "detects new JSONL files and emits AgentCreated" do
      watcher.scan_once

      jsonl_path = File.join(tmpdir, "session-abc.jsonl")
      File.write(jsonl_path, "")

      watcher.scan_once

      event = event_queue.pop(true) rescue nil
      expect(event).to be_a(ClaudeOffice::Transcript::AgentCreated)
      expect(event.session_id).to eq("session-abc")
    end

    it "does not re-emit for already-known files" do
      jsonl_path = File.join(tmpdir, "session-abc.jsonl")
      File.write(jsonl_path, "")

      watcher.scan_once
      event_queue.pop(true) rescue nil

      watcher.scan_once
      event = event_queue.pop(true) rescue nil
      expect(event).to be_nil
    end
  end

  describe "line reading" do
    it "reads new lines from a JSONL file and emits parsed events" do
      jsonl_path = File.join(tmpdir, "session-xyz.jsonl")
      File.write(jsonl_path, "")

      watcher.scan_once
      event_queue.pop(true) rescue nil # consume AgentCreated

      line = JSON.generate({
        type: "system",
        subtype: "turn_duration",
        durationMs: 3000
      })
      File.open(jsonl_path, "a") { |f| f.puts(line) }

      watcher.read_new_lines

      event = event_queue.pop(true) rescue nil
      expect(event).to be_a(ClaudeOffice::Transcript::TurnEnd)
      expect(event.duration_ms).to eq(3000)
    end

    it "tracks file offset and only reads new content" do
      jsonl_path = File.join(tmpdir, "session-xyz.jsonl")
      line1 = JSON.generate({ type: "system", subtype: "turn_duration", durationMs: 1000 })
      File.write(jsonl_path, "#{line1}\n")

      watcher.scan_once
      event_queue.pop(true) rescue nil # AgentCreated
      watcher.read_new_lines
      event_queue.pop(true) rescue nil # first TurnEnd

      line2 = JSON.generate({ type: "system", subtype: "turn_duration", durationMs: 2000 })
      File.open(jsonl_path, "a") { |f| f.puts(line2) }

      watcher.read_new_lines

      event = event_queue.pop(true) rescue nil
      expect(event).to be_a(ClaudeOffice::Transcript::TurnEnd)
      expect(event.duration_ms).to eq(2000)
    end
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `cd /Volumes/MacintoshEDD/workspace/claude-office && bundle exec rspec spec/transcript/watcher_spec.rb`
Expected: FAIL — `cannot load such file -- claude_office/transcript/watcher`

**Step 3: Write the watcher implementation**

```ruby
# lib/claude_office/transcript/watcher.rb
require_relative "parser"
require_relative "events"

module ClaudeOffice
  module Transcript
    class Watcher
      POLL_INTERVAL = 2.0 # seconds

      attr_reader :project_dir

      def initialize(project_dir, event_queue)
        @project_dir = project_dir
        @event_queue = event_queue
        @known_files = {}   # path => { parser:, offset:, line_buffer: }
        @running = false
        @thread = nil
      end

      def self.project_slug(path)
        path.gsub("/", "-")
      end

      def self.claude_project_dir(project_path)
        slug = project_slug(File.expand_path(project_path))
        File.join(Dir.home, ".claude", "projects", slug)
      end

      def start
        @running = true
        @thread = Thread.new { run_loop }
        @thread.abort_on_exception = true
      end

      def stop
        @running = false
        @thread&.join(2)
      end

      def scan_once
        return unless Dir.exist?(@project_dir)

        Dir.glob(File.join(@project_dir, "*.jsonl")).each do |path|
          next if @known_files.key?(path)

          session_id = File.basename(path, ".jsonl")
          parser = Parser.new(session_id)

          @known_files[path] = {
            parser: parser,
            offset: 0,
            line_buffer: ""
          }

          @event_queue.push(AgentCreated.new(
            session_id: session_id,
            jsonl_path: path
          ))
        end
      end

      def read_new_lines
        @known_files.each do |path, state|
          read_file_lines(path, state)
        end
      end

      private

      def run_loop
        while @running
          scan_once
          read_new_lines
          sleep(POLL_INTERVAL)
        end
      end

      def read_file_lines(path, state)
        return unless File.exist?(path)

        size = File.size(path)
        return if size <= state[:offset]

        data = File.binread(path, size - state[:offset], state[:offset])
        state[:offset] = size

        text = state[:line_buffer] + data.force_encoding("UTF-8")
        lines = text.split("\n", -1)
        state[:line_buffer] = lines.pop || ""

        lines.each do |line|
          next if line.strip.empty?

          events = state[:parser].parse_line(line)
          events.each { |e| @event_queue.push(e) }
        end
      end
    end
  end
end
```

**Step 4: Update main require**

Add to `lib/claude_office.rb`:
```ruby
require_relative "claude_office/transcript/watcher"
```

**Step 5: Run tests to verify they pass**

Run: `cd /Volumes/MacintoshEDD/workspace/claude-office && bundle exec rspec spec/transcript/watcher_spec.rb`
Expected: All tests pass

**Step 6: Commit**

```bash
git add lib/claude_office/transcript/watcher.rb spec/transcript/watcher_spec.rb lib/claude_office.rb
git commit -m "feat: add transcript watcher with file polling and line reading"
```

---

### Task 4: Agent State Machine

**Files:**
- Create: `lib/claude_office/agents/agent.rb`
- Create: `lib/claude_office/agents/sub_agent.rb`
- Create: `lib/claude_office/agents/registry.rb`
- Create: `spec/agents/agent_spec.rb`

**Step 1: Write agent tests**

```ruby
# spec/agents/agent_spec.rb
require "spec_helper"
require "claude_office/agents/agent"

RSpec.describe ClaudeOffice::Agents::Agent do
  let(:agent) { described_class.new(session_id: "test-123", desk_position: [5, 3]) }

  describe "initial state" do
    it "starts in idle state" do
      expect(agent.state).to eq(:idle)
    end

    it "has no active tools" do
      expect(agent.active_tools).to be_empty
    end
  end

  describe "#tool_started" do
    it "transitions to working state" do
      agent.tool_started("t1", "Read", "Reading foo.rb")
      expect(agent.state).to eq(:working)
    end

    it "tracks active tools" do
      agent.tool_started("t1", "Read", "Reading foo.rb")
      expect(agent.active_tools).to include("t1")
    end

    it "stores the current status text" do
      agent.tool_started("t1", "Edit", "Editing app.rb")
      expect(agent.status_text).to eq("Editing app.rb")
    end

    it "determines animation from tool name" do
      agent.tool_started("t1", "Read", "Reading foo.rb")
      expect(agent.animation).to eq(:reading)

      agent.tool_started("t2", "Edit", "Editing bar.rb")
      expect(agent.animation).to eq(:typing)

      agent.tool_started("t3", "Bash", "Running: ls")
      expect(agent.animation).to eq(:running)
    end
  end

  describe "#tool_done" do
    it "removes tool from active set" do
      agent.tool_started("t1", "Read", "Reading foo.rb")
      agent.tool_done("t1")
      expect(agent.active_tools).to be_empty
    end

    it "transitions to idle when no more active tools" do
      agent.tool_started("t1", "Read", "Reading foo.rb")
      agent.tool_done("t1")
      expect(agent.state).to eq(:idle)
    end

    it "stays working when other tools still active" do
      agent.tool_started("t1", "Read", "Reading foo.rb")
      agent.tool_started("t2", "Edit", "Editing bar.rb")
      agent.tool_done("t1")
      expect(agent.state).to eq(:working)
    end
  end

  describe "#turn_ended" do
    it "transitions to waiting state" do
      agent.tool_started("t1", "Read", "Reading foo.rb")
      agent.turn_ended
      expect(agent.state).to eq(:waiting)
    end

    it "clears all active tools" do
      agent.tool_started("t1", "Read", "Reading foo.rb")
      agent.turn_ended
      expect(agent.active_tools).to be_empty
    end
  end

  describe "#new_turn" do
    it "transitions from waiting to idle" do
      agent.turn_ended
      agent.new_turn
      expect(agent.state).to eq(:idle)
    end
  end

  describe "sub-agents" do
    it "tracks sub-agent activity" do
      agent.tool_started("task_1", "Task", "Subtask: explore")
      agent.sub_agent_tool_started("task_1", "sub_t1", "Read", "Reading file.rb")
      expect(agent.sub_agents["task_1"]).to be_a(ClaudeOffice::Agents::SubAgent)
      expect(agent.sub_agents["task_1"].active_tools).to include("sub_t1")
    end

    it "cleans up sub-agent when parent tool completes" do
      agent.tool_started("task_1", "Task", "Subtask: explore")
      agent.sub_agent_tool_started("task_1", "sub_t1", "Read", "Reading file.rb")
      agent.tool_done("task_1")
      expect(agent.sub_agents).not_to have_key("task_1")
    end
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `cd /Volumes/MacintoshEDD/workspace/claude-office && bundle exec rspec spec/agents/agent_spec.rb`
Expected: FAIL

**Step 3: Write sub_agent implementation**

```ruby
# lib/claude_office/agents/sub_agent.rb
module ClaudeOffice
  module Agents
    class SubAgent
      attr_reader :parent_tool_id, :active_tools, :status_text, :animation

      TOOL_ANIMATIONS = {
        "Read" => :reading, "Glob" => :reading, "Grep" => :reading,
        "WebFetch" => :reading, "WebSearch" => :reading,
        "Edit" => :typing, "Write" => :typing, "NotebookEdit" => :typing,
        "Bash" => :running,
      }.freeze

      def initialize(parent_tool_id:)
        @parent_tool_id = parent_tool_id
        @active_tools = {}
        @status_text = ""
        @animation = :idle
      end

      def tool_started(tool_id, tool_name, status_text)
        @active_tools[tool_id] = tool_name
        @status_text = status_text
        @animation = TOOL_ANIMATIONS.fetch(tool_name, :idle)
      end

      def tool_done(tool_id)
        @active_tools.delete(tool_id)
        if @active_tools.empty?
          @animation = :idle
          @status_text = ""
        end
      end
    end
  end
end
```

**Step 4: Write agent implementation**

```ruby
# lib/claude_office/agents/agent.rb
require_relative "sub_agent"

module ClaudeOffice
  module Agents
    class Agent
      TOOL_ANIMATIONS = {
        "Read" => :reading, "Glob" => :reading, "Grep" => :reading,
        "WebFetch" => :reading, "WebSearch" => :reading,
        "Edit" => :typing, "Write" => :typing, "NotebookEdit" => :typing,
        "Bash" => :running,
        "Task" => :typing,
        "AskUserQuestion" => :waiting,
        "EnterPlanMode" => :reading,
      }.freeze

      attr_reader :session_id, :state, :active_tools, :status_text,
                  :animation, :desk_position, :sub_agents, :position

      def initialize(session_id:, desk_position:)
        @session_id = session_id
        @desk_position = desk_position
        @position = desk_position.dup
        @state = :idle
        @active_tools = {}
        @status_text = ""
        @animation = :idle
        @sub_agents = {}
      end

      def tool_started(tool_id, tool_name, status_text)
        @active_tools[tool_id] = tool_name
        @status_text = status_text
        @animation = TOOL_ANIMATIONS.fetch(tool_name, :idle)
        @state = :working
      end

      def tool_done(tool_id)
        tool_name = @active_tools.delete(tool_id)

        if tool_name == "Task"
          @sub_agents.delete(tool_id)
        end

        if @active_tools.empty?
          @state = :idle
          @animation = :idle
          @status_text = ""
        else
          last_tool = @active_tools.values.last
          @animation = TOOL_ANIMATIONS.fetch(last_tool, :idle)
        end
      end

      def turn_ended
        @state = :waiting
        @animation = :waiting
        @active_tools.clear
        @sub_agents.clear
        @status_text = ""
      end

      def new_turn
        @state = :idle
        @animation = :idle
      end

      def sub_agent_tool_started(parent_tool_id, tool_id, tool_name, status_text)
        @sub_agents[parent_tool_id] ||= SubAgent.new(parent_tool_id: parent_tool_id)
        @sub_agents[parent_tool_id].tool_started(tool_id, tool_name, status_text)
      end

      def sub_agent_tool_done(parent_tool_id, tool_id)
        sub = @sub_agents[parent_tool_id]
        sub&.tool_done(tool_id)
      end
    end
  end
end
```

**Step 5: Write registry**

```ruby
# lib/claude_office/agents/registry.rb
require_relative "agent"

module ClaudeOffice
  module Agents
    class Registry
      attr_reader :agents

      def initialize
        @agents = {}
      end

      def add(session_id, desk_position)
        agent = Agent.new(session_id: session_id, desk_position: desk_position)
        @agents[session_id] = agent
        agent
      end

      def get(session_id)
        @agents[session_id]
      end

      def remove(session_id)
        @agents.delete(session_id)
      end

      def count
        @agents.size
      end

      def each(&block)
        @agents.each_value(&block)
      end
    end
  end
end
```

**Step 6: Update main require**

Add to `lib/claude_office.rb`:
```ruby
require_relative "claude_office/agents/agent"
require_relative "claude_office/agents/sub_agent"
require_relative "claude_office/agents/registry"
```

**Step 7: Run tests to verify they pass**

Run: `cd /Volumes/MacintoshEDD/workspace/claude-office && bundle exec rspec spec/agents/agent_spec.rb`
Expected: All tests pass

**Step 8: Commit**

```bash
git add lib/claude_office/agents/ spec/agents/ lib/claude_office.rb
git commit -m "feat: add agent state machine with sub-agent tracking"
```

---

### Task 5: Office Grid and Auto-Layout

**Files:**
- Create: `lib/claude_office/office/grid.rb`
- Create: `lib/claude_office/office/desk.rb`
- Create: `lib/claude_office/office/pathfinder.rb`
- Create: `spec/office/grid_spec.rb`
- Create: `spec/office/pathfinder_spec.rb`

**Step 1: Write grid and layout tests**

```ruby
# spec/office/grid_spec.rb
require "spec_helper"
require "claude_office/office/grid"

RSpec.describe ClaudeOffice::Office::Grid do
  describe "#layout_for" do
    it "creates a grid with one desk for one agent" do
      grid = described_class.new(width: 40, height: 15)
      grid.layout_for(1)
      expect(grid.desks.length).to eq(1)
    end

    it "creates a grid with three desks in one row" do
      grid = described_class.new(width: 60, height: 15)
      grid.layout_for(3)
      expect(grid.desks.length).to eq(3)
      # All desks on same row
      ys = grid.desks.map { |d| d.position[1] }
      expect(ys.uniq.length).to eq(1)
    end

    it "wraps to second row for 4+ agents" do
      grid = described_class.new(width: 60, height: 20)
      grid.layout_for(4)
      expect(grid.desks.length).to eq(4)
      ys = grid.desks.map { |d| d.position[1] }
      expect(ys.uniq.length).to eq(2)
    end

    it "assigns chair positions below each desk" do
      grid = described_class.new(width: 40, height: 15)
      grid.layout_for(1)
      desk = grid.desks.first
      expect(desk.chair_position[1]).to be > desk.position[1]
    end
  end

  describe "#walkable?" do
    it "returns true for floor tiles" do
      grid = described_class.new(width: 20, height: 10)
      grid.layout_for(1)
      # Floor area should be walkable
      expect(grid.walkable?(1, 1)).to be true
    end

    it "returns false for wall tiles" do
      grid = described_class.new(width: 20, height: 10)
      grid.layout_for(1)
      # Border walls are not walkable
      expect(grid.walkable?(0, 0)).to be false
    end
  end
end
```

**Step 2: Write pathfinder tests**

```ruby
# spec/office/pathfinder_spec.rb
require "spec_helper"
require "claude_office/office/pathfinder"
require "claude_office/office/grid"

RSpec.describe ClaudeOffice::Office::Pathfinder do
  it "finds a path between two walkable points" do
    grid = ClaudeOffice::Office::Grid.new(width: 20, height: 10)
    grid.layout_for(2)
    pathfinder = described_class.new(grid)

    start = grid.desks[0].chair_position
    goal = grid.desks[1].chair_position
    path = pathfinder.find_path(start, goal)

    expect(path).not_to be_nil
    expect(path.first).to eq(start)
    expect(path.last).to eq(goal)
  end

  it "returns nil when no path exists" do
    grid = ClaudeOffice::Office::Grid.new(width: 10, height: 10)
    grid.layout_for(1)
    pathfinder = described_class.new(grid)

    # Trying to reach an unwalkable position
    path = pathfinder.find_path([1, 1], [0, 0])
    expect(path).to be_nil
  end

  it "returns single-element path when start equals goal" do
    grid = ClaudeOffice::Office::Grid.new(width: 20, height: 10)
    grid.layout_for(1)
    pathfinder = described_class.new(grid)

    pos = grid.desks[0].chair_position
    path = pathfinder.find_path(pos, pos)
    expect(path).to eq([pos])
  end
end
```

**Step 3: Run tests to verify they fail**

Run: `cd /Volumes/MacintoshEDD/workspace/claude-office && bundle exec rspec spec/office/`
Expected: FAIL

**Step 4: Write desk**

```ruby
# lib/claude_office/office/desk.rb
module ClaudeOffice
  module Office
    class Desk
      attr_reader :position, :chair_position, :assigned_session_id

      def initialize(position:, chair_position:)
        @position = position
        @chair_position = chair_position
        @assigned_session_id = nil
      end

      def assign(session_id)
        @assigned_session_id = session_id
      end

      def unassign
        @assigned_session_id = nil
      end

      def assigned?
        !@assigned_session_id.nil?
      end
    end
  end
end
```

**Step 5: Write grid with auto-layout**

```ruby
# lib/claude_office/office/grid.rb
require_relative "desk"

module ClaudeOffice
  module Office
    class Grid
      DESKS_PER_ROW = 3
      DESK_WIDTH = 7        # characters wide: ┌─────┐
      DESK_HEIGHT = 3       # rows tall
      DESK_SPACING_X = 6    # horizontal gap between desks
      DESK_SPACING_Y = 7    # vertical gap between desk rows
      MARGIN_X = 3          # left/right margin inside walls
      MARGIN_Y = 2          # top/bottom margin inside walls

      attr_reader :width, :height, :desks, :tiles

      def initialize(width:, height:)
        @width = width
        @height = height
        @desks = []
        @tiles = Array.new(height) { Array.new(width, :floor) }
        place_walls
      end

      def layout_for(agent_count)
        @desks.clear
        return if agent_count == 0

        rows = (agent_count.to_f / DESKS_PER_ROW).ceil
        agent_index = 0

        rows.times do |row|
          desks_in_row = [DESKS_PER_ROW, agent_count - agent_index].min
          row_y = MARGIN_Y + 1 + row * DESK_SPACING_Y

          desks_in_row.times do |col|
            desk_x = MARGIN_X + 1 + col * (DESK_WIDTH + DESK_SPACING_X)
            desk_pos = [desk_x, row_y]
            chair_pos = [desk_x + DESK_WIDTH / 2, row_y + DESK_HEIGHT + 1]

            @desks << Desk.new(position: desk_pos, chair_position: chair_pos)
            agent_index += 1
          end
        end
      end

      def walkable?(x, y)
        return false if x < 0 || y < 0 || x >= @width || y >= @height

        @tiles[y][x] == :floor
      end

      private

      def place_walls
        @width.times do |x|
          @tiles[0][x] = :wall
          @tiles[@height - 1][x] = :wall
        end
        @height.times do |y|
          @tiles[y][0] = :wall
          @tiles[y][@width - 1] = :wall
        end
      end
    end
  end
end
```

**Step 6: Write pathfinder (BFS)**

```ruby
# lib/claude_office/office/pathfinder.rb
module ClaudeOffice
  module Office
    class Pathfinder
      DIRECTIONS = [[0, -1], [0, 1], [-1, 0], [1, 0]].freeze

      def initialize(grid)
        @grid = grid
      end

      def find_path(start, goal)
        return [start] if start == goal
        return nil unless @grid.walkable?(start[0], start[1])
        return nil unless @grid.walkable?(goal[0], goal[1])

        queue = [start]
        came_from = { start => nil }

        until queue.empty?
          current = queue.shift

          if current == goal
            return reconstruct_path(came_from, goal)
          end

          DIRECTIONS.each do |dx, dy|
            neighbor = [current[0] + dx, current[1] + dy]
            next if came_from.key?(neighbor)
            next unless @grid.walkable?(neighbor[0], neighbor[1])

            came_from[neighbor] = current
            queue << neighbor
          end
        end

        nil
      end

      private

      def reconstruct_path(came_from, goal)
        path = [goal]
        current = goal

        while came_from[current]
          current = came_from[current]
          path.unshift(current)
        end

        path
      end
    end
  end
end
```

**Step 7: Update main require**

Add to `lib/claude_office.rb`:
```ruby
require_relative "claude_office/office/desk"
require_relative "claude_office/office/grid"
require_relative "claude_office/office/pathfinder"
```

**Step 8: Run tests to verify they pass**

Run: `cd /Volumes/MacintoshEDD/workspace/claude-office && bundle exec rspec spec/office/`
Expected: All tests pass

**Step 9: Commit**

```bash
git add lib/claude_office/office/ spec/office/ lib/claude_office.rb
git commit -m "feat: add office grid with auto-layout and BFS pathfinding"
```

---

### Task 6: Sprites, Theme, and Renderer

**Files:**
- Create: `lib/claude_office/rendering/sprites.rb`
- Create: `lib/claude_office/rendering/theme.rb`
- Create: `lib/claude_office/rendering/renderer.rb`

**Step 1: Write sprites**

```ruby
# lib/claude_office/rendering/sprites.rb
module ClaudeOffice
  module Rendering
    module Sprites
      FACES = {
        idle:     "(o_o)",
        typing:   "(o.o)~",
        reading:  "(o.O)",
        running:  "(>.<)",
        waiting:  "(-.-)zzZ",
        walking:  ["(o_o)/", "(o_o)\\"],
      }.freeze

      SUB_AGENT_FACES = {
        idle:    "(o_o)",
        typing:  "(o.o)",
        reading: "(o.O)",
        running: "(>.<)",
        waiting: "(-.-)",
      }.freeze

      DESK = [
        "┌─────┐",
        "│ ▒▒▒ │",
        "└──┬──┘",
      ].freeze

      FLOOR_CHAR = "░"
      WALL_CHAR = "█"

      def self.face_for(animation, frame: 0)
        sprite = FACES.fetch(animation, FACES[:idle])
        sprite.is_a?(Array) ? sprite[frame % sprite.length] : sprite
      end

      def self.sub_face_for(animation)
        SUB_AGENT_FACES.fetch(animation, SUB_AGENT_FACES[:idle])
      end
    end
  end
end
```

**Step 2: Write theme**

```ruby
# lib/claude_office/rendering/theme.rb
require "lipgloss"

module ClaudeOffice
  module Rendering
    module Theme
      FLOOR_STYLE = Lipgloss::Style.new
        .foreground("#555555")
        .background("#2D2D2D")

      WALL_STYLE = Lipgloss::Style.new
        .foreground("#777777")
        .background("#444444")

      DESK_STYLE = Lipgloss::Style.new
        .foreground("#8B6914")

      ACTIVE_AGENT_STYLE = Lipgloss::Style.new
        .foreground("#00D4AA")
        .bold(true)

      WAITING_AGENT_STYLE = Lipgloss::Style.new
        .foreground("#FFD700")

      IDLE_AGENT_STYLE = Lipgloss::Style.new
        .foreground("#AAAAAA")

      STATUS_TEXT_STYLE = Lipgloss::Style.new
        .foreground("#888888")
        .italic(true)

      SUB_AGENT_STYLE = Lipgloss::Style.new
        .foreground("#77AADD")

      SPEECH_BUBBLE_STYLE = Lipgloss::Style.new
        .border(:rounded)
        .border_foreground("#874BFD")
        .padding(0, 1)

      TITLE_STYLE = Lipgloss::Style.new
        .bold(true)
        .foreground("#FFFFFF")
        .background("#333333")
        .padding(0, 1)

      STATUS_BAR_STYLE = Lipgloss::Style.new
        .foreground("#CCCCCC")
        .background("#333333")
        .padding(0, 1)

      def self.agent_style(state)
        case state
        when :working then ACTIVE_AGENT_STYLE
        when :waiting then WAITING_AGENT_STYLE
        else IDLE_AGENT_STYLE
        end
      end
    end
  end
end
```

**Step 3: Write renderer**

```ruby
# lib/claude_office/rendering/renderer.rb
require "lipgloss"
require_relative "sprites"
require_relative "theme"

module ClaudeOffice
  module Rendering
    class Renderer
      def initialize(width:, height:)
        @width = width
        @height = height
      end

      def render(grid:, agents:, frame:)
        title = render_title(grid)
        office = render_office(grid, agents, frame)
        status = render_status_bar(agents)

        Lipgloss.join_vertical(:left, title, office, status)
      end

      private

      def render_title(grid)
        Theme::TITLE_STYLE
          .width(@width)
          .render("claude-office")
      end

      def render_office(grid, agents, frame)
        lines = []

        grid.height.times do |y|
          line = ""
          grid.width.times do |x|
            case grid.tiles[y][x]
            when :wall
              line += Theme::WALL_STYLE.render(Sprites::WALL_CHAR)
            else
              line += Theme::FLOOR_STYLE.render(Sprites::FLOOR_CHAR)
            end
          end
          lines << line
        end

        office_str = lines.join("\n")

        # Overlay desks
        grid.desks.each do |desk|
          desk_str = Sprites::DESK.map { |row| Theme::DESK_STYLE.render(row) }.join("\n")
          office_str = overlay(office_str, desk_str, desk.position[0], desk.position[1])
        end

        # Overlay agents at their positions
        agents.each do |agent|
          face = Sprites.face_for(agent.animation, frame: frame)
          style = Theme.agent_style(agent.state)
          agent_str = style.render(face)

          # Status text below face
          unless agent.status_text.empty?
            status = Theme::STATUS_TEXT_STYLE.render("\"#{agent.status_text}\"")
            agent_str = Lipgloss.join_vertical(:center, agent_str, status)
          end

          # Sub-agents
          agent.sub_agents.each_value do |sub|
            sub_face = Sprites.sub_face_for(sub.animation)
            sub_line = Theme::SUB_AGENT_STYLE.render("└─ #{sub_face}")
            unless sub.status_text.empty?
              sub_line += " " + Theme::STATUS_TEXT_STYLE.render("\"#{sub.status_text}\"")
            end
            agent_str = Lipgloss.join_vertical(:left, agent_str, sub_line)
          end

          # Speech bubble for waiting agents
          if agent.state == :waiting
            bubble = Theme::SPEECH_BUBBLE_STYLE.render("Needs input!")
            agent_str = Lipgloss.join_vertical(:center, bubble, agent_str)
          end

          pos = agent.desk_position
          char_x = pos[0] + 1
          char_y = pos[1] + Sprites::DESK.length + 1
          office_str = overlay(office_str, agent_str, char_x, char_y)
        end

        office_str
      end

      def render_status_bar(agents)
        parts = agents.map do |agent|
          state_str = agent.state.to_s
          subs = agent.sub_agents.size
          sub_info = subs > 0 ? " (#{subs} sub#{"s" if subs > 1})" : ""
          "Agent: #{state_str}#{sub_info}"
        end

        parts << "q: quit"
        bar_text = parts.join(" │ ")

        Theme::STATUS_BAR_STYLE
          .width(@width)
          .render(bar_text)
      end

      def overlay(base, overlay_str, x, y)
        base_lines = base.split("\n")
        overlay_lines = overlay_str.split("\n")

        overlay_lines.each_with_index do |oline, i|
          target_y = y + i
          next if target_y < 0 || target_y >= base_lines.length

          base_line = base_lines[target_y]
          visible_len = Lipgloss.width(oline)

          # Simple overlay: replace characters at position
          # This is approximate — for styled text, exact character replacement
          # is complex. We'll use Lipgloss.place in the real implementation
          # if available, otherwise string concatenation.
          before = base_line[0...x] || ""
          after_start = x + visible_len
          after = base_line[after_start..] || ""
          base_lines[target_y] = before + oline + after
        end

        base_lines.join("\n")
      end
    end
  end
end
```

**Step 4: Update main require**

Add to `lib/claude_office.rb`:
```ruby
require_relative "claude_office/rendering/sprites"
require_relative "claude_office/rendering/theme"
require_relative "claude_office/rendering/renderer"
```

**Step 5: Commit**

```bash
git add lib/claude_office/rendering/ lib/claude_office.rb
git commit -m "feat: add sprites, theme, and renderer"
```

---

### Task 7: Animation (Spring Mover + Frame Cycling)

**Files:**
- Create: `lib/claude_office/animation/spring_mover.rb`
- Create: `lib/claude_office/animation/frame_cycle.rb`

**Step 1: Write spring mover**

```ruby
# lib/claude_office/animation/spring_mover.rb
require "harmonica"

module ClaudeOffice
  module Animation
    class SpringMover
      def initialize(fps: 30)
        @spring = Harmonica::Spring.new(
          delta_time: Harmonica.fps(fps),
          angular_frequency: 5.0,
          damping_ratio: 0.8
        )
        @x = 0.0
        @y = 0.0
        @vx = 0.0
        @vy = 0.0
        @target_x = 0.0
        @target_y = 0.0
      end

      def set_position(x, y)
        @x = x.to_f
        @y = y.to_f
        @target_x = x.to_f
        @target_y = y.to_f
        @vx = 0.0
        @vy = 0.0
      end

      def set_target(x, y)
        @target_x = x.to_f
        @target_y = y.to_f
      end

      def update
        @x, @vx = @spring.update(@x, @vx, @target_x)
        @y, @vy = @spring.update(@y, @vy, @target_y)
      end

      def position
        [@x.round, @y.round]
      end

      def arrived?(threshold: 0.5)
        (@x - @target_x).abs < threshold && (@y - @target_y).abs < threshold
      end
    end
  end
end
```

**Step 2: Write frame cycle**

```ruby
# lib/claude_office/animation/frame_cycle.rb
module ClaudeOffice
  module Animation
    class FrameCycle
      attr_reader :frame

      def initialize(frame_count:, frames_per_tick: 10)
        @frame_count = frame_count
        @frames_per_tick = frames_per_tick
        @tick = 0
        @frame = 0
      end

      def advance
        @tick += 1
        if @tick >= @frames_per_tick
          @tick = 0
          @frame = (@frame + 1) % @frame_count
        end
      end
    end
  end
end
```

**Step 3: Update main require**

Add to `lib/claude_office.rb`:
```ruby
require_relative "claude_office/animation/spring_mover"
require_relative "claude_office/animation/frame_cycle"
```

**Step 4: Commit**

```bash
git add lib/claude_office/animation/ lib/claude_office.rb
git commit -m "feat: add spring mover and frame cycling for animation"
```

---

### Task 8: Notification Module

**Files:**
- Create: `lib/claude_office/notification.rb`

**Step 1: Write notification module**

```ruby
# lib/claude_office/notification.rb
module ClaudeOffice
  class Notification
    def initialize(sound_enabled: true)
      @sound_enabled = sound_enabled
    end

    def agent_waiting(session_id)
      bell if @sound_enabled
    end

    def agent_turn_ended(session_id)
      bell if @sound_enabled
    end

    private

    def bell
      print "\a"
      $stdout.flush
    end
  end
end
```

**Step 2: Update main require**

Add to `lib/claude_office.rb`:
```ruby
require_relative "claude_office/notification"
```

**Step 3: Commit**

```bash
git add lib/claude_office/notification.rb lib/claude_office.rb
git commit -m "feat: add terminal bell notification"
```

---

### Task 9: Main App — Bubbletea Model Wiring Everything Together

**Files:**
- Create: `lib/claude_office/app.rb`
- Modify: `lib/claude_office/cli.rb`

**Step 1: Write the main Bubbletea model**

```ruby
# lib/claude_office/app.rb
require "bubbletea"
require "lipgloss"
require_relative "transcript/watcher"
require_relative "agents/registry"
require_relative "office/grid"
require_relative "office/pathfinder"
require_relative "rendering/renderer"
require_relative "animation/frame_cycle"
require_relative "notification"

module ClaudeOffice
  class TickMessage < Bubbletea::Message; end

  class TranscriptEventMessage < Bubbletea::Message
    attr_reader :event

    def initialize(event)
      @event = event
    end
  end

  class App
    include Bubbletea::Model

    FPS = 30
    GRID_WIDTH = 60
    GRID_HEIGHT = 20

    def initialize(project_dir:, sound: true)
      @project_dir = project_dir
      @sound = sound
      @registry = Agents::Registry.new
      @grid = Office::Grid.new(width: GRID_WIDTH, height: GRID_HEIGHT)
      @pathfinder = Office::Pathfinder.new(@grid)
      @renderer = Rendering::Renderer.new(width: GRID_WIDTH, height: GRID_HEIGHT)
      @notification = Notification.new(sound_enabled: sound)
      @frame_cycle = Animation::FrameCycle.new(frame_count: 2, frames_per_tick: 15)
      @event_queue = Queue.new
      @watcher = nil
      @width = GRID_WIDTH
      @height = GRID_HEIGHT
    end

    def init
      @watcher = Transcript::Watcher.new(@project_dir, @event_queue)
      @watcher.start

      [self, schedule_tick]
    end

    def update(message)
      case message
      when Bubbletea::KeyMessage
        handle_key(message)
      when Bubbletea::WindowSizeMessage
        @width = message.width
        @height = message.height
        @grid = Office::Grid.new(width: [@width, GRID_WIDTH].min, height: [message.height - 4, GRID_HEIGHT].min)
        @grid.layout_for(@registry.count)
        @pathfinder = Office::Pathfinder.new(@grid)
        @renderer = Rendering::Renderer.new(width: @grid.width, height: @grid.height)
        [self, nil]
      when TickMessage
        handle_tick
      else
        [self, nil]
      end
    end

    def view
      agents = []
      @registry.each { |a| agents << a }
      @renderer.render(grid: @grid, agents: agents, frame: @frame_cycle.frame)
    end

    private

    def handle_key(message)
      case message.to_s
      when "q", "ctrl+c"
        @watcher&.stop
        [self, Bubbletea.quit]
      else
        [self, nil]
      end
    end

    def handle_tick
      # Drain event queue
      while (event = @event_queue.pop(true) rescue nil)
        process_event(event)
      end

      @frame_cycle.advance

      [self, schedule_tick]
    end

    def process_event(event)
      case event
      when Transcript::AgentCreated
        desk_pos = next_desk_position
        @registry.add(event.session_id, desk_pos)
        @grid.layout_for(@registry.count)
        @pathfinder = Office::Pathfinder.new(@grid)
        # Reassign desk positions after re-layout
        reassign_desk_positions

      when Transcript::ToolStart
        agent = @registry.get(event.session_id)
        agent&.tool_started(event.tool_id, event.tool_name, event.status_text)

      when Transcript::ToolDone
        agent = @registry.get(event.session_id)
        agent&.tool_done(event.tool_id)

      when Transcript::TurnEnd
        agent = @registry.get(event.session_id)
        if agent
          agent.turn_ended
          @notification.agent_turn_ended(event.session_id)
        end

      when Transcript::SubAgentToolStart
        agent = @registry.get(event.session_id)
        agent&.sub_agent_tool_started(
          event.parent_tool_id, event.tool_id,
          event.tool_name, event.status_text
        )

      when Transcript::SubAgentToolDone
        agent = @registry.get(event.session_id)
        agent&.sub_agent_tool_done(event.parent_tool_id, event.tool_id)

      when Transcript::TextOnly
        # Could start idle timer here; skip for now
      end
    end

    def next_desk_position
      count = @registry.count
      [3 + (count % 3) * 13, 3 + (count / 3) * 7]
    end

    def reassign_desk_positions
      @registry.each_with_index do |agent, i|
        if i < @grid.desks.length
          desk = @grid.desks[i]
          desk.assign(agent.session_id)
        end
      end
    end

    def schedule_tick
      Bubbletea.tick(1.0 / FPS) { TickMessage.new }
    end
  end
end
```

**Step 2: Update CLI to launch the app**

```ruby
# lib/claude_office/cli.rb
require_relative "transcript/watcher"

module ClaudeOffice
  class CLI
    def self.run(args)
      if args.include?("--version")
        puts "claude-office #{ClaudeOffice::VERSION}"
        return
      end

      if args.include?("--help")
        puts <<~HELP
          Usage: claude-office [PROJECT_PATH] [OPTIONS]

          Watch Claude Code sessions as animated characters in a terminal office.

          Arguments:
            PROJECT_PATH    Path to project (default: current directory)

          Options:
            --no-sound      Disable terminal bell notifications
            --version       Show version
            --help          Show this help
        HELP
        return
      end

      project_path = args.reject { |a| a.start_with?("--") }.first || Dir.pwd
      sound = !args.include?("--no-sound")

      project_dir = Transcript::Watcher.claude_project_dir(project_path)

      unless Dir.exist?(project_dir)
        $stderr.puts "Error: No Claude Code data found for #{project_path}"
        $stderr.puts "Expected: #{project_dir}"
        $stderr.puts ""
        $stderr.puts "Make sure you've run Claude Code in that directory at least once."
        exit 1
      end

      require_relative "app"

      app = App.new(project_dir: project_dir, sound: sound)
      Bubbletea.run(app, alt_screen: true, mouse_cell_motion: true)
    end
  end
end
```

**Step 3: Make the bin file executable**

Run: `chmod +x /Volumes/MacintoshEDD/workspace/claude-office/bin/claude-office`

**Step 4: Test the app runs (smoke test against real data)**

Run: `cd /Volumes/MacintoshEDD/workspace/claude-office && ruby bin/claude-office /Volumes/MacintoshEDD/workspace`

Expected: TUI launches in alt screen, shows office grid. Press `q` to quit.

**Step 5: Commit**

```bash
git add lib/claude_office/app.rb lib/claude_office/cli.rb bin/claude-office
git commit -m "feat: wire up main Bubbletea app with all components"
```

---

### Task 10: Polish and Integration Testing

**Step 1: Run full test suite**

Run: `cd /Volumes/MacintoshEDD/workspace/claude-office && bundle exec rspec`
Expected: All tests pass

**Step 2: Manual smoke test**

Run the app against this workspace (which has active JSONL files from this session):

Run: `cd /Volumes/MacintoshEDD/workspace/claude-office && ruby bin/claude-office /Volumes/MacintoshEDD/workspace`

Verify:
- TUI renders in alt screen
- Office grid with floor and walls visible
- At least one agent character appears (from this Claude Code session)
- Status bar shows agent state
- Press `q` to quit cleanly

**Step 3: Fix any rendering issues discovered during smoke test**

Adjust grid dimensions, character positions, or overlay logic as needed.

**Step 4: Final commit**

```bash
git add -A
git commit -m "feat: claude-office v0.1.0 — TUI companion for Claude Code"
```
