require "lipgloss"
require_relative "sprites"
require_relative "theme"

module ClaudeOffice
  module Rendering
    class Renderer
      def initialize(width:, height:)
        @width = width
        @height = height
      end

      def render(grid:, agents:, frame:)
        title = render_title(grid)
        office = render_office(grid, agents, frame)
        status = render_status_bar(agents)

        Lipgloss.join_vertical(:left, title, office, status)
      end

      private

      def render_title(grid)
        Theme::TITLE_STYLE
          .width(@width)
          .render("claude-office")
      end

      def render_office(grid, agents, frame)
        lines = []

        grid.height.times do |y|
          line = ""
          grid.width.times do |x|
            case grid.tiles[y][x]
            when :wall
              line += Theme::WALL_STYLE.render(Sprites::WALL_CHAR)
            else
              line += Theme::FLOOR_STYLE.render(Sprites::FLOOR_CHAR)
            end
          end
          lines << line
        end

        office_str = lines.join("\n")

        grid.desks.each do |desk|
          desk_str = Sprites::DESK.map { |row| Theme::DESK_STYLE.render(row) }.join("\n")
          office_str = overlay(office_str, desk_str, desk.position[0], desk.position[1])
        end

        agents.each do |agent|
          face = Sprites.face_for(agent.animation, frame: frame)
          style = Theme.agent_style(agent.state)
          agent_str = style.render(face)

          unless agent.status_text.empty?
            status = Theme::STATUS_TEXT_STYLE.render("\"#{agent.status_text}\"")
            agent_str = Lipgloss.join_vertical(:center, agent_str, status)
          end

          agent.sub_agents.each_value do |sub|
            sub_face = Sprites.sub_face_for(sub.animation)
            sub_line = Theme::SUB_AGENT_STYLE.render("└─ #{sub_face}")
            unless sub.status_text.empty?
              sub_line += " " + Theme::STATUS_TEXT_STYLE.render("\"#{sub.status_text}\"")
            end
            agent_str = Lipgloss.join_vertical(:left, agent_str, sub_line)
          end

          if agent.state == :waiting
            bubble = Theme::SPEECH_BUBBLE_STYLE.render("Needs input!")
            agent_str = Lipgloss.join_vertical(:center, bubble, agent_str)
          end

          pos = agent.desk_position
          char_x = pos[0] + 1
          char_y = pos[1] + Sprites::DESK.length + 1
          office_str = overlay(office_str, agent_str, char_x, char_y)
        end

        office_str
      end

      def render_status_bar(agents)
        parts = agents.map do |agent|
          state_str = agent.state.to_s
          subs = agent.sub_agents.size
          sub_info = subs > 0 ? " (#{subs} sub#{"s" if subs > 1})" : ""
          "Agent: #{state_str}#{sub_info}"
        end

        parts << "q: quit"
        bar_text = parts.join(" │ ")

        Theme::STATUS_BAR_STYLE
          .width(@width)
          .render(bar_text)
      end

      def overlay(base, overlay_str, x, y)
        base_lines = base.split("\n")
        overlay_lines = overlay_str.split("\n")

        overlay_lines.each_with_index do |oline, i|
          target_y = y + i
          next if target_y < 0 || target_y >= base_lines.length

          base_line = base_lines[target_y]
          visible_len = Lipgloss.width(oline)

          before = base_line[0...x] || ""
          after_start = x + visible_len
          after = base_line[after_start..] || ""
          base_lines[target_y] = before + oline + after
        end

        base_lines.join("\n")
      end
    end
  end
end
