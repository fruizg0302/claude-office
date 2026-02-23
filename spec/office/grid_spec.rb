require "spec_helper"
require "claude_office/office/grid"

RSpec.describe ClaudeOffice::Office::Grid do
  describe "#layout_for" do
    it "creates a grid with one desk for one agent" do
      grid = described_class.new(width: 40, height: 15)
      grid.layout_for(1)
      expect(grid.desks.length).to eq(1)
    end

    it "creates a grid with three desks in one row" do
      grid = described_class.new(width: 60, height: 15)
      grid.layout_for(3)
      expect(grid.desks.length).to eq(3)
      ys = grid.desks.map { |d| d.position[1] }
      expect(ys.uniq.length).to eq(1)
    end

    it "wraps to second row for 4+ agents" do
      grid = described_class.new(width: 60, height: 20)
      grid.layout_for(4)
      expect(grid.desks.length).to eq(4)
      ys = grid.desks.map { |d| d.position[1] }
      expect(ys.uniq.length).to eq(2)
    end

    it "assigns chair positions below each desk" do
      grid = described_class.new(width: 40, height: 15)
      grid.layout_for(1)
      desk = grid.desks.first
      expect(desk.chair_position[1]).to be > desk.position[1]
    end
  end

  describe "#walkable?" do
    it "returns true for floor tiles" do
      grid = described_class.new(width: 20, height: 10)
      grid.layout_for(1)
      expect(grid.walkable?(1, 1)).to be true
    end

    it "returns false for wall tiles" do
      grid = described_class.new(width: 20, height: 10)
      grid.layout_for(1)
      expect(grid.walkable?(0, 0)).to be false
    end
  end
end
