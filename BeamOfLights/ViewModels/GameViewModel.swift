//
//  GameViewModel.swift
//  BeamOfLights
//
//  Main game logic and state management
//

import Foundation
import SwiftUI
internal import Combine

// MARK: - Game State
enum GameState {
    case playing
    case won
    case lost
}

// MARK: - Beam representation for sliding puzzle
@Observable
class Beam: Identifiable, Equatable {
    let id: UUID
    let cells: [Cell]  // All cells that make up this beam
    let color: String
    var isSliding: Bool = false
    var slideOffset: CGFloat = 0  // For animation

    var direction: Direction {
        // Get the direction from the last cell (the arrow tip)
        guard let lastCell = cells.last else { return .none }
        return lastCell.direction
    }

    init(cells: [Cell], color: String, isSliding: Bool = false, slideOffset: CGFloat = 0) {
        self.id = UUID()
        self.cells = cells
        self.color = color
        self.isSliding = isSliding
        self.slideOffset = slideOffset
    }

    static func == (lhs: Beam, rhs: Beam) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Game View Model
@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentLevel: Level?
    @Published var gameState: GameState = .playing
    @Published var heartsRemaining: Int = 3
    @Published var activeBeams: [Beam] = []  // Beams currently on canvas
    @Published var allLevels: [Level] = []
    @Published var currentLevelIndex: Int = 0

    // Feedback properties for animations
    @Published var wrongMoveTrigger: Bool = false
    @Published var heartLostTrigger: Bool = false
    @Published var levelCompleteTrigger: Bool = false

    // MARK: - Initialization
    init() {
        loadLevels()
        if !allLevels.isEmpty {
            loadLevel(at: 0)
        }
    }

    // MARK: - Level Loading

    /// Load all levels from JSON file
    func loadLevels() {
        guard let url = Bundle.main.url(forResource: "levels", withExtension: "json") else {
            print("❌ Could not find levels.json")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let levelsData = try decoder.decode(LevelsData.self, from: data)
            self.allLevels = levelsData.levels
            print("✅ Loaded \(allLevels.count) levels")
        } catch {
            print("❌ Error loading levels: \(error)")
        }
    }

    /// Load specific level by index
    func loadLevel(at index: Int) {
        guard index >= 0 && index < allLevels.count else {
            print("❌ Invalid level index: \(index)")
            return
        }

        currentLevelIndex = index
        currentLevel = allLevels[index]
        resetLevel()
        buildBeams()
        print("✅ Loaded level \(currentLevel?.levelNumber ?? 0) with \(activeBeams.count) beams")
    }

    /// Move to next level
    func nextLevel() {
        let nextIndex = currentLevelIndex + 1
        if nextIndex < allLevels.count {
            loadLevel(at: nextIndex)
        } else {
            print("🎉 All levels completed!")
        }
    }

    /// Reset current level
    func resetLevel() {
        gameState = .playing
        activeBeams = []
        heartsRemaining = currentLevel?.difficulty ?? 3
    }

    // MARK: - Beam Building

    /// Build all beams from level cells by grouping cells with same color
    private func buildBeams() {
        guard let level = currentLevel else { return }

        print("🏗️ Building beams from level \(level.levelNumber) with \(level.cells.count) cells")

        // Group cells by color
        var beamsByColor: [String: [Cell]] = [:]
        for cell in level.cells {
            if !cell.color.isEmpty {
                beamsByColor[cell.color, default: []].append(cell)
            }
        }

        print("🎨 Found cells grouped by color: \(beamsByColor.map { "\($0.key): \($0.value.count)" })")

        // Create beam objects by following the connected path
        activeBeams = beamsByColor.compactMap { color, cells in
            print("🔗 Building beam for color: \(color) with \(cells.count) cells")
            guard let orderedCells = buildConnectedPath(for: cells) else {
                print("❌ Failed to build connected path for color: \(color)")
                return nil
            }
            let beam = Beam(cells: orderedCells, color: color)
            print("✅ Created \(color) beam with \(beam.cells.count) cells, direction: \(beam.direction)")
            return beam
        }

        print("✅ Built \(activeBeams.count) total beams")
        for (index, beam) in activeBeams.enumerated() {
            print("   Beam \(index): \(beam.color), \(beam.cells.count) cells, direction: \(beam.direction)")
        }
    }

