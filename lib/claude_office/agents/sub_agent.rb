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
