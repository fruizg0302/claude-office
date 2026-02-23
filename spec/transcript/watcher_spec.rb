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
