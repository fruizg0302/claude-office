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
