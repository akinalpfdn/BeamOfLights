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

            // Main beam rendering with gradient
            Canvas { context, size in
                // Main beam with gradient effect - PALE at start, LIVELY at end
                let gradient = Gradient(stops: [
                    .init(color: beamColor.opacity(0.2), location: 0.0),   // Pale at start
                    .init(color: beamColor.opacity(0.4), location: 0.3),   // Getting brighter
                    .init(color: beamColor.opacity(0.7), location: 0.6),   // Quite bright
                    .init(color: beamColor.opacity(0.9), location: 0.8),   // Very bright
                    .init(color: Color.white.opacity(0.8), location: 0.9), // White flash near end
                    .init(color: beamColor.opacity(1.0), location: 1.0)    // Lively at end
                ])

                context.stroke(
                    fullPath,
                    with: .linearGradient(gradient, startPoint: pathStartPoint, endPoint: pathEndPoint),
                    style: StrokeStyle(lineWidth: beamWidth, lineCap: .round, lineJoin: .round)
                )

                // Bright core for active beams
                if isActive {
                    let coreGradient = Gradient(stops: [
                        .init(color: beamColor.opacity(0.3), location: 0.0),     // Pale core at start
                        .init(color: beamColor.opacity(0.6), location: 0.5),     // Mid brightness
                        .init(color: Color.white.opacity(0.9), location: 0.8),   // Bright white near end
                        .init(color: Color.white.opacity(1.0), location: 1.0)    // Lively at end
                    ])

                    context.stroke(
                        fullPath,
                        with: .linearGradient(coreGradient, startPoint: pathStartPoint, endPoint: pathEndPoint),
                        style: StrokeStyle(lineWidth: beamWidth * 0.3, lineCap: .round, lineJoin: .round)
                    )
                }

                // Animated energy flow
                if isActive {
                    context.stroke(
                        fullPath,
                        with: .color(Color.white.opacity(0.6 + sparklePhase * 0.2)),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [20, 30], dashPhase: dashPhase)
                    )
                }

                // Enhanced start and end markers
                for cell in cells {
                    let pos = cellPosition(for: cell)
                    if cell.type == .start {
                        drawEnhancedStartMarker(context: context, at: pos, color: beamColor, pulse: pulsePhase, glow: glowPhase)
                    } else if cell.type == .end {
                        drawEnhancedEndMarker(context: context, at: pos, color: beamColor, pulse: pulsePhase, glow: glowPhase)
                    }
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

    // Enhanced start marker with multi-layered effects
    private func drawEnhancedStartMarker(context: GraphicsContext, at position: CGPoint, color: Color, pulse: CGFloat, glow: CGFloat) {
        let baseRadius: CGFloat = 18
        let radius = isActive ? baseRadius * (1.0 + pulse * 0.15) : baseRadius

        if isActive {
            // Outermost glow ring
            let outerGlowRadius = radius * (2.0 + glow * 0.5)
            let outerGlow = Path(ellipseIn: CGRect(x: position.x - outerGlowRadius, y: position.y - outerGlowRadius, width: outerGlowRadius * 2, height: outerGlowRadius * 2))
            let outerGlowGradient = Gradient(colors: [color.opacity(0.1), color.opacity(0), color.opacity(0)])
            context.fill(outerGlow, with: .radialGradient(outerGlowGradient, center: position, startRadius: outerGlowRadius * 0.3, endRadius: outerGlowRadius))

            // Middle glow ring
            let middleGlowRadius = radius * (1.5 + pulse * 0.2)
            let middleGlow = Path(ellipseIn: CGRect(x: position.x - middleGlowRadius, y: position.y - middleGlowRadius, width: middleGlowRadius * 2, height: middleGlowRadius * 2))
            let middleGlowGradient = Gradient(colors: [color.opacity(0.3), color.opacity(0.1), color.opacity(0)])
            context.fill(middleGlow, with: .radialGradient(middleGlowGradient, center: position, startRadius: middleGlowRadius * 0.4, endRadius: middleGlowRadius))
        }

        // Main glowing circle
        let mainCircle = Path(ellipseIn: CGRect(x: position.x - radius, y: position.y - radius, width: radius * 2, height: radius * 2))
        let mainGradient = Gradient(stops: [
            .init(color: color.opacity(0.9), location: 0.0),
            .init(color: color.opacity(0.7), location: 0.6),
            .init(color: color.opacity(0.3), location: 0.9),
            .init(color: color.opacity(0), location: 1.0)
        ])
        context.fill(mainCircle, with: .radialGradient(mainGradient, center: position, startRadius: 0, endRadius: radius))

        // Inner bright core
        let coreRadius = radius * 0.4
        let coreCircle = Path(ellipseIn: CGRect(x: position.x - coreRadius, y: position.y - coreRadius, width: coreRadius * 2, height: coreRadius * 2))
        let coreGradient = Gradient(stops: [
            .init(color: Color.white.opacity(0.95), location: 0.0),
            .init(color: color.opacity(0.8), location: 0.7),
            .init(color: color.opacity(0.4), location: 1.0)
        ])
        context.fill(coreCircle, with: .radialGradient(coreGradient, center: position, startRadius: 0, endRadius: coreRadius))

        // Sparkle effect for active beams
        if isActive {
            let sparkleRadius = coreRadius * 0.3
            let sparkleOpacity = 0.6 + sparklePhase * 0.4
            let sparkle = Path(ellipseIn: CGRect(x: position.x - sparkleRadius, y: position.y - sparkleRadius, width: sparkleRadius * 2, height: sparkleRadius * 2))
            context.fill(sparkle, with: .color(Color.white.opacity(sparkleOpacity)))
        }
    }

    // Enhanced end marker with sophisticated effects
    private func drawEnhancedEndMarker(context: GraphicsContext, at position: CGPoint, color: Color, pulse: CGFloat, glow: CGFloat) {
        let baseSize: CGFloat = 28
        let size = isActive ? baseSize * (1.0 + pulse * 0.15) : baseSize

        if isActive {
            // Outer glow area
            let outerGlowSize = size * (2.2 + glow * 0.4)
            let outerGlowRect = CGRect(x: position.x - outerGlowSize / 2, y: position.y - outerGlowSize / 2, width: outerGlowSize, height: outerGlowSize)
            let outerGlow = Path(roundedRect: outerGlowRect, cornerRadius: outerGlowSize * 0.3)
            let outerGlowGradient = Gradient(colors: [color.opacity(0.15), color.opacity(0.05), color.opacity(0)])
            context.fill(outerGlow, with: .radialGradient(outerGlowGradient, center: position, startRadius: outerGlowSize * 0.2, endRadius: outerGlowSize / 2))

            // Middle glow area
            let middleGlowSize = size * (1.6 + pulse * 0.3)
            let middleGlowRect = CGRect(x: position.x - middleGlowSize / 2, y: position.y - middleGlowSize / 2, width: middleGlowSize, height: middleGlowSize)
            let middleGlow = Path(roundedRect: middleGlowRect, cornerRadius: middleGlowSize * 0.25)
            let middleGlowGradient = Gradient(colors: [color.opacity(0.4), color.opacity(0.15), color.opacity(0.05)])
            context.fill(middleGlow, with: .radialGradient(middleGlowGradient, center: position, startRadius: middleGlowSize * 0.3, endRadius: middleGlowSize / 2))
        }

        // Main rounded square
        let rect = CGRect(x: position.x - size / 2, y: position.y - size / 2, width: size, height: size)
        let shape = Path(roundedRect: rect, cornerRadius: size * 0.25)
        let mainGradient = Gradient(stops: [
            .init(color: color.opacity(0.9), location: 0.0),
            .init(color: color.opacity(0.7), location: 0.5),
            .init(color: color.opacity(0.4), location: 0.8),
            .init(color: color.opacity(0.2), location: 1.0)
        ])
        context.fill(shape, with: .radialGradient(mainGradient, center: position, startRadius: 0, endRadius: size / 2))

        // Inner bright core
        let coreSize = size * 0.45
        let coreRect = CGRect(x: position.x - coreSize / 2, y: position.y - coreSize / 2, width: coreSize, height: coreSize)
        let coreShape = Path(roundedRect: coreRect, cornerRadius: coreSize * 0.2)
        let coreGradient = Gradient(stops: [
            .init(color: Color.white.opacity(0.95), location: 0.0),
            .init(color: color.opacity(0.85), location: 0.6),
            .init(color: color.opacity(0.5), location: 1.0)
        ])
        context.fill(coreShape, with: .radialGradient(coreGradient, center: position, startRadius: 0, endRadius: coreSize / 2))

        // Pulsing center dot for active beams
        if isActive {
            let centerRadius = coreSize * 0.25
            let centerOpacity = 0.7 + sparklePhase * 0.3
            let centerDot = Path(ellipseIn: CGRect(x: position.x - centerRadius, y: position.y - centerRadius, width: centerRadius * 2, height: centerRadius * 2))
            context.fill(centerDot, with: .color(Color.white.opacity(centerOpacity)))
        }
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
