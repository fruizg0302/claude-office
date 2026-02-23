require_relative "lib/claude_office/version"

Gem::Specification.new do |spec|
  spec.name = "claude-office"
  spec.version = ClaudeOffice::VERSION
  spec.authors = ["Fernando Ruiz"]
  spec.email = ["fruizg0302@users.noreply.github.com"]
  spec.summary = "A TUI companion for Claude Code — animated kaomoji agents in a virtual office"
  spec.description = "Watch Claude Code sessions come alive as kaomoji characters in a terminal office. " \
                     "Characters walk, type, read, and wait based on real-time JSONL transcript data."
  spec.homepage = "https://github.com/fruizg0302/claude-office"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/fruizg0302/claude-office",
    "changelog_uri" => "https://github.com/fruizg0302/claude-office/blob/master/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*", "bin/*", "LICENSE", "README.md"]
  spec.bindir = "bin"
  spec.executables = ["claude-office"]

  spec.add_dependency "bubbletea", "~> 0.1"
  spec.add_dependency "lipgloss", "~> 0.2"
  spec.add_dependency "harmonica", "~> 0.1"

  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rake", "~> 13.0"
end
