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
