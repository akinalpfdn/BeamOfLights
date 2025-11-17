//
//  Cell.swift
//  BeamOfLights
//
//  Core data model representing a single cell in the game grid
//

import Foundation

// MARK: - Direction Enum
enum Direction: String, Codable {
    case up
    case down
    case left
    case right
    case none
}

// MARK: - Cell Type Enum
enum CellType: String, Codable {
    case start
    case end
    case path
    case empty
}

// MARK: - Cell Model
struct Cell: Codable, Identifiable {
    let id: UUID
    let row: Int
    let column: Int
    let type: CellType
    let direction: Direction
    let color: String // Color name for the light beam (e.g., "blue", "pink", "purple")

    // Custom initializer
    init(row: Int, column: Int, type: CellType, direction: Direction, color: String) {
        self.id = UUID()
        self.row = row
        self.column = column
        self.type = type
        self.direction = direction
        self.color = color
    }

    // Codable keys (UUID will be generated, not decoded)
    enum CodingKeys: String, CodingKey {
        case row, column, type, direction, color
    }

    // Custom decoder to generate UUID
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.row = try container.decode(Int.self, forKey: .row)
        self.column = try container.decode(Int.self, forKey: .column)
        self.type = try container.decode(CellType.self, forKey: .type)
        self.direction = try container.decode(Direction.self, forKey: .direction)
        self.color = try container.decode(String.self, forKey: .color)
    }
}
