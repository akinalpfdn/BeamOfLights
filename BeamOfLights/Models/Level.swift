//
//  Level.swift
//  BeamOfLights
//
//  Data model representing a complete game level
//

import Foundation

// MARK: - Grid Size
struct GridSize: Codable {
    let rows: Int
    let columns: Int
}

// MARK: - Level Model
struct Level: Codable, Identifiable {
    let id: UUID
    let levelNumber: Int
    let gridSize: GridSize
    let difficulty: Int // Number of hearts (3-5)
    let cells: [Cell]

    // Custom initializer
    init(levelNumber: Int, gridSize: GridSize, difficulty: Int, cells: [Cell]) {
        self.id = UUID()
        self.levelNumber = levelNumber
        self.gridSize = gridSize
        self.difficulty = difficulty
        self.cells = cells
    }

    // Codable keys
    enum CodingKeys: String, CodingKey {
        case levelNumber, gridSize, difficulty, cells
    }

    // Custom decoder to generate UUID
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.levelNumber = try container.decode(Int.self, forKey: .levelNumber)
        self.gridSize = try container.decode(GridSize.self, forKey: .gridSize)
        self.difficulty = try container.decode(Int.self, forKey: .difficulty)
        self.cells = try container.decode([Cell].self, forKey: .cells)
    }

    // Helper method to get cell at specific position
    func cell(at row: Int, column: Int) -> Cell? {
        return cells.first { $0.row == row && $0.column == column }
    }

    // Get start cell
    var startCell: Cell? {
        return cells.first { $0.type == .start }
    }

    // Get end cell
    var endCell: Cell? {
        return cells.first { $0.type == .end }
    }
}

// MARK: - Levels Container
struct LevelsData: Codable {
    let levels: [Level]
}
