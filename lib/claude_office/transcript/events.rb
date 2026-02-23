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
