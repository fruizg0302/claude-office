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
