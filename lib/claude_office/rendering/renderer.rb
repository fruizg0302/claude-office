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
        # Build a plain-text 2D buffer, then style entire lines
        buffer = build_buffer(grid)

        # Place desks into buffer
        grid.desks.each do |desk|
          place_desk(buffer, desk)
        end

        # Place agents into buffer
        agent_labels = []
        agents.each do |agent|
          place_agent(buffer, agent, frame, agent_labels)
        end

        # Render buffer to styled string
        title = render_title
        office = render_buffer(buffer)
        labels = render_labels(agent_labels)
        status = render_status_bar(agents)

        parts = [title, office]
        parts << labels unless labels.empty?
        parts << status

        Lipgloss.join_vertical(:left, *parts)
      end

      private

      def build_buffer(grid)
        Array.new(grid.height) do |y|
          Array.new(grid.width) do |x|
            case grid.tiles[y][x]
            when :wall then { char: Sprites::WALL_CHAR, type: :wall }
            else { char: Sprites::FLOOR_CHAR, type: :floor }
            end
          end
        end
      end

      def place_desk(buffer, desk)
        dx, dy = desk.position
        Sprites::DESK.each_with_index do |row, row_i|
          row.chars.each_with_index do |ch, col_i|
            bx = dx + col_i
            by = dy + row_i
            next if by < 0 || by >= buffer.length
            next if bx < 0 || bx >= buffer[0].length

            buffer[by][bx] = { char: ch, type: :desk }
          end
        end
      end

      def place_agent(buffer, agent, frame, agent_labels)
        pos = agent.desk_position
        face = Sprites.face_for(agent.animation, frame: frame)
        char_x = pos[0] + 1
        char_y = pos[1] + Sprites::DESK.length + 1

        # Place face characters into buffer
        face.chars.each_with_index do |ch, i|
          bx = char_x + i
          next if char_y < 0 || char_y >= buffer.length
          next if bx < 0 || bx >= buffer[0].length

          buffer[char_y][bx] = { char: ch, type: :agent, state: agent.state }
        end

        # Collect label info for rendering below the grid
        label_parts = []
        label_parts << agent.status_text unless agent.status_text.empty?

        agent.sub_agents.each_value do |sub|
          sub_face = Sprites.sub_face_for(sub.animation)
          sub_text = "  └─ #{sub_face}"
          sub_text += " \"#{sub.status_text}\"" unless sub.status_text.empty?
          label_parts << sub_text
        end

        if agent.state == :waiting
          label_parts.unshift("Needs input!")
        end

        unless label_parts.empty?
          agent_labels << { state: agent.state, parts: label_parts }
        end
      end

      def render_title
        Theme::TITLE_STYLE
          .width(@width)
          .render("claude-office")
      end

      def render_buffer(buffer)
        lines = buffer.map do |row|
          row.map do |cell|
            case cell[:type]
            when :wall
              Theme::WALL_STYLE.render(cell[:char])
            when :desk
              Theme::DESK_STYLE.render(cell[:char])
            when :agent
              Theme.agent_style(cell[:state]).render(cell[:char])
            else
              Theme::FLOOR_STYLE.render(cell[:char])
            end
          end.join
        end

        lines.join("\n")
      end

      def render_labels(agent_labels)
        return "" if agent_labels.empty?

        lines = agent_labels.map do |info|
          style = Theme.agent_style(info[:state])
          info[:parts].map do |part|
            if part.start_with?("  └─")
              Theme::SUB_AGENT_STYLE.render(part)
            elsif part == "Needs input!"
              Theme::WAITING_AGENT_STYLE.render("⚡ #{part}")
            else
              Theme::STATUS_TEXT_STYLE.render("  \"#{part}\"")
            end
          end.join("\n")
        end

        lines.join("\n")
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
    end
  end
end
