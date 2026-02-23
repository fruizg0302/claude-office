require "spec_helper"
require "claude_office/office/pathfinder"
require "claude_office/office/grid"

RSpec.describe ClaudeOffice::Office::Pathfinder do
  it "finds a path between two walkable points" do
    grid = ClaudeOffice::Office::Grid.new(width: 40, height: 10)
    grid.layout_for(2)
    pathfinder = described_class.new(grid)

    start = grid.desks[0].chair_position
    goal = grid.desks[1].chair_position
    path = pathfinder.find_path(start, goal)

    expect(path).not_to be_nil
    expect(path.first).to eq(start)
    expect(path.last).to eq(goal)
  end

  it "returns nil when no path exists" do
    grid = ClaudeOffice::Office::Grid.new(width: 10, height: 10)
    grid.layout_for(1)
    pathfinder = described_class.new(grid)

    path = pathfinder.find_path([1, 1], [0, 0])
    expect(path).to be_nil
  end

  it "returns single-element path when start equals goal" do
    grid = ClaudeOffice::Office::Grid.new(width: 20, height: 10)
    grid.layout_for(1)
    pathfinder = described_class.new(grid)

    pos = grid.desks[0].chair_position
    path = pathfinder.find_path(pos, pos)
    expect(path).to eq([pos])
  end
end
