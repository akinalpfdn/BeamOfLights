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

// MARK: - Animation State
enum AnimationState {
    case idle
    case sliding
}

// MARK: - Beam representation for sliding puzzle
@Observable
class Beam: Identifiable, Equatable {
    let id: UUID
    let cells: [Cell]  // All cells that make up this beam
    let color: String
    var isSliding: Bool = false
    var slideOffset: CGFloat = 0  // For backward compatibility
    var cellOffsets: [CGFloat] = []  // Individual offsets for snake-like movement

    var direction: Direction {
        // Get the direction from the last non-end cell (the arrow tip)
        // End cells have direction: .none, so we need to find the cell that points TO the end
        guard let lastCell = cells.last else { return .none }

        // If the last cell has a direction (not an end cell), use it
        if lastCell.direction != .none {
            return lastCell.direction
        }

        // If last cell is an end cell (direction: .none), find the previous cell's direction
        if cells.count >= 2, let secondToLastCell = cells.dropLast().last {
            print("🔍 End cell has no direction, using previous cell's direction: \(secondToLastCell.direction)")
            return secondToLastCell.direction
        }

        print("⚠️ Could not determine beam direction")
        return .none
    }

    init(cells: [Cell], color: String, isSliding: Bool = false, slideOffset: CGFloat = 0) {
        self.id = UUID()
        self.cells = cells
        self.color = color
        self.isSliding = isSliding
        self.slideOffset = slideOffset
        self.cellOffsets = Array(repeating: 0, count: cells.count)  // Initialize all cells with 0 offset
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

    // Animation state management
    private var animationState: AnimationState = .idle
    private var isProcessingWin: Bool = false  // Prevent multiple win triggers

    // MARK: - Initialization
    init() {
        loadLevels()
        if !allLevels.isEmpty {
            loadLevel(at: 0)
        }
    }

    // Clean up when deallocated
    deinit {
        print("🧹 GameViewModel deinit - cleaning up \(activeAnimations.count) animations")
        activeAnimations.removeAll()
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
        // Reset win processing flag when moving to next level
        isProcessingWin = false

        let nextIndex = currentLevelIndex + 1
        if nextIndex < allLevels.count {
            print("🎮 Moving to level \(nextIndex + 1)")
            loadLevel(at: nextIndex)
        } else {
            print("🎉 All levels completed!")
        }
    }

    /// Reset current level
    func resetLevel() {
        gameState = .playing
        isProcessingWin = false  // Reset win processing flag
        activeAnimations.removeAll()  // Clear any animations
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
            print("⚠️ Cell (\(cell.row),\(cell.column)) has no direction")
            return nil
        }

        let key = "\(nextRow),\(nextColumn)"
        guard !visited.contains(key) else {
            print("⚠️ Already visited cell (\(nextRow),\(nextColumn))")
            return nil
        }

        let nextCell = cells.first { $0.row == nextRow && $0.column == nextColumn }
        if let nextCell = nextCell {
            print("🔗 Found next cell: (\(nextCell.row),\(nextCell.column)) from (\(cell.row),\(cell.column)) direction: \(cell.direction)")
        } else {
            print("❌ No cell found at (\(nextRow),\(nextColumn)) from (\(cell.row),\(cell.column)) direction: \(cell.direction)")
        }

        return nextCell
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
            slideBeam(at: beamIndex, cellSize: cellSize, spacing: spacing)
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
    private func slideBeam(at index: Int, cellSize: CGFloat = 60, spacing: CGFloat = 30) {
        guard index < activeBeams.count else { return }

        let beam = activeBeams[index]

        // Check if beam can exit (no collision)
        if willCollideWithOtherBeam(beam) {
            // Collision detected - bounce back
            animateBounceBack(at: index)
        } else {
            // No collision - exit canvas
            animateBeamExit(at: index, cellSize: cellSize, spacing: spacing)
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

    // MARK: - Sliding Animation Properties
    private var activeAnimations: Set<UUID> = []  // Track which beams are animating

    /// Animate beam sliding out of canvas (success) - snake-like movement
    private func animateBeamExit(at index: Int, cellSize: CGFloat = 60, spacing: CGFloat = 30) {
        guard index < activeBeams.count else { return }

        let beam = activeBeams[index]
        print("🐍 Starting snake-like slide animation for \(beam.color) beam")

        // Success haptic
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Calculate distance needed to slide completely off canvas
        let slideDistance = calculateRequiredSlideDistance(for: beam, cellSize: cellSize, spacing: spacing)

        if slideDistance <= 0 {
            print("⚠️ No slide distance needed for \(beam.color) beam")
            return
        }

        print("📏 Total slide distance: \(slideDistance)px")

        // Calculate duration based on 50px/sec speed
        let duration = slideDistance / 50.0
        print("⏱️ Animation duration: \(duration) seconds")

        beam.isSliding = true
        activeAnimations.insert(beam.id)

        // Create snake-like movement - each cell follows the path
        createSnakeAnimation(for: beam, at: index, distance: slideDistance, duration: duration)
    }

    /// Create step-by-step sliding animation where beam moves one grid cell at a time
    private func createSnakeAnimation(for beam: Beam, at index: Int, distance: CGFloat, duration: TimeInterval) {
        let cellSize: CGFloat = 60
        let spacing: CGFloat = 30
        let stepDistance = cellSize + spacing  // Distance to move one grid cell

        print("🐍 Step-by-step animation: beam moves \(stepDistance)px per step at 50px/sec")

        // Calculate how many steps to exit the grid
        let totalSteps = Int(distance / stepDistance)
        let stepDuration = stepDistance / 50.0  // Time per step at 50px/sec

        print("📏 Total steps: \(totalSteps), step duration: \(stepDuration)s")

        // Animate step by step
        animateBeamStep(beam: beam, at: index, currentStep: 0, totalSteps: totalSteps, stepDuration: stepDuration, stepDistance: stepDistance)
    }

    /// Animate one step of the beam movement - snake-like where each cell follows previous cell
    private func animateBeamStep(beam: Beam, at index: Int, currentStep: Int, totalSteps: Int, stepDuration: TimeInterval, stepDistance: CGFloat) {
        guard currentStep < totalSteps && index < activeBeams.count else {
            // Animation complete - remove beam
            finishBeamAnimation(at: index, beam: beam)
            return
        }

        print("🐍 Snake Step \(currentStep + 1)/\(totalSteps) for \(beam.color) beam")

        // Calculate new positions for each cell - each cell moves to previous cell's position
        let newOffsets = calculateSnakePositions(for: beam, step: currentStep, stepDistance: stepDistance, direction: beam.direction)
        print("   New offsets: \(newOffsets.map { String(format: "%.0f", $0) }.joined(separator: ", "))")

        // Animate cells to their new positions
        withAnimation(.linear(duration: stepDuration)) {
            self.activeBeams[index].cellOffsets = newOffsets
        }

        // Schedule next step
        DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration) {
            self.animateBeamStep(beam: beam, at: index, currentStep: currentStep + 1, totalSteps: totalSteps, stepDuration: stepDuration, stepDistance: stepDistance)
        }
    }

    /// Calculate snake-like positions where each cell follows the previous cell's path
    private func calculateSnakePositions(for beam: Beam, step: Int, stepDistance: CGFloat, direction: Direction) -> [CGFloat] {
        var offsets: [CGFloat] = []

        // For snake movement, each cell moves to where the previous cell was
        // First cell (head) moves forward, others follow
        for i in 0..<beam.cells.count {
            if i == 0 {
                // Head cell moves forward
                offsets.append(CGFloat(step + 1) * stepDistance)
            } else {
                // Body cells follow previous cell's path with delay
                // Cell 1 follows where cell 0 was, cell 2 follows where cell 1 was, etc.
                let followDelay = max(0, step - i + 1)
                offsets.append(CGFloat(followDelay) * stepDistance)
            }
        }

        return offsets
    }

    /// Finish beam animation and remove beam
    private func finishBeamAnimation(at index: Int, beam: Beam) {
        print("✅ Step-by-step animation finished for \(beam.color) beam")

        // Remove beam and clean up
        if index < activeBeams.count {
            activeBeams[index].isSliding = false
            activeBeams.remove(at: index)
        }
        activeAnimations.remove(beam.id)

        // Check win condition
        if activeBeams.isEmpty && activeAnimations.isEmpty && gameState == .playing && !isProcessingWin {
            print("🎯 All beams removed - checking win condition")
            handleWin()
        }
    }

    /// Animate beam bouncing back (collision) - simple SwiftUI animation
    private func animateBounceBack(at index: Int) {
        guard index < activeBeams.count else { return }

        let beam = activeBeams[index]
        print("💥 Starting bounce-back animation for \(beam.color) beam")

        wrongMoveTrigger.toggle()
        heartsRemaining -= 1
        heartLostTrigger.toggle()

        // Error haptic
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.error)

        // Calculate bounce distance (short distance, then reverse)
        let bounceDistance: CGFloat = 80
        print("📏 Bounce distance: \(bounceDistance)px")

        beam.isSliding = true
        activeAnimations.insert(beam.id)

        // Slide forward first
        withAnimation(.easeOut(duration: 0.4)) {
            beam.slideOffset = bounceDistance
        }

        // Then slide back with spring
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else { return }

            withAnimation(.interpolatingSpring(duration: 0.6, bounce: 0.4)) {
                if index < self.activeBeams.count {
                    self.activeBeams[index].slideOffset = 0
                    self.activeBeams[index].isSliding = false
                }
            }

            self.activeAnimations.remove(beam.id)
        }

        if heartsRemaining <= 0 {
            gameState = .lost
            print("💔 Game over - no hearts remaining")
        }
    }

