//
//  ContinuousBeamPath.swift
//  BeamOfLights
//
//  Renders continuous, connected light beam paths
//

import SwiftUI

// MARK: - Beam Segment Type
enum BeamSegmentType {
    case horizontal
    case vertical
    case cornerUpRight    // Coming from bottom, going right
    case cornerUpLeft     // Coming from bottom, going left
    case cornerDownRight  // Coming from top, going right
    case cornerDownLeft   // Coming from top, going left
    case cornerRightDown  // Coming from left, going down
    case cornerRightUp    // Coming from left, going up
    case cornerLeftDown   // Coming from right, going down
    case cornerLeftUp     // Coming from right, going up
}

// MARK: - Beam Segment Shape
struct BeamSegment: Shape {
    let startPoint: CGPoint
    let endPoint: CGPoint
    let segmentType: BeamSegmentType
    let beamWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        switch segmentType {
        case .horizontal, .vertical:
            // Straight beam
            drawStraightBeam(in: &path)

        case .cornerUpRight, .cornerUpLeft, .cornerDownRight, .cornerDownLeft,
             .cornerRightDown, .cornerRightUp, .cornerLeftDown, .cornerLeftUp:
            // Corner beam with smooth curve
            drawCornerBeam(in: &path)
        }

        return path
    }

    private func drawStraightBeam(in path: inout Path) {
        let isHorizontal = abs(endPoint.x - startPoint.x) > abs(endPoint.y - startPoint.y)

        if isHorizontal {
            // Horizontal beam
            let topLeft = CGPoint(x: startPoint.x, y: startPoint.y - beamWidth / 2)
            let topRight = CGPoint(x: endPoint.x, y: endPoint.y - beamWidth / 2)
            let bottomRight = CGPoint(x: endPoint.x, y: endPoint.y + beamWidth / 2)
            let bottomLeft = CGPoint(x: startPoint.x, y: startPoint.y + beamWidth / 2)

            path.move(to: topLeft)
            path.addLine(to: topRight)
            path.addLine(to: bottomRight)
            path.addLine(to: bottomLeft)
            path.closeSubpath()
        } else {
            // Vertical beam
            let topLeft = CGPoint(x: startPoint.x - beamWidth / 2, y: startPoint.y)
            let topRight = CGPoint(x: startPoint.x + beamWidth / 2, y: startPoint.y)
            let bottomRight = CGPoint(x: endPoint.x + beamWidth / 2, y: endPoint.y)
            let bottomLeft = CGPoint(x: endPoint.x - beamWidth / 2, y: endPoint.y)

            path.move(to: topLeft)
            path.addLine(to: topRight)
            path.addLine(to: bottomRight)
            path.addLine(to: bottomLeft)
            path.closeSubpath()
        }
    }

    private func drawCornerBeam(in path: inout Path) {
        // For corners, draw rounded connection
        let radius = beamWidth * 1.5

        path.move(to: startPoint)
        path.addLine(to: CGPoint(
            x: (startPoint.x + endPoint.x) / 2,
            y: (startPoint.y + endPoint.y) / 2
        ))
        path.addLine(to: endPoint)

        // This is simplified - in production, use proper arc calculations
    }
}

// MARK: - Continuous Beam Renderer
struct ContinuousBeamPath: View {
    let cells: [Cell]
    let gridSize: GridSize
    let cellSize: CGFloat
    let spacing: CGFloat
    let beamColor: Color
    let isActive: Bool

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Draw all beam segments
                for i in 0..<cells.count {
                    let currentCell = cells[i]

                    // Skip empty cells or cells without direction
                    if currentCell.type == .empty || currentCell.direction == .none {
                        continue
                    }

                    // Calculate current cell position
                    let currentPos = cellPosition(for: currentCell)

                    // Get next cell in the direction
                    if let nextCell = getNextCell(from: currentCell) {
                        let nextPos = cellPosition(for: nextCell)

                        // Draw beam segment between cells
                        drawBeamSegment(
                            context: context,
                            from: currentPos,
                            to: nextPos,
                            color: beamColor
                        )
                    }

                    // Draw dot at cell position (for path cells)
                    if currentCell.type == .path {
                        drawDot(context: context, at: currentPos, color: beamColor)
                    }
                }

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
    }

    // MARK: - Helper Methods

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

    private func drawBeamSegment(context: GraphicsContext, from: CGPoint, to: CGPoint, color: Color) {
        let beamWidth: CGFloat = 8

        var path = Path()
        path.move(to: from)
        path.addLine(to: to)

        context.stroke(
            path,
            with: .color(color.opacity(isActive ? 1.0 : 0.5)),
            lineWidth: beamWidth
        )

        // Add glow effect
        if isActive {
            context.stroke(
                path,
                with: .color(color.opacity(0.3)),
                style: StrokeStyle(lineWidth: beamWidth * 2, lineCap: .round)
            )
        }
    }

    private func drawDot(context: GraphicsContext, at position: CGPoint, color: Color) {
        let dotRadius: CGFloat = 4

        let dotPath = Path(ellipseIn: CGRect(
            x: position.x - dotRadius,
            y: position.y - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        ))

        context.fill(dotPath, with: .color(color.opacity(0.6)))
    }

    private func drawStartMarker(context: GraphicsContext, at position: CGPoint, color: Color) {
        let radius: CGFloat = 12

        let circlePath = Path(ellipseIn: CGRect(
            x: position.x - radius,
            y: position.y - radius,
            width: radius * 2,
            height: radius * 2
        ))

        // Outer glow
        context.fill(circlePath, with: .color(color.opacity(0.3)))

        // Main circle
        let innerRadius = radius * 0.7
        let innerCircle = Path(ellipseIn: CGRect(
            x: position.x - innerRadius,
            y: position.y - innerRadius,
            width: innerRadius * 2,
            height: innerRadius * 2
        ))

        context.fill(innerCircle, with: .color(color))
        context.stroke(innerCircle, with: .color(.white), lineWidth: 2)
    }

    private func drawEndMarker(context: GraphicsContext, at position: CGPoint, color: Color) {
        let size: CGFloat = 20

        let squarePath = Path(roundedRect: CGRect(
            x: position.x - size / 2,
            y: position.y - size / 2,
            width: size,
            height: size
        ), cornerRadius: 4)

        // Outer glow
        context.fill(squarePath, with: .color(color.opacity(0.3)))

        // Main square
        let innerSize = size * 0.7
        let innerSquare = Path(roundedRect: CGRect(
            x: position.x - innerSize / 2,
            y: position.y - innerSize / 2,
            width: innerSize,
            height: innerSize
        ), cornerRadius: 3)

        context.fill(innerSquare, with: .color(color))
        context.stroke(innerSquare, with: .color(.white), lineWidth: 2)
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
    .background(Color.white)
}
