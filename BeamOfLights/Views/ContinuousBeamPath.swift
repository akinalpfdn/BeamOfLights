//
//  ContinuousBeamPath.swift
//  BeamOfLights
//
//  Enhanced continuous, connected light beam paths with professional graphics
//

import SwiftUI

// MARK: - Enhanced Continuous Beam Renderer
struct ContinuousBeamPath: View {
    let cells: [Cell]
    let gridSize: GridSize
    let cellSize: CGFloat
    let spacing: CGFloat
    let beamColor: Color
    let isActive: Bool
    var slideOffset: CGFloat = 0  // Offset for sliding animation
    var slideDirection: Direction = .none  // Direction of sliding

    private let beamWidth: CGFloat = 12
    @State private var dashPhase: CGFloat = 0
    @State private var pulsePhase: CGFloat = 0
    @State private var glowPhase: CGFloat = 0
    @State private var sparklePhase: CGFloat = 0

    var body: some View {
        let fullPath = buildFullPath()

        ZStack {
            // Multiple glow layers for depth
            Canvas { context, size in
                if isActive {
                    // Outermost glow layer
                    let outerGlowWidth = beamWidth * (3.5 + glowPhase * 0.8)
                    context.addFilter(GraphicsContext.Filter.blur(radius: outerGlowWidth / 2))
                    context.stroke(
                        fullPath,
                        with: .color(beamColor.opacity(0.15)),
                        style: StrokeStyle(lineWidth: outerGlowWidth, lineCap: .round, lineJoin: .round)
                    )
                }
            }

            Canvas { context, size in
                if isActive {
                    // Middle glow layer
                    let middleGlowWidth = beamWidth * (2.5 + pulsePhase * 0.6)
                    context.addFilter(GraphicsContext.Filter.blur(radius: middleGlowWidth / 3))
                    context.stroke(
                        fullPath,
                        with: .color(beamColor.opacity(0.25)),
                        style: StrokeStyle(lineWidth: middleGlowWidth, lineCap: .round, lineJoin: .round)
                    )
                }
            }

            Canvas { context, size in
                if isActive {
                    // Inner glow layer
                    let innerGlowWidth = beamWidth * (1.8 + pulsePhase * 0.4)
                    context.addFilter(GraphicsContext.Filter.blur(radius: innerGlowWidth / 4))
                    context.stroke(
                        fullPath,
                        with: .color(beamColor.opacity(0.35)),
                        style: StrokeStyle(lineWidth: innerGlowWidth, lineCap: .round, lineJoin: .round)
                    )
                }
            }

            // Main beam rendering with gradient - COMET EFFECT: Bright tip → Fading tail
            Canvas { context, size in
                // Main beam with REVERSED gradient - Bright white at tip, fading to pale at tail
                let gradient = Gradient(stops: [
                    .init(color: beamColor.opacity(0.15), location: 0.0),   // Very pale at tail (start)
                    .init(color: beamColor.opacity(0.3), location: 0.2),    // Getting brighter
                    .init(color: beamColor.opacity(0.5), location: 0.4),    // Moderately bright
                    .init(color: beamColor.opacity(0.75), location: 0.6),   // Quite bright
                    .init(color: beamColor.opacity(0.9), location: 0.8),    // Very bright
                    .init(color: Color.white.opacity(0.95), location: 0.95), // White flash at tip
                    .init(color: Color.white.opacity(1.0), location: 1.0)   // Brightest white at tip (end)
                ])

                context.stroke(
                    fullPath,
                    with: .linearGradient(gradient, startPoint: pathStartPoint, endPoint: pathEndPoint),
                    style: StrokeStyle(lineWidth: beamWidth, lineCap: .round, lineJoin: .round)
                )

                // Bright core for active beams - also reversed
                if isActive {
                    let coreGradient = Gradient(stops: [
                        .init(color: beamColor.opacity(0.2), location: 0.0),      // Pale core at tail
                        .init(color: beamColor.opacity(0.5), location: 0.4),      // Getting brighter
                        .init(color: Color.white.opacity(0.7), location: 0.7),    // Bright white
                        .init(color: Color.white.opacity(1.0), location: 1.0)     // Brightest at tip
                    ])

                    context.stroke(
                        fullPath,
                        with: .linearGradient(coreGradient, startPoint: pathStartPoint, endPoint: pathEndPoint),
                        style: StrokeStyle(lineWidth: beamWidth * 0.3, lineCap: .round, lineJoin: .round)
                    )
                }

                // Animated energy flow - bright sparkles at tip
                if isActive {
                    context.stroke(
                        fullPath,
                        with: .color(Color.white.opacity(0.7 + sparklePhase * 0.3)),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [15, 25], dashPhase: dashPhase)
                    )
                }
            }
        }
        .onAppear {
            if isActive {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    dashPhase = -50
                }
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    pulsePhase = 1.0
                }
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    glowPhase = 1.0
                }
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    sparklePhase = 1.0
                }
            }
        }
    }

    // MARK: - Helper Methods

    // Calculate path gradient start and end points
    private var pathStartPoint: CGPoint {
        guard let startCell = cells.first(where: { $0.type == .start }) else {
            return CGPoint(x: 0, y: 0)
        }
        let startPos = cellPosition(for: startCell)
        guard let nextCell = getNextCell(from: startCell) else {
            return startPos
        }
        let nextPos = cellPosition(for: nextCell)

        // Create a point that extends beyond the start in the opposite direction of the first beam
        let dx = startPos.x - nextPos.x
        let dy = startPos.y - nextPos.y
        let length = sqrt(dx * dx + dy * dy)
        if length > 0 {
            return CGPoint(
                x: startPos.x + (dx / length) * 50,
                y: startPos.y + (dy / length) * 50
            )
        }
        return startPos
    }

    private var pathEndPoint: CGPoint {
        guard let endCell = cells.first(where: { $0.type == .end }) else {
            return CGPoint(x: 100, y: 100)
        }
        let endPos = cellPosition(for: endCell)

        // Find the cell that leads to the end
        var previousCell: Cell?
        for cell in cells {
            if let next = getNextCell(from: cell), next.row == endCell.row && next.column == endCell.column {
                previousCell = cell
                break
            }
        }

        if let prevCell = previousCell {
            let prevPos = cellPosition(for: prevCell)
            // Create a point that extends beyond the end in the direction of the final beam
            let dx = endPos.x - prevPos.x
            let dy = endPos.y - prevPos.y
            let length = sqrt(dx * dx + dy * dy)
            if length > 0 {
                return CGPoint(
                    x: endPos.x + (dx / length) * 50,
                    y: endPos.y + (dy / length) * 50
                )
            }
        }
        return endPos
    }

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
        var x = CGFloat(cell.column) * (cellSize + spacing) + cellSize / 2
        var y = CGFloat(cell.row) * (cellSize + spacing) + cellSize / 2

        // Apply slide offset based on direction
        switch slideDirection {
        case .up:
            y -= slideOffset
        case .down:
            y += slideOffset
        case .left:
            x -= slideOffset
        case .right:
            x += slideOffset
        case .none:
            break
        }

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
