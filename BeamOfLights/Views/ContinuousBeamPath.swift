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
                // Main beam with gradient - Pale at start, Bright at end
                let gradient = Gradient(stops: [
                    .init(color: beamColor.opacity(0.1), location: 0.0),   // Very pale at start
                    .init(color: beamColor.opacity(0.2), location: 0.15),   // Still pale
                    .init(color: beamColor.opacity(0.35), location: 0.3),   // Getting slightly brighter
                    .init(color: beamColor.opacity(0.55), location: 0.5),   // Moderately bright
                    .init(color: beamColor.opacity(0.75), location: 0.7),   // Quite bright
                    .init(color: beamColor.opacity(0.9), location: 0.85),   // Very bright
                    .init(color: Color.white.opacity(0.95), location: 1), // Almost white
                       // Brightest white at end
                ])

                context.stroke(
                    fullPath,
                    with: .linearGradient(gradient, startPoint: pathStartPoint, endPoint: pathEndPoint),
                    style: StrokeStyle(lineWidth: beamWidth, lineCap: .round, lineJoin: .round)
                )

                // No bright core line - removed as requested

                // No dashed energy flow line - removed as requested
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
        return cellPosition(for: startCell)
    }

    private var pathEndPoint: CGPoint {
        guard let endCell = cells.first(where: { $0.type == .end }) else {
            return CGPoint(x: 100, y: 100)
        }
        return cellPosition(for: endCell)
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
