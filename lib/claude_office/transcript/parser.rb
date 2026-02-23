require "json"
require_relative "events"

module ClaudeOffice
  module Transcript
    class Parser
      BASH_COMMAND_MAX_LENGTH = 40
      TASK_DESCRIPTION_MAX_LENGTH = 40

      def initialize(session_id)
        @session_id = session_id
        @active_tools = {}
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
