require_relative "transcript/watcher"

module ClaudeOffice
  class CLI
    def self.run(args)
      if args.include?("--version")
        puts "claude-office #{ClaudeOffice::VERSION}"
        return
      end

      if args.include?("--help")
        puts <<~HELP
          Usage: claude-office [PROJECT_PATH] [OPTIONS]

          Watch Claude Code sessions as animated characters in a terminal office.

          Arguments:
            PROJECT_PATH    Path to project (default: current directory)

          Options:
            --no-sound      Disable terminal bell notifications
            --version       Show version
            --help          Show this help
        HELP
        return
      end

      project_path = args.reject { |a| a.start_with?("--") }.first || Dir.pwd
      sound = !args.include?("--no-sound")

      project_dir = Transcript::Watcher.claude_project_dir(project_path)

      unless Dir.exist?(project_dir)
        $stderr.puts "Error: No Claude Code data found for #{project_path}"
        $stderr.puts "Expected: #{project_dir}"
        $stderr.puts ""
        $stderr.puts "Make sure you've run Claude Code in that directory at least once."
        exit 1
      end

      require_relative "app"

      app = App.new(project_dir: project_dir, sound: sound)
      Bubbletea.run(app, alt_screen: true, mouse_cell_motion: true)
    end
  end
end
