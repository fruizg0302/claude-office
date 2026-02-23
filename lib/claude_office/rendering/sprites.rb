module ClaudeOffice
  module Rendering
    module Sprites
      FACES = {
        idle:     "(o_o)",
        typing:   "(o.o)~",
        reading:  "(o.O)",
        running:  "(>.<)",
        waiting:  "(-.-)zzZ",
        walking:  ["(o_o)/", "(o_o)\\"],
      }.freeze

      SUB_AGENT_FACES = {
        idle:    "(o_o)",
        typing:  "(o.o)",
        reading: "(o.O)",
        running: "(>.<)",
        waiting: "(-.-)",
      }.freeze

      DESK = [
        "┌─────┐",
        "│ ▒▒▒ │",
        "└──┬──┘",
      ].freeze

      FLOOR_CHAR = "░"
      WALL_CHAR = "█"

      def self.face_for(animation, frame: 0)
        sprite = FACES.fetch(animation, FACES[:idle])
        sprite.is_a?(Array) ? sprite[frame % sprite.length] : sprite
      end

      def self.sub_face_for(animation)
        SUB_AGENT_FACES.fetch(animation, SUB_AGENT_FACES[:idle])
      end
    end
  end
end
