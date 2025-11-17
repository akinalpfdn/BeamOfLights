//
//  ContinuousBeamPath.swift
//  BeamOfLights
//
//  Renders continuous, connected light beam paths
//

import SwiftUI

// MARK: - Continuous Beam Renderer
struct ContinuousBeamPath: View {
    let cells: [Cell]
    let gridSize: GridSize
    let cellSize: CGFloat
    let spacing: CGFloat
    let beamColor: Color
    let isActive: Bool

    private let beamWidth: CGFloat = 10

    var body: some View {
        Canvas { context, size in
            let fullPath = buildFullPath()

            // Draw the beam with a glowing effect
            if isActive {
                // Outer glow - wide and soft
                context.stroke(
                    fullPath,
                    with: .color(beamColor.opacity(0.4)),
                    style: StrokeStyle(lineWidth: beamWidth * 2.5, lineCap: .round, lineJoin: .round)
                )
                
                // Inner "hotter" glow
                context.stroke(
                    fullPath,
                    with: .color(Color.white.opacity(0.8)),
                    style: StrokeStyle(lineWidth: beamWidth * 1.5, lineCap: .round, lineJoin: .round)
                )
            }

            // Main beam
            context.stroke(
                fullPath,
                with: .color(isActive ? beamColor : beamColor.opacity(0.5)),
                style: StrokeStyle(lineWidth: beamWidth, lineCap: .round, lineJoin: .round)
            )

            // Draw start and end markers
            for cell in cells {
                let pos = cellPosition(for: cell)
                if cell.type == .start {
                    drawStartMarker(context: context, at: pos, color: beamColor)
                } else if cell.type == .end {
                    drawEndMarker(context: context, at: pos, color: beamColor)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func buildFullPath() -> Path {
        var path = Path()
        guard let startCell = cells.first(where: { $0.type == .start }) else {
            return path
        }

        var currentCell: Cell? = startCell
        path.move(to: cellPosition(for: startCell))

        while let cell = currentCell, cell.type != .end {
            currentCell = getNextCell(from: cell)
            if let next = currentCell {
                path.addLine(to: cellPosition(for: next))
            }
        }
        return path
    }

    private func cellPosition(for cell: Cell) -> CGPoint {
        let x = CGFloat(cell.column) * (cellSize + spacing) + cellSize / 2
        let y = CGFloat(cell.row) * (cellSize + spacing) + cellSize / 2
        return CGPoint(x: x, y: y)
    }

    private func getNextCell(from cell: Cell) -> Cell? {
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

    private func drawStartMarker(context: GraphicsContext, at position: CGPoint, color: Color) {
        let radius: CGFloat = 14
        let circle = Path(ellipseIn: CGRect(x: position.x - radius, y: position.y - radius, width: radius * 2, height: radius * 2))

        let gradient = Gradient(colors: [color, color.opacity(0)])
        context.fill(circle, with: .radialGradient(gradient, center: position, startRadius: radius * 0.3, endRadius: radius))

        let coreRadius = radius * 0.4
        let coreCircle = Path(ellipseIn: CGRect(x: position.x - coreRadius, y: position.y - coreRadius, width: coreRadius * 2, height: coreRadius * 2))
        context.fill(coreCircle, with: .color(Color.white.opacity(0.9)))
    }

    private func drawEndMarker(context: GraphicsContext, at position: CGPoint, color: Color) {
        let size: CGFloat = 24
        let rect = CGRect(x: position.x - size / 2, y: position.y - size / 2, width: size, height: size)
        let shape = Path(roundedRect: rect, cornerRadius: 6)

        let gradient = Gradient(colors: [color, color.opacity(0)])
        context.fill(shape, with: .radialGradient(gradient, center: position, startRadius: size * 0.3, endRadius: size * 0.7))
        
        let coreSize = size * 0.4
        let coreRect = CGRect(x: position.x - coreSize / 2, y: position.y - coreSize / 2, width: coreSize, height: coreSize)
        let coreShape = Path(roundedRect: coreRect, cornerRadius: 3)
        context.fill(coreShape, with: .color(Color.white.opacity(0.9)))
    }
}

// MARK: - Preview
#Preview {
    let testCells = [
        Cell(row: 0, column: 0, type: .start, direction: .right, color: "blue"),
        Cell(row: 0, column: 1, type: .path, direction: .down, color: "blue"),
        Cell(row: 1, column: 1, type: .path, direction: .right, color: "blue"),
        Cell(row: 1, column: 2, type: .end, direction: .none, color: "blue")
    ]

    return ContinuousBeamPath(
        cells: testCells,
        gridSize: GridSize(rows: 3, columns: 3),
        cellSize: 60,
        spacing: 20,
        beamColor: Color(red: 0.66, green: 0.85, blue: 0.92),
        isActive: true
    )
    .frame(width: 300, height: 300)
    .background(Color.black)
}
