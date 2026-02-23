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
