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
