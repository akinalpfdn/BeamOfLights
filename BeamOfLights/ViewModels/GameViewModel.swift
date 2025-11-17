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
struct Beam: Identifiable, Equatable {
    let id: UUID
    let cells: [Cell]  // All cells that make up this beam
    let color: String
    var isSliding: Bool = false
    var slideOffset: CGFloat = 0  // For animation

    var direction: Direction {
        // Get the direction from the last cell (the arrow tip)
        cells.last?.direction ?? .none
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

        // Group cells by color
        var beamsByColor: [String: [Cell]] = [:]
        for cell in level.cells {
            if !cell.color.isEmpty {
                beamsByColor[cell.color, default: []].append(cell)
            }
        }

        // Create beam objects by following the connected path
        activeBeams = beamsByColor.compactMap { color, cells in
            guard let orderedCells = buildConnectedPath(for: cells) else {
                return nil
            }
            return Beam(cells: orderedCells, color: color)
        }

        print("✅ Built \(activeBeams.count) beams")
    }

    /// Build connected path by following cell directions
    private func buildConnectedPath(for cells: [Cell]) -> [Cell]? {
        // Find start cell (type == .start) or first cell if no start
        guard let startCell = cells.first(where: { $0.type == .start }) ?? cells.first else {
            return nil
        }

        var orderedCells: [Cell] = [startCell]
        var visited = Set<String>()
        visited.insert("\(startCell.row),\(startCell.column)")

        var current = startCell

        // Follow the direction to build the path
        while current.type != .end {
            guard let next = findNextCell(from: current, in: cells, visited: visited) else {
                break
            }
            orderedCells.append(next)
            visited.insert("\(next.row),\(next.column)")
            current = next
        }

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
        guard gameState == .playing else { return }

        // Find which beam was tapped
        if let beamIndex = findBeamAt(position: position, cellSize: cellSize, spacing: spacing) {
            let beam = activeBeams[beamIndex]

            // Light haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()

            print("✅ Tapped \(beam.color) beam - sliding \(beam.direction)")

            // Start sliding animation
            slideBeam(at: beamIndex)
        }
    }

    /// Find which beam contains the tapped position
    private func findBeamAt(position: CGPoint, cellSize: CGFloat, spacing: CGFloat) -> Int? {
        for (index, beam) in activeBeams.enumerated() {
            for cell in beam.cells {
                let cellPos = cellPosition(for: cell, cellSize: cellSize, spacing: spacing)
                let rect = CGRect(
                    x: cellPos.x - cellSize / 2,
                    y: cellPos.y - cellSize / 2,
                    width: cellSize,
                    height: cellSize
                )
                if rect.contains(position) {
                    return index
                }
            }
        }
        return nil
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
            return false
        }

        // Check against all other beams
        for otherBeam in activeBeams where otherBeam.id != beam.id {
            // Check if any cell of the other beam intersects with sliding path
            for otherCell in otherBeam.cells {
                if slidingPath.contains(where: { $0.row == otherCell.row && $0.column == otherCell.column }) {
                    return true  // Collision detected!
                }
            }
        }

        return false  // No collision
    }

    /// Get the path that the beam will slide through
    private func getBeamSlidingPath(_ beam: Beam) -> [GridPosition]? {
        guard let level = currentLevel else { return nil }

        var path: [GridPosition] = []
        let direction = beam.direction

        // Start from the tip (last cell) of the beam
        guard let tipCell = beam.cells.last else { return nil }

        var currentRow = tipCell.row
        var currentColumn = tipCell.column

        // Follow the direction until out of bounds
        while true {
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
                return path
            }

            // Check if out of bounds (successfully exit)
            if currentRow < 0 || currentRow >= level.gridSize.rows ||
               currentColumn < 0 || currentColumn >= level.gridSize.columns {
                break
            }

            path.append(GridPosition(row: currentRow, column: currentColumn))
        }

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

        // Success haptic
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Calculate slide distance (enough to exit canvas completely)
        let slideDistance: CGFloat = 500  // Enough to slide off screen

        // Animate beam sliding out with smooth spring animation
        withAnimation(.interpolatingSpring(duration: 1.0, bounce: 0.0)) {
            objectWillChange.send()  // Force SwiftUI to detect changes
            activeBeams[index].isSliding = true
            activeBeams[index].slideOffset = slideDistance
        }

        // Remove beam after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }

            self.activeBeams.remove(at: index)
            print("✅ Beam exited canvas - \(self.activeBeams.count) beams remaining")

            // Check win condition
            if self.activeBeams.isEmpty {
                self.handleWin()
            }
        }
    }

    /// Animate beam bouncing back (collision)
    private func animateBounceBack(at index: Int) {
        guard index < activeBeams.count else { return }

        wrongMoveTrigger.toggle()
        heartsRemaining -= 1
        heartLostTrigger.toggle()

        // Error haptic
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.error)

        print("❌ Beam collision - bouncing back")

        let bounceDistance: CGFloat = 80  // Small bounce distance

        // Animate forward then back with smooth bounce
        withAnimation(.interpolatingSpring(duration: 0.25, bounce: 0.0)) {
            objectWillChange.send()  // Force SwiftUI to detect changes
            activeBeams[index].slideOffset = bounceDistance
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self, index < self.activeBeams.count else { return }

            // Bounce back with stronger spring for tactile feel
            withAnimation(.interpolatingSpring(duration: 0.5, bounce: 0.3)) {
                self.objectWillChange.send()  // Force SwiftUI to detect changes
                self.activeBeams[index].slideOffset = 0
            }
        }

        if heartsRemaining <= 0 {
            gameState = .lost
            print("💔 Game over - no hearts remaining")
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
