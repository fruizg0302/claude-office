module ClaudeOffice
  module Office
    class Pathfinder
      DIRECTIONS = [[0, -1], [0, 1], [-1, 0], [1, 0]].freeze

      def initialize(grid)
        @grid = grid
      end

      def find_path(start, goal)
        return [start] if start == goal
        return nil unless @grid.walkable?(start[0], start[1])
        return nil unless @grid.walkable?(goal[0], goal[1])

        queue = [start]
        came_from = { start => nil }

        until queue.empty?
          current = queue.shift

          if current == goal
            return reconstruct_path(came_from, goal)
          end

          DIRECTIONS.each do |dx, dy|
            neighbor = [current[0] + dx, current[1] + dy]
            next if came_from.key?(neighbor)
            next unless @grid.walkable?(neighbor[0], neighbor[1])

            came_from[neighbor] = current
            queue << neighbor
          end
        end

        nil
      end

      private

      def reconstruct_path(came_from, goal)
        path = [goal]
        current = goal

        while came_from[current]
          current = came_from[current]
          path.unshift(current)
        end

        path
      end
    end
  end
end
