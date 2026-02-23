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