    /// Build connected path by following cell directions
    private func buildConnectedPath(for cells: [Cell]) -> [Cell]? {
        // Find start cell (type == .start) or first cell if no start
        guard let startCell = cells.first(where: { $0.type == .start }) ?? cells.first else {
            print("❌ No start cell found for color: \(cells.first?.color ?? "unknown")")
            return nil
        }

        var orderedCells: [Cell] = [startCell]
        var visited = Set<String>()
        visited.insert("\(startCell.row),\(startCell.column)")

        var current = startCell
        var iterations = 0
        let maxIterations = cells.count * 2  // Prevent infinite loops

        // Follow the direction to build the path
        while current.type != .end && iterations < maxIterations {
            guard let next = findNextCell(from: current, in: cells, visited: visited) else {
                print("⚠️ Could not find next cell from (\(current.row),\(current.column)) for color: \(current.color)")
                break
            }
            orderedCells.append(next)
            visited.insert("\(next.row),\(next.column)")
            current = next
            iterations += 1
        }

        print("✅ Built path for \(startCell.color): \(orderedCells.count) cells from start to end")
        return orderedCells
    }

    /// Find the next connected cell in the beam
    private func findNextCell(from cell: Cell, in cells: [Cell], visited: Set<String>) -> Cell? {
        var nextRow = cell.row
        var nextColumn = cell.column

        switch cell.direction {
        case .up:
            nextRow -= 1
        case .down:
            nextRow += 1
        case .left:
            nextColumn -= 1
        case .right:
            nextColumn += 1
        case .none:
            return nil
        }

        let key = "\(nextRow),\(nextColumn)"
        guard !visited.contains(key) else {
            return nil
        }

        return cells.first { $0.row == nextRow && $0.column == nextColumn }
    }

    // MARK: - Game Logic (Sliding Puzzle)

    /// Handle beam tap - start sliding animation
    func tapBeam(at position: CGPoint, cellSize: CGFloat, spacing: CGFloat) {
        print("🎯 tapBeam called at position: \(position), cellSize: \(cellSize), spacing: \(spacing)")
        print("🎮 Game state: \(gameState), Active beams count: \(activeBeams.count)")

        guard gameState == .playing else {
            print("❌ Game not in playing state")
            return
        }

        // Find which beam was tapped
        if let beamIndex = findBeamAt(position: position, cellSize: cellSize, spacing: spacing) {
            let beam = activeBeams[beamIndex]

            // Light haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()

            print("✅ Tapped \(beam.color) beam at index \(beamIndex) - sliding \(beam.direction)")

            // Start sliding animation
            slideBeam(at: beamIndex)
        } else {
            print("❌ No beam found at tap position")
        }
    }

    /// Find which beam contains the tapped position using continuous path detection
    private func findBeamAt(position: CGPoint, cellSize: CGFloat, spacing: CGFloat) -> Int? {
        print("🔍 Searching for beam at tap position: \(position)")

        for (index, beam) in activeBeams.enumerated() {
            print("🔍 Checking beam \(index): \(beam.color) with \(beam.cells.count) cells")

            if isPointNearBeamPath(position: position, beam: beam, cellSize: cellSize, spacing: spacing) {
                print("   ✅ FOUND! Beam \(index) (\(beam.color)) contains tap position")
                return index
            }
        }

        print("❌ No beam found at tap position")
        return nil
    }

