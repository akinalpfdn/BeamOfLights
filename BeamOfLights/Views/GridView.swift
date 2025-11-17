//
//  GridView.swift
//  BeamOfLights
//
//  View for displaying the game grid
//

import SwiftUI

struct GridView: View {
    @ObservedObject var viewModel: GameViewModel

    // Calculate cell size based on screen size
    private var cellSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let padding: CGFloat = 40 // Total horizontal padding
        let spacing: CGFloat = 8 // Space between cells

        guard let level = viewModel.currentLevel else { return 60 }

        let columns = CGFloat(level.gridSize.columns)
        let totalSpacing = spacing * (columns - 1)
        let availableWidth = screenWidth - padding - totalSpacing

        return min(availableWidth / columns, 80) // Max 80pt per cell
    }

    private var gridColumns: [GridItem] {
        guard let level = viewModel.currentLevel else {
            return [GridItem(.flexible())]
        }

        return Array(
            repeating: GridItem(.fixed(cellSize), spacing: 8),
            count: level.gridSize.columns
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            // Level info
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
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Game Grid
            if let level = viewModel.currentLevel {
                LazyVGrid(columns: gridColumns, spacing: 8) {
                    ForEach(level.cells) { cell in
                        CellView(
                            cell: cell,
                            isInCurrentPath: viewModel.isInCurrentPath(cell),
                            cellSize: cellSize
                        )
                        .onTapGesture {
                            handleCellTap(cell)
                        }
                    }
                }
                .padding()
            } else {
                Text("Loading level...")
                    .foregroundColor(.gray)
            }

            // Game state overlay
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
    }

    // MARK: - Actions

    private func handleCellTap(_ cell: Cell) {
        viewModel.selectCell(cell)
        print("Tapped cell at (\(cell.row), \(cell.column)) - Type: \(cell.type)")
    }
}

// MARK: - Preview
#Preview {
    GridView(viewModel: GameViewModel())
}
