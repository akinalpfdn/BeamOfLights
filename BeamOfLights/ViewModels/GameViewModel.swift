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

// MARK: - Game View Model
@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentLevel: Level?
    @Published var gameState: GameState = .playing
    @Published var heartsRemaining: Int = 3
    @Published var currentPath: [Cell] = []
    @Published var allLevels: [Level] = []
    @Published var currentLevelIndex: Int = 0

    // MARK: - Private Properties
    private var correctPath: [Cell] = []

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
        buildCorrectPath()
        print("✅ Loaded level \(currentLevel?.levelNumber ?? 0)")
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
        currentPath = []
        heartsRemaining = currentLevel?.difficulty ?? 3
    }

    // MARK: - Path Building

    /// Build the correct path from start to end
    private func buildCorrectPath() {
        guard let level = currentLevel,
              let start = level.startCell else {
            print("❌ No start cell found")
            return
        }

        correctPath = [start]
        var current = start
        var visited = Set<String>()
        visited.insert("\(current.row),\(current.column)")

        // Follow the beam directions to build the complete path
        while current.type != .end {
            guard let next = getNextCell(from: current, in: level, visited: visited) else {
                break
            }
            correctPath.append(next)
            visited.insert("\(next.row),\(next.column)")
            current = next
        }

        print("✅ Correct path has \(correctPath.count) cells")
    }

    /// Get next cell in the beam direction
    private func getNextCell(from cell: Cell, in level: Level, visited: Set<String>) -> Cell? {
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

        // Check bounds
        guard nextRow >= 0 && nextRow < level.gridSize.rows &&
              nextColumn >= 0 && nextColumn < level.gridSize.columns else {
            return nil
        }

        // Check if already visited
        let key = "\(nextRow),\(nextColumn)"
        guard !visited.contains(key) else {
            return nil
        }

        return level.cell(at: nextRow, column: nextColumn)
    }

    // MARK: - Game Logic

    /// Handle cell tap/selection
    func selectCell(_ cell: Cell) {
        guard gameState == .playing else { return }

        // First tap should be the start cell
        if currentPath.isEmpty {
            if cell.type == .start {
                currentPath.append(cell)
                print("✅ Started path from start cell")
            } else {
                handleWrongMove()
                print("❌ Must start from start cell")
            }
            return
        }

        // Check if this is the next correct cell
        if isValidNextCell(cell) {
            currentPath.append(cell)
            print("✅ Added cell to path: \(cell.row),\(cell.column)")

            // Check if reached the end
            if cell.type == .end {
                handleWin()
            }
        } else {
            handleWrongMove()
            print("❌ Wrong cell selected")
        }
    }

    /// Validate if the cell is the correct next cell in the path
    private func isValidNextCell(_ cell: Cell) -> Bool {
        guard let lastCell = currentPath.last,
              currentPath.count < correctPath.count else {
            return false
        }

        let expectedNext = correctPath[currentPath.count]
        return cell.row == expectedNext.row && cell.column == expectedNext.column
    }

    /// Handle correct path completion
    private func handleWin() {
        gameState = .won
        print("🎉 Level completed!")
    }

    /// Handle wrong move
    private func handleWrongMove() {
        heartsRemaining -= 1
        currentPath = []

        if heartsRemaining <= 0 {
            gameState = .lost
            print("💔 Game over - no hearts remaining")
        } else {
            print("💔 Lost a heart - \(heartsRemaining) remaining")
        }
    }

    // MARK: - Helper Methods

    /// Check if a cell is in the current path
    func isInCurrentPath(_ cell: Cell) -> Bool {
        return currentPath.contains { $0.row == cell.row && $0.column == cell.column }
    }

    /// Check if a cell is in the correct path (for debugging/preview)
    func isInCorrectPath(_ cell: Cell) -> Bool {
        return correctPath.contains { $0.row == cell.row && $0.column == cell.column }
    }
}
