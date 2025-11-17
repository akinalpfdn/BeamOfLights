//
//  CellView.swift
//  BeamOfLights
//
//  View for displaying a single grid cell
//

import SwiftUI

struct CellView: View {
    let cell: Cell
    let isInCurrentPath: Bool
    let cellSize: CGFloat

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .frame(width: cellSize, height: cellSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: isInCurrentPath ? 3 : 1)
                )

            // Beautiful light beam instead of arrows
            if cell.direction != .none {
                BeamView(
                    direction: cell.direction,
                    color: beamColor,
                    isActive: isInCurrentPath
                )
                .frame(width: cellSize * 0.9, height: cellSize * 0.9)
                .opacity(isInCurrentPath ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 0.3), value: isInCurrentPath)
            }

            // Special markers for start/end with glow
            if cell.type == .start {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(beamColor)
                        .frame(width: cellSize * 0.4, height: cellSize * 0.4)
                        .blur(radius: 8)
                        .opacity(0.6)

                    // Main circle
                    Circle()
                        .fill(beamColor)
                        .frame(width: cellSize * 0.3, height: cellSize * 0.3)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(color: beamColor.opacity(0.5), radius: 6, x: 0, y: 2)
                }
            } else if cell.type == .end {
                ZStack {
                    // Glow effect
                    RoundedRectangle(cornerRadius: 6)
                        .fill(beamColor)
                        .frame(width: cellSize * 0.4, height: cellSize * 0.4)
                        .blur(radius: 8)
                        .opacity(0.6)

                    // Main square
                    RoundedRectangle(cornerRadius: 6)
                        .fill(beamColor)
                        .frame(width: cellSize * 0.3, height: cellSize * 0.3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(color: beamColor.opacity(0.5), radius: 6, x: 0, y: 2)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var backgroundColor: Color {
        switch cell.type {
        case .empty:
            return Color.gray.opacity(0.1)
        case .start, .end:
            return beamColor.opacity(0.2)
        case .path:
            return isInCurrentPath ? beamColor.opacity(0.3) : Color.white
        }
    }

    private var borderColor: Color {
        if isInCurrentPath {
            return beamColor
        }
        return Color.gray.opacity(0.3)
    }

    private var beamColor: Color {
        switch cell.color.lowercased() {
        case "blue":
            return Color(red: 0.66, green: 0.85, blue: 0.92) // Soft Blue #A8D8EA
        case "pink":
            return Color(red: 1.0, green: 0.71, blue: 0.76) // Soft Pink #FFB6C1
        case "purple":
            return Color(red: 0.83, green: 0.71, blue: 0.94) // Soft Purple #D4B5F0
        case "green":
            return Color(red: 0.71, green: 0.91, blue: 0.81) // Soft Green #B4E7CE
        case "orange":
            return Color(red: 1.0, green: 0.83, blue: 0.64) // Soft Orange #FFD4A3
        default:
            return Color.gray
        }
    }

}

// MARK: - Preview
#Preview {
    HStack(spacing: 20) {
        CellView(
            cell: Cell(row: 0, column: 0, type: .start, direction: .right, color: "blue"),
            isInCurrentPath: false,
            cellSize: 70
        )

        CellView(
            cell: Cell(row: 0, column: 1, type: .path, direction: .down, color: "pink"),
            isInCurrentPath: true,
            cellSize: 70
        )

        CellView(
            cell: Cell(row: 0, column: 2, type: .end, direction: .none, color: "purple"),
            isInCurrentPath: false,
            cellSize: 70
        )

        CellView(
            cell: Cell(row: 0, column: 3, type: .empty, direction: .none, color: ""),
            isInCurrentPath: false,
            cellSize: 70
        )
    }
    .padding()
}
