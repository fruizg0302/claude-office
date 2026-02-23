module ClaudeOffice
  module Animation
    class FrameCycle
      attr_reader :frame

      def initialize(frame_count:, frames_per_tick: 10)
        @frame_count = frame_count
        @frames_per_tick = frames_per_tick
        @tick = 0
        @frame = 0
      end

      def advance
        @tick += 1
        if @tick >= @frames_per_tick
          @tick = 0
          @frame = (@frame + 1) % @frame_count
        end
      end
    end
  end
end
