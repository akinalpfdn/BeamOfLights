//
//  GameViewModel.swift
//  BeamOfLights
//
//  Main game logic and state management
//

import Foundation
import SwiftUI
import Combine

// MARK: - Game State
enum GameState {
    case playing
    case won
    case lost
}

// MARK: - Game Actions for SpriteKit
enum GameAction {
    case slideOut(beamID: UUID, direction: Direction)
    case bounce(beamID: UUID, direction: Direction)
    case reset
}

// MARK: - Beam representation for sliding puzzle
@Observable
class Beam: Identifiable, Equatable {
    let id: UUID
    var cells: [Cell]  // All cells that make up this beam
    let color: String
    var isSliding: Bool = false

    var direction: Direction {
        // Get the direction from the last non-end cell (the arrow tip)
        guard let lastCell = cells.last else { return .none }

        // If the last cell has a direction (not an end cell), use it
        if lastCell.direction != .none {
            return lastCell.direction
        }

        // If last cell is an end cell (direction: .none), find the previous cell's direction
        if cells.count >= 2, let secondToLastCell = cells.dropLast().last {
            return secondToLastCell.direction
        }
        
        return .none
    }

    init(id: UUID = UUID(), cells: [Cell], color: String, isSliding: Bool = false) {
        self.id = id
        self.cells = cells
        self.color = color
        self.isSliding = isSliding
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

    // Event Stream for SpriteKit
    let gameActions = PassthroughSubject<GameAction, Never>()

    // Feedback properties (kept for SwiftUI overlays if needed)
    @Published var showLevelCompleteAnimation: Bool = false

    private var isProcessingWin: Bool = false  // Prevent multiple win triggers


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
        gameActions.send(.reset) // Tell scene to reset
        print("✅ Loaded level \(currentLevel?.levelNumber ?? 0) with \(activeBeams.count) beams")
    }

    /// Move to next level
    func nextLevel() {
        isProcessingWin = false
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
        isProcessingWin = false
        showLevelCompleteAnimation = false
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
    }

    /// Build connected path by following cell directions
    private func buildConnectedPath(for cells: [Cell]) -> [Cell]? {
        guard let startCell = cells.first(where: { $0.type == .start }) ?? cells.first else { return nil }

        var orderedCells: [Cell] = [startCell]
        var visited = Set<String>()
        visited.insert("\(startCell.row),\(startCell.column)")

        var current = startCell
        var iterations = 0
        let maxIterations = cells.count * 2

        while current.type != .end && iterations < maxIterations {
            guard let next = findNextCell(from: current, in: cells, visited: visited) else { break }
            orderedCells.append(next)
            visited.insert("\(next.row),\(next.column)")
            current = next
            iterations += 1
        }
        return orderedCells
    }

    private func findNextCell(from cell: Cell, in cells: [Cell], visited: Set<String>) -> Cell? {
        var nextRow = cell.row
        var nextColumn = cell.column

        switch cell.direction {
        case .up: nextRow -= 1
        case .down: nextRow += 1
        case .left: nextColumn -= 1
        case .right: nextColumn += 1
        case .none: return nil
        }

        let key = "\(nextRow),\(nextColumn)"
        guard !visited.contains(key) else { return nil }

        return cells.first { $0.row == nextRow && $0.column == nextColumn }
    }

    // MARK: - Game Logic

    /// Handle beam tap - check logic and trigger action
    func tapBeam(atRow row: Int, column: Int) {
        guard gameState == .playing else { return }

        // Find which beam was tapped
        if let beamIndex = activeBeams.firstIndex(where: { beam in
            beam.cells.contains(where: { $0.row == row && $0.column == column })
        }) {
            let beam = activeBeams[beamIndex]
            
            // Check collision logic
            if willCollideWithOtherBeam(beam) {
                // Collision -> Bounce
                handleCollision(for: beam)
            } else {
                // Clear path -> Slide out
                handleSuccess(for: beam, at: beamIndex)
            }
        }
    }

    private func handleCollision(for beam: Beam) {
        // Lose a heart
        heartsRemaining -= 1
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.error)
        
        // Trigger bounce animation
        gameActions.send(.bounce(beamID: beam.id, direction: beam.direction))
        
        if heartsRemaining <= 0 {
            gameState = .lost
        }
    }
    
    private func handleSuccess(for beam: Beam, at index: Int) {
        // Trigger slide animation
        gameActions.send(.slideOut(beamID: beam.id, direction: beam.direction))
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Remove from logical model after a delay (matching animation roughly)
        // Or immediately, but we need to wait for win check.
        // Let's remove it immediately from our logic list, but maybe we should wait for the scene callback?
        // Simpler: Remove it now, so user can't tap it again.
        
        activeBeams.remove(at: index)
        
        if activeBeams.isEmpty {
            handleWin()
        }
    }

    /// Check if beam will collide with another beam when sliding
    private func willCollideWithOtherBeam(_ beam: Beam) -> Bool {
        guard let slidingPath = getBeamSlidingPath(beam) else { return false }

        for otherBeam in activeBeams where otherBeam.id != beam.id {
            for otherCell in otherBeam.cells {
                if slidingPath.contains(where: { $0.row == otherCell.row && $0.column == otherCell.column }) {
                    return true
                }
            }
        }
        return false
    }

    /// Get the path that the beam will slide through
    private func getBeamSlidingPath(_ beam: Beam) -> [GridPosition]? {
        guard let level = currentLevel else { return nil }
        var path: [GridPosition] = []
        let direction = beam.direction
        guard let tipCell = beam.cells.last else { return nil }

        var currentRow = tipCell.row
        var currentColumn = tipCell.column
        var steps = 0
        let maxSteps = max(level.gridSize.rows, level.gridSize.columns) + 1

        while steps < maxSteps {
            switch direction {
            case .up: currentRow -= 1
            case .down: currentRow += 1
            case .left: currentColumn -= 1
            case .right: currentColumn += 1
            case .none: return path
            }
            
            // If out of bounds, we are done
            if currentRow < 0 || currentRow >= level.gridSize.rows ||
               currentColumn < 0 || currentColumn >= level.gridSize.columns {
                break
            }
            path.append(GridPosition(row: currentRow, column: currentColumn))
            steps += 1
        }
        return path
    }

    private struct GridPosition {
        let row: Int
        let column: Int
    }

    private func handleWin() {
        guard !isProcessingWin, gameState == .playing else { return }
        isProcessingWin = true
        showLevelCompleteAnimation = true
        
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.nextLevel()
        }
    }
}
