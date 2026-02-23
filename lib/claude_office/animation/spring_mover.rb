require "harmonica"

module ClaudeOffice
  module Animation
    class SpringMover
      def initialize(fps: 30)
        @spring = Harmonica::Spring.new(
          delta_time: Harmonica.fps(fps),
          angular_frequency: 5.0,
          damping_ratio: 0.8
        )
        @x = 0.0
        @y = 0.0
        @vx = 0.0
        @vy = 0.0
        @target_x = 0.0
        @target_y = 0.0
      end

      def set_position(x, y)
        @x = x.to_f
        @y = y.to_f
        @target_x = x.to_f
        @target_y = y.to_f
        @vx = 0.0
        @vy = 0.0
      end

      def set_target(x, y)
        @target_x = x.to_f
        @target_y = y.to_f
      end

      def update
        @x, @vx = @spring.update(@x, @vx, @target_x)
        @y, @vy = @spring.update(@y, @vy, @target_y)
      end

      def position
        [@x.round, @y.round]
      end

      def arrived?(threshold: 0.5)
        (@x - @target_x).abs < threshold && (@y - @target_y).abs < threshold
      end
    end
  end
end
