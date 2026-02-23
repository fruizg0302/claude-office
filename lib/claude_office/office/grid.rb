require_relative "desk"

module ClaudeOffice
  module Office
    class Grid
      DESKS_PER_ROW = 3
      DESK_WIDTH = 7
      DESK_HEIGHT = 3
      DESK_SPACING_X = 6
      DESK_SPACING_Y = 7
      MARGIN_X = 3
      MARGIN_Y = 2

      attr_reader :width, :height, :desks, :tiles

      def initialize(width:, height:)
        @width = width
        @height = height
        @desks = []
        @tiles = Array.new(height) { Array.new(width, :floor) }
        place_walls
      end

      def layout_for(agent_count)
        @desks.clear
        return if agent_count == 0

        rows = (agent_count.to_f / DESKS_PER_ROW).ceil
        agent_index = 0

        rows.times do |row|
          desks_in_row = [DESKS_PER_ROW, agent_count - agent_index].min
          row_y = MARGIN_Y + 1 + row * DESK_SPACING_Y

          desks_in_row.times do |col|
            desk_x = MARGIN_X + 1 + col * (DESK_WIDTH + DESK_SPACING_X)
            desk_pos = [desk_x, row_y]
            chair_pos = [desk_x + DESK_WIDTH / 2, row_y + DESK_HEIGHT + 1]

            @desks << Desk.new(position: desk_pos, chair_position: chair_pos)
            agent_index += 1
          end
        end
      end

      def walkable?(x, y)
        return false if x < 0 || y < 0 || x >= @width || y >= @height

        @tiles[y][x] == :floor
      end

      private

      def place_walls
        @width.times do |x|
          @tiles[0][x] = :wall
          @tiles[@height - 1][x] = :wall
        end
        @height.times do |y|
          @tiles[y][0] = :wall
          @tiles[y][@width - 1] = :wall
        end
      end
    end
  end
end
