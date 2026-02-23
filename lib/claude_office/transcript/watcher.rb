require_relative "parser"
require_relative "events"

module ClaudeOffice
  module Transcript
    class Watcher
      POLL_INTERVAL = 2.0

      attr_reader :project_dir

      def initialize(project_dir, event_queue)
        @project_dir = project_dir
        @event_queue = event_queue
        @known_files = {}
        @running = false
        @thread = nil
      end

      def self.project_slug(path)
        path.gsub("/", "-")
      end

      def self.claude_project_dir(project_path)
        slug = project_slug(File.expand_path(project_path))
        File.join(Dir.home, ".claude", "projects", slug)
      end

      def start
        @running = true
        @thread = Thread.new { run_loop }
        @thread.abort_on_exception = true
      end

      def stop
        @running = false
        @thread&.join(2)
      end

      def scan_once
        return unless Dir.exist?(@project_dir)

        Dir.glob(File.join(@project_dir, "*.jsonl")).each do |path|
          next if @known_files.key?(path)

          session_id = File.basename(path, ".jsonl")
          parser = Parser.new(session_id)

          @known_files[path] = {
            parser: parser,
            offset: 0,
            line_buffer: ""
          }

          @event_queue.push(AgentCreated.new(
            session_id: session_id,
            jsonl_path: path
          ))
        end
      end

      def read_new_lines
        @known_files.each do |path, state|
          read_file_lines(path, state)
        end
      end

      private

      def run_loop
        while @running
          scan_once
          read_new_lines
          sleep(POLL_INTERVAL)
        end
      end

      def read_file_lines(path, state)
        return unless File.exist?(path)

        size = File.size(path)
        return if size <= state[:offset]

        data = File.binread(path, size - state[:offset], state[:offset])
        state[:offset] = size

        text = state[:line_buffer] + data.force_encoding("UTF-8")
        lines = text.split("\n", -1)
        state[:line_buffer] = lines.pop || ""

        lines.each do |line|
          next if line.strip.empty?

          events = state[:parser].parse_line(line)
          events.each { |e| @event_queue.push(e) }
        end
      end
    end
  end
end
