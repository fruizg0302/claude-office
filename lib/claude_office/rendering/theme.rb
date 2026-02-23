require "lipgloss"

module ClaudeOffice
  module Rendering
    module Theme
      FLOOR_STYLE = Lipgloss::Style.new
        .foreground("#555555")
        .background("#2D2D2D")

      WALL_STYLE = Lipgloss::Style.new
        .foreground("#777777")
        .background("#444444")

      DESK_STYLE = Lipgloss::Style.new
        .foreground("#8B6914")

      ACTIVE_AGENT_STYLE = Lipgloss::Style.new
        .foreground("#00D4AA")
        .bold(true)

      WAITING_AGENT_STYLE = Lipgloss::Style.new
        .foreground("#FFD700")

      IDLE_AGENT_STYLE = Lipgloss::Style.new
        .foreground("#AAAAAA")

      STATUS_TEXT_STYLE = Lipgloss::Style.new
        .foreground("#888888")
        .italic(true)

      SUB_AGENT_STYLE = Lipgloss::Style.new
        .foreground("#77AADD")

      SPEECH_BUBBLE_STYLE = Lipgloss::Style.new
        .border(:rounded)
        .border_foreground("#874BFD")
        .padding(0, 1)

      TITLE_STYLE = Lipgloss::Style.new
        .bold(true)
        .foreground("#FFFFFF")
        .background("#333333")
        .padding(0, 1)

      STATUS_BAR_STYLE = Lipgloss::Style.new
        .foreground("#CCCCCC")
        .background("#333333")
        .padding(0, 1)

      def self.agent_style(state)
        case state
        when :working then ACTIVE_AGENT_STYLE
        when :waiting then WAITING_AGENT_STYLE
        else IDLE_AGENT_STYLE
        end
      end
    end
  end
end