    /// Calculate the exact distance needed for beam to exit canvas
    private func calculateRequiredSlideDistance(for beam: Beam, cellSize: CGFloat = 60, spacing: CGFloat = 30) -> CGFloat {
        guard let level = currentLevel, let tipCell = beam.cells.last else {
            return 0
        }

        // Calculate current tip position
        let tipX = 30 + CGFloat(tipCell.column) * (cellSize + spacing) + cellSize / 2
        let tipY = CGFloat(tipCell.row) * (cellSize + spacing) + cellSize / 2

        // Calculate distance to canvas edge
        let canvasWidth = CGFloat(level.gridSize.columns) * (cellSize + spacing) + 30
        let canvasHeight = CGFloat(level.gridSize.rows) * (cellSize + spacing) + cellSize

        let slideDistance: CGFloat
        switch beam.direction {
        case .up:
            slideDistance = tipY + 100  // Slide up past top edge
        case .down:
            slideDistance = (canvasHeight - tipY) + 100  // Slide down past bottom edge
        case .left:
            slideDistance = tipX + 100  // Slide left past left edge
        case .right:
            slideDistance = (canvasWidth - tipX) + 100  // Slide right past right edge
        case .none:
            slideDistance = 0
        }

        print("📐 Beam tip at (\(tipX), \(tipY)), canvas size: \(canvasWidth)x\(canvasHeight)")
        return slideDistance
    }

    /// Handle level completion (all beams removed)
    private func handleWin() {
        // Prevent multiple win condition triggers
        guard !isProcessingWin else {
            print("⚠️ Already processing win condition - skipping")
            return
        }

        guard gameState == .playing else {
            print("⚠️ Game not in playing state - skipping win condition")
            return
        }

        print("🎯 Starting win condition processing")

        // Immediately set flags to prevent any further processing
        isProcessingWin = true
        gameState = .won

        // Clear all animations
        print("🛑 Clearing all animations (\(activeAnimations.count) animations)")
        activeAnimations.removeAll()

        levelCompleteTrigger.toggle()

        // Heavy haptic feedback for success
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        print("🎉 Level completed! All beams removed from canvas!")

        // Don't reset the flag - it will be reset when moving to next level
    }
}
