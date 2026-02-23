require "bubbletea"
require "lipgloss"
require_relative "transcript/watcher"
require_relative "agents/registry"
require_relative "office/grid"
require_relative "office/pathfinder"
require_relative "rendering/renderer"
require_relative "animation/frame_cycle"
require_relative "notification"

module ClaudeOffice
  class TickMessage < Bubbletea::Message; end

  class App
    include Bubbletea::Model

    FPS = 30
    GRID_WIDTH = 60
    GRID_HEIGHT = 20

    def initialize(project_dir:, sound: true)
      @project_dir = project_dir
      @sound = sound
      @registry = Agents::Registry.new
      @grid = Office::Grid.new(width: GRID_WIDTH, height: GRID_HEIGHT)
      @pathfinder = Office::Pathfinder.new(@grid)
      @renderer = Rendering::Renderer.new(width: GRID_WIDTH, height: GRID_HEIGHT)
      @notification = Notification.new(sound_enabled: sound)
      @frame_cycle = Animation::FrameCycle.new(frame_count: 2, frames_per_tick: 15)
      @event_queue = Queue.new
      @watcher = nil
      @width = GRID_WIDTH
      @height = GRID_HEIGHT
    end

    def init
      @watcher = Transcript::Watcher.new(@project_dir, @event_queue)
      @watcher.start

      [self, schedule_tick]
    end

    def update(message)
      case message
      when Bubbletea::KeyMessage
        handle_key(message)
      when Bubbletea::WindowSizeMessage
        @width = message.width
        @height = message.height
        grid_w = [@width, GRID_WIDTH].min
        grid_h = [message.height - 4, GRID_HEIGHT].min
        @grid = Office::Grid.new(width: grid_w, height: grid_h)
        @grid.layout_for(@registry.count)
        @pathfinder = Office::Pathfinder.new(@grid)
        @renderer = Rendering::Renderer.new(width: @grid.width, height: @grid.height)
        [self, nil]
      when TickMessage
        handle_tick
      else
        [self, nil]
      end
    end

    def view
      agents = []
      @registry.each { |a| agents << a }
      @renderer.render(grid: @grid, agents: agents, frame: @frame_cycle.frame)
    end

    private

    def handle_key(message)
      case message.to_s
      when "q", "ctrl+c"
        @watcher&.stop
        [self, Bubbletea.quit]
      else
        [self, nil]
      end
    end

    def handle_tick
      while (event = @event_queue.pop(true) rescue nil)
        process_event(event)
      end

      @frame_cycle.advance

      [self, schedule_tick]
    end

    def process_event(event)
      case event
      when Transcript::AgentCreated
        desk_pos = next_desk_position
        @registry.add(event.session_id, desk_pos)
        @grid.layout_for(@registry.count)
        @pathfinder = Office::Pathfinder.new(@grid)
        reassign_desk_positions

      when Transcript::ToolStart
        agent = @registry.get(event.session_id)
        agent&.tool_started(event.tool_id, event.tool_name, event.status_text)

      when Transcript::ToolDone
        agent = @registry.get(event.session_id)
        agent&.tool_done(event.tool_id)

      when Transcript::TurnEnd
        agent = @registry.get(event.session_id)
        if agent
          agent.turn_ended
          @notification.agent_turn_ended(event.session_id)
        end

      when Transcript::SubAgentToolStart
        agent = @registry.get(event.session_id)
        agent&.sub_agent_tool_started(
          event.parent_tool_id, event.tool_id,
          event.tool_name, event.status_text
        )

      when Transcript::SubAgentToolDone
        agent = @registry.get(event.session_id)
        agent&.sub_agent_tool_done(event.parent_tool_id, event.tool_id)
      end
    end

    def next_desk_position
      count = @registry.count
      [3 + (count % 3) * 13, 3 + (count / 3) * 7]
    end

    def reassign_desk_positions
      index = 0
      @registry.each do |agent|
        if index < @grid.desks.length
          desk = @grid.desks[index]
          desk.assign(agent.session_id)
        end
        index += 1
      end
    end

    def schedule_tick
      Bubbletea.tick(1.0 / FPS) { TickMessage.new }
    end
  end
end
