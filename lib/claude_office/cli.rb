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

      puts "claude-office #{ClaudeOffice::VERSION}"
      puts "Project: #{project_path}"
      puts "Sound: #{sound ? "on" : "off"}"
      puts "(TUI not yet implemented)"
    end
  end
end