    /// Check if a point is near the beam's continuous path
    private func isPointNearBeamPath(position: CGPoint, beam: Beam, cellSize: CGFloat, spacing: CGFloat) -> Bool {
        // Build the beam path
        guard let startCell = beam.cells.first else { return false }

        var path = Path()
        path.move(to: cellPosition(for: startCell, cellSize: cellSize, spacing: spacing))

        var currentCell: Cell? = startCell
        while let cell = currentCell, cell.type != .end {
            currentCell = getNextCellFromBeam(from: cell, in: beam.cells)
            if let next = currentCell {
                path.addLine(to: cellPosition(for: next, cellSize: cellSize, spacing: spacing))
            }
        }

        // Create a thicker stroke area around the path for tap detection
        let beamWidth = cellSize * 0.4  // Use same width as in ContinuousBeamPath
        let tapTolerance = beamWidth + 10  // Add 10pt tolerance for easier tapping

        // Check each segment of the path
        for i in 0..<beam.cells.count - 1 {
            let cell1 = beam.cells[i]
            let cell2 = beam.cells[i + 1]

            let pos1 = cellPosition(for: cell1, cellSize: cellSize, spacing: spacing)
            let pos2 = cellPosition(for: cell2, cellSize: cellSize, spacing: spacing)

            // Calculate distance from point to line segment
            if distanceFromPointToLineSegment(position, pos1, pos2) <= tapTolerance / 2 {
                print("   🎯 Point is within tolerance of segment \(i)")
                return true
            }
        }

        return false
    }

    /// Get next cell from beam's cells (similar to ContinuousBeamPath.getNextCell)
    private func getNextCellFromBeam(from cell: Cell, in cells: [Cell]) -> Cell? {
        var nextRow = cell.row
        var nextColumn = cell.column

        switch cell.direction {
        case .up: nextRow -= 1
        case .down: nextRow += 1
        case .left: nextColumn -= 1
        case .right: nextColumn += 1
        case .none: return nil
        }

        return cells.first { $0.row == nextRow && $0.column == nextColumn }
    }

    /// Calculate distance from point to line segment
    private func distanceFromPointToLineSegment(_ point: CGPoint, _ lineStart: CGPoint, _ lineEnd: CGPoint) -> CGFloat {
        let A = point.x - lineStart.x
        let B = point.y - lineStart.y
        let C = lineEnd.x - lineStart.x
        let D = lineEnd.y - lineStart.y

        let dot = A * C + B * D
        let lenSq = C * C + D * D

        if lenSq == 0 { return sqrt(A * A + B * B) }

        var param = dot / lenSq

        var xx: CGFloat, yy: CGFloat

        if param < 0 {
            xx = lineStart.x
            yy = lineStart.y
        } else if param > 1 {
            xx = lineEnd.x
            yy = lineEnd.y
        } else {
            xx = lineStart.x + param * C
            yy = lineStart.y + param * D
        }

        let dx = point.x - xx
        let dy = point.y - yy

        return sqrt(dx * dx + dy * dy)
    }

    /// Calculate cell position on screen
    private func cellPosition(for cell: Cell, cellSize: CGFloat, spacing: CGFloat) -> CGPoint {
        let x = 30 + CGFloat(cell.column) * (cellSize + spacing) + cellSize / 2
        let y = CGFloat(cell.row) * (cellSize + spacing) + cellSize / 2
        return CGPoint(x: x, y: y)
    }

    /// Slide beam in its direction
    private func slideBeam(at index: Int) {
        guard index < activeBeams.count else { return }

        let beam = activeBeams[index]

        // Check if beam can exit (no collision)
        if willCollideWithOtherBeam(beam) {
            // Collision detected - bounce back
            animateBounceBack(at: index)
        } else {
            // No collision - exit canvas
            animateBeamExit(at: index)
        }
    }

    /// Check if beam will collide with another beam when sliding
    private func willCollideWithOtherBeam(_ beam: Beam) -> Bool {
        // Get the beam's sliding path
        guard let slidingPath = getBeamSlidingPath(beam) else {
            print("⚠️ Could not get sliding path for beam")
            return false
        }

        print("🔍 Checking collision for \(beam.color) beam, sliding path has \(slidingPath.count) positions")

        // Check against all other beams
        for otherBeam in activeBeams where otherBeam.id != beam.id {
            // Check if any cell of the other beam intersects with sliding path
            for otherCell in otherBeam.cells {
                if slidingPath.contains(where: { position in
                    position.row == otherCell.row && position.column == otherCell.column
                }) {
                    print("💥 Collision detected! \(beam.color) beam would hit \(otherBeam.color) beam at (\(otherCell.row),\(otherCell.column))")
                    return true  // Collision detected!
                }
            }
        }

        print("✅ No collision detected for \(beam.color) beam")
        return false  // No collision
    }

