//
//  ContinuousBeamPath.swift
//  BeamOfLights
//
//  Renders continuous, connected light beam paths
//

import SwiftUI

// MARK: - Continuous Beam Renderer
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
    @State private var dashPhase: CGFloat = 0
    @State private var pulsePhase: CGFloat = 0

    var body: some View {
        let fullPath = buildFullPath()

        ZStack {
            // Canvas for the blurred glow
            Canvas { context, size in
                if isActive {
                    let glowWidth = beamWidth * (2.0 + pulsePhase * 0.5)
                    context.addFilter(GraphicsContext.Filter.blur(radius: glowWidth / 3))
                    context.stroke(
                        fullPath,
                        with: .color(beamColor.opacity(0.5)),
                        style: StrokeStyle(lineWidth: glowWidth, lineCap: .round, lineJoin: .round)
                    )
                }
            }

            // Main canvas for sharp elements
            Canvas { context, size in
                // Main beam
                context.stroke(
                    fullPath,
                    with: .color(isActive ? beamColor : beamColor.opacity(0.5)),
                    style: StrokeStyle(lineWidth: beamWidth, lineCap: .round, lineJoin: .round)
                )
                
                // Brighter core
                if isActive {
                    context.stroke(
                        fullPath,
                        with: .color(Color.white.opacity(0.7)),
                        style: StrokeStyle(lineWidth: beamWidth * 0.4, lineCap: .round, lineJoin: .round)
                    )
                }
                
                // Animated dash on top for "flow"
                if isActive {
                    context.stroke(
                        fullPath,
                        with: .color(Color.white.opacity(0.7)),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [15, 25], dashPhase: dashPhase)
                    )
                }

                // Draw start and end markers
                for cell in cells {
                    let pos = cellPosition(for: cell)
                    if cell.type == .start {
                        drawStartMarker(context: context, at: pos, color: beamColor, pulse: pulsePhase)
                    } else if cell.type == .end {
                        drawEndMarker(context: context, at: pos, color: beamColor, pulse: pulsePhase)
                    }
                }
            }
        }
        .onAppear {
            if isActive {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    dashPhase = -40
                }
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    pulsePhase = 1.0
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

    private func drawStartMarker(context: GraphicsContext, at position: CGPoint, color: Color, pulse: CGFloat) {
        let baseRadius: CGFloat = 14
        let radius = isActive ? baseRadius * (1.0 + pulse * 0.1) : baseRadius
        let circle = Path(ellipseIn: CGRect(x: position.x - radius, y: position.y - radius, width: radius * 2, height: radius * 2))

        let gradient = Gradient(colors: [color.opacity(0.8), color.opacity(0)])
        context.fill(circle, with: .radialGradient(gradient, center: position, startRadius: radius * 0.5, endRadius: radius))

        let coreRadius = radius * 0.5
        let coreCircle = Path(ellipseIn: CGRect(x: position.x - coreRadius, y: position.y - coreRadius, width: coreRadius * 2, height: coreRadius * 2))
        context.fill(coreCircle, with: .color(Color.white.opacity(0.9)))
    }

    private func drawEndMarker(context: GraphicsContext, at position: CGPoint, color: Color, pulse: CGFloat) {
        let baseSize: CGFloat = 24
        let size = isActive ? baseSize * (1.0 + pulse * 0.1) : baseSize
        let rect = CGRect(x: position.x - size / 2, y: position.y - size / 2, width: size, height: size)
        let shape = Path(roundedRect: rect, cornerRadius: 6)

        let gradient = Gradient(colors: [color.opacity(0.8), color.opacity(0)])
        context.fill(shape, with: .radialGradient(gradient, center: position, startRadius: 0, endRadius: size / 2))
        
        let coreSize = size * 0.5
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
