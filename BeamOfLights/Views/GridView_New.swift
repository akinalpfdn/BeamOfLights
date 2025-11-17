//
//  GridView_New.swift
//  BeamOfLights
//
//  New continuous path-based grid rendering
//

import SwiftUI

struct GridView_New: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        GeometryReader { geometry in
            contentView(width: geometry.size.width)
        }
    }

    @ViewBuilder
    private func contentView(width: CGFloat) -> some View {
        let cellSize = calculateCellSize(screenWidth: width)
        let spacing = cellSize * 0.5

        VStack(spacing: 20) {
            // Level info header
            levelHeader

            // Main game area
            if let level = viewModel.currentLevel {
                ZStack {
                    // Background dots grid (subtle)
                    backgroundDotsGrid(level: level, cellSize: cellSize, spacing: spacing)

                    // Continuous beam paths
                    ContinuousBeamPath(
                        cells: level.cells,
                        gridSize: level.gridSize,
                        cellSize: cellSize,
                        spacing: spacing,
                        beamColor: getBeamColor(for: level.cells.first?.color ?? "blue"),
                        isActive: !viewModel.currentPath.isEmpty
                    )
                    .padding(30)

                    // User's current path overlay
                    if !viewModel.currentPath.isEmpty {
                        ContinuousBeamPath(
                            cells: viewModel.currentPath,
                            gridSize: level.gridSize,
                            cellSize: cellSize,
                            spacing: spacing,
                            beamColor: getBeamColor(for: viewModel.currentPath.first?.color ?? "blue"),
                            isActive: true
                        )
                        .padding(30)
                    }
                }
                .frame(height: calculateGridHeight(for: level, cellSize: cellSize, spacing: spacing))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleDrag(at: value.location, level: level, cellSize: cellSize, spacing: spacing)
                        }
                        .onEnded { _ in
                            handleDragEnd()
                        }
                )
            } else {
                Text("Loading level...")
                    .foregroundColor(.gray)
            }

            // Game state overlays
            gameStateOverlay
        }
    }

    // MARK: - Subviews

    private var levelHeader: some View {
        Group {
            if let level = viewModel.currentLevel {
                HStack {
                    Text("Level \(level.levelNumber)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    // Hearts
                    HStack(spacing: 4) {
                        ForEach(0..<level.difficulty, id: \.self) { index in
                            Image(systemName: index < viewModel.heartsRemaining ? "heart.fill" : "heart")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func backgroundDotsGrid(level: Level, cellSize: CGFloat, spacing: CGFloat) -> some View {
        Canvas { context, size in
            for row in 0..<level.gridSize.rows {
                for col in 0..<level.gridSize.columns {
                    let x = 30 + CGFloat(col) * (cellSize + spacing) + cellSize / 2
                    let y = CGFloat(row) * (cellSize + spacing) + cellSize / 2

                    let dotPath = Path(ellipseIn: CGRect(
                        x: x - 2,
                        y: y - 2,
                        width: 4,
                        height: 4
                    ))

                    context.fill(dotPath, with: .color(Color.gray.opacity(0.2)))
                }
            }
        }
        .frame(height: calculateGridHeight(for: level, cellSize: cellSize, spacing: spacing))
    }

    @ViewBuilder
    private var gameStateOverlay: some View {
        if viewModel.gameState == .won {
            VStack(spacing: 16) {
                Text("🎉 Level Complete!")
                    .font(.title)
                    .fontWeight(.bold)

                Button("Next Level") {
                    viewModel.nextLevel()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        } else if viewModel.gameState == .lost {
            VStack(spacing: 16) {
                Text("💔 Game Over")
                    .font(.title)
                    .fontWeight(.bold)

                Button("Try Again") {
                    viewModel.resetLevel()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
    }

    // MARK: - Helper Methods

    private func calculateCellSize(screenWidth: CGFloat) -> CGFloat {
        let padding: CGFloat = 60
        let spacingMultiplier: CGFloat = 0.5

        guard let level = viewModel.currentLevel else { return 60 }

        let columns = CGFloat(level.gridSize.columns)
        let availableWidth = screenWidth - padding

        let calculatedSize = availableWidth / (columns + (columns - 1) * spacingMultiplier)
        return min(calculatedSize, 70)
    }

    private func calculateGridHeight(for level: Level, cellSize: CGFloat, spacing: CGFloat) -> CGFloat {
        let rows = CGFloat(level.gridSize.rows)
        return rows * cellSize + (rows - 1) * spacing + 60
    }

    private func getBeamColor(for colorName: String) -> Color {
        switch colorName.lowercased() {
        case "blue":
            return Color(red: 0.66, green: 0.85, blue: 0.92)
        case "pink", "red":
            return Color(red: 1.0, green: 0.71, blue: 0.76)
        case "purple":
            return Color(red: 0.83, green: 0.71, blue: 0.94)
        case "green":
            return Color(red: 0.71, green: 0.91, blue: 0.81)
        case "orange", "yellow":
            return Color(red: 1.0, green: 0.83, blue: 0.64)
        default:
            return Color.gray
        }
    }

    // MARK: - Gesture Handling

    private func handleDrag(at location: CGPoint, level: Level, cellSize: CGFloat, spacing: CGFloat) {
        let adjustedLocation = CGPoint(
            x: location.x - 30,
            y: location.y
        )

        let col = Int((adjustedLocation.x - cellSize / 2) / (cellSize + spacing))
        let row = Int((adjustedLocation.y - cellSize / 2) / (cellSize + spacing))

        if let cell = level.cell(at: row, column: col) {
            viewModel.selectCell(cell)
        }
    }

    private func handleDragEnd() {
        print("Drag ended - current path has \(viewModel.currentPath.count) cells")
    }
}

// MARK: - Preview
#Preview {
    GridView_New(viewModel: GameViewModel())
}