    /// Get the path that the beam will slide through
    private func getBeamSlidingPath(_ beam: Beam) -> [GridPosition]? {
        guard let level = currentLevel else { return nil }

        var path: [GridPosition] = []
        let direction = beam.direction

        print("🛤️ Calculating sliding path for \(beam.color) beam moving \(direction)")

        // Start from the tip (last cell) of the beam
        guard let tipCell = beam.cells.last else {
            print("❌ No tip cell found for beam")
            return nil
        }

        var currentRow = tipCell.row
        var currentColumn = tipCell.column
        var steps = 0
        let maxSteps = max(level.gridSize.rows, level.gridSize.columns) + 5  // Allow sliding out of bounds

        // Follow the direction until out of bounds or max steps reached
        while steps < maxSteps {
            switch direction {
            case .up:
                currentRow -= 1
            case .down:
                currentRow += 1
            case .left:
                currentColumn -= 1
            case .right:
                currentColumn += 1
            case .none:
                print("⚠️ Beam has no direction")
                return path
            }

            // Check if out of bounds (successfully exit)
            if currentRow < 0 || currentRow >= level.gridSize.rows ||
               currentColumn < 0 || currentColumn >= level.gridSize.columns {
                print("✅ Beam will exit canvas at step \(steps)")
                break
            }

            path.append(GridPosition(row: currentRow, column: currentColumn))
            steps += 1
        }

        print("📏 Sliding path: \(path.map { "(\($0.row),\($0.column))" }.joined(separator: " → "))")
        return path
    }

    /// Simple grid position struct for collision detection
    private struct GridPosition {
        let row: Int
        let column: Int
    }

    /// Animate beam sliding out of canvas (success)
    private func animateBeamExit(at index: Int) {
        guard index < activeBeams.count else { return }

        let beam = activeBeams[index]
        print("🎯 Animating beam exit for \(beam.color) beam")

        // Success haptic
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Calculate slide distance based on direction and screen size
        let slideDistance = calculateSlideDistance(for: beam.direction)

        // Animate beam sliding out with smooth animation
        withAnimation(.easeInOut(duration: 1.0)) {
            beam.isSliding = true
            beam.slideOffset = slideDistance
        }

        // Remove beam after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }

            if index < self.activeBeams.count {
                print("✅ Beam exited canvas - removing from active beams")
                self.activeBeams.remove(at: index)

                // Check win condition
                if self.activeBeams.isEmpty {
                    self.handleWin()
                }
            }
        }
    }

    /// Animate beam bouncing back (collision)
    private func animateBounceBack(at index: Int) {
        guard index < activeBeams.count else { return }

        let beam = activeBeams[index]
        print("💥 Animating bounce back for \(beam.color) beam")

        wrongMoveTrigger.toggle()
        heartsRemaining -= 1
        heartLostTrigger.toggle()

        // Error haptic
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.error)

        let bounceDistance = calculateSlideDistance(for: beam.direction) * 0.3  // 30% of full distance

        // Animate forward then back with smooth bounce
        withAnimation(.easeInOut(duration: 0.3)) {
            beam.isSliding = true
            beam.slideOffset = bounceDistance
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }

            // Bounce back with stronger spring for tactile feel
            withAnimation(.interpolatingSpring(duration: 0.6, bounce: 0.4)) {
                if index < self.activeBeams.count {
                    self.activeBeams[index].slideOffset = 0
                    self.activeBeams[index].isSliding = false
                }
            }
        }

        if heartsRemaining <= 0 {
            gameState = .lost
            print("💔 Game over - no hearts remaining")
        }
    }

    /// Calculate slide distance based on beam direction
    private func calculateSlideDistance(for direction: Direction) -> CGFloat {
        // Calculate distance needed to slide completely off screen
        // This is a simplified calculation - in a real app you'd use actual screen dimensions
        switch direction {
        case .up, .down:
            return 600  // Vertical slide distance
        case .left, .right:
            return 800  // Horizontal slide distance
        case .none:
            return 0
        }
    }

    /// Handle level completion (all beams removed)
    private func handleWin() {
        gameState = .won
        levelCompleteTrigger.toggle()

        // Heavy haptic feedback for success
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        print("🎉 Level completed! All beams removed from canvas!")
    }
}
