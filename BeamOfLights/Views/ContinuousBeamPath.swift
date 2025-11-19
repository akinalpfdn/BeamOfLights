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
            // Glow layers
            Canvas { context, size in
                if isActive {
                    let outerGlowWidth = beamWidth * (3.5 + glowPhase * 0.8)
                    context.addFilter(GraphicsContext.Filter.blur(radius: outerGlowWidth / 2))
                    context.stroke(fullPath, with: .color(beamColor.opacity(0.15)), style: StrokeStyle(lineWidth: outerGlowWidth, lineCap: .round, lineJoin: .round))
                }
            }
            Canvas { context, size in
                if isActive {
                    let middleGlowWidth = beamWidth * (2.5 + pulsePhase * 0.6)
                    context.addFilter(GraphicsContext.Filter.blur(radius: middleGlowWidth / 3))
                    context.stroke(fullPath, with: .color(beamColor.opacity(0.25)), style: StrokeStyle(lineWidth: middleGlowWidth, lineCap: .round, lineJoin: .round))
                }
            }
            Canvas { context, size in
                if isActive {
                    let innerGlowWidth = beamWidth * (1.8 + pulsePhase * 0.4)
                    context.addFilter(GraphicsContext.Filter.blur(radius: innerGlowWidth / 4))
                    context.stroke(fullPath, with: .color(beamColor.opacity(0.35)), style: StrokeStyle(lineWidth: innerGlowWidth, lineCap: .round, lineJoin: .round))
                }
            }

            // Main beam rendering
            Canvas { context, size in
                let gradient = Gradient(stops: [
                    .init(color: beamColor.opacity(0.1), location: 0.0),
                    .init(color: beamColor.opacity(0.2), location: 0.15),
                    .init(color: beamColor.opacity(0.35), location: 0.3),
                    .init(color: beamColor.opacity(0.55), location: 0.5),
                    .init(color: beamColor.opacity(0.75), location: 0.7),
                    .init(color: beamColor.opacity(0.9), location: 0.85),
                    .init(color: Color.white.opacity(0.95), location: 1),
                ])
                context.stroke(fullPath, with: .linearGradient(gradient, startPoint: pathStartPoint, endPoint: pathEndPoint), style: StrokeStyle(lineWidth: beamWidth, lineCap: .round, lineJoin: .round))
            }
        }
        .onAppear {
            if isActive {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) { dashPhase = -50 }
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { pulsePhase = 1.0 }
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) { glowPhase = 1.0 }
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { sparklePhase = 1.0 }
            }
        }
    }

    // MARK: - Helper Methods

    private var pathStartPoint: CGPoint {
        guard let startCell = cells.first else { return .zero }
        return cellPosition(for: startCell)
    }

    private var pathEndPoint: CGPoint {
        guard let endCell = cells.last else { return .zero }
        return cellPosition(for: endCell)
    }

    private func buildFullPath() -> Path {
        var path = Path()
        guard !cells.isEmpty else { return path }
        
        path.move(to: cellPosition(for: cells[0]))
        
        for i in 1..<cells.count {
            path.addLine(to: cellPosition(for: cells[i]))
        }
        
        return path
    }

    private func cellPosition(for cell: Cell) -> CGPoint {
        let x = 30 + CGFloat(cell.column) * (cellSize + spacing) + cellSize / 2
        let y = CGFloat(cell.row) * (cellSize + spacing) + cellSize / 2
        return CGPoint(x: x, y: y)
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
