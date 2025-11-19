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

            // Main game area - centered both vertically and horizontally
            if let level = viewModel.currentLevel {
                GeometryReader { geometry in
                    let gridWidth = calculateGridWidth(for: level, cellSize: cellSize, spacing: spacing)
                    let gridHeight = calculateGridHeight(for: level, cellSize: cellSize, spacing: spacing)
                    let gridOriginX = (geometry.size.width - gridWidth) / 2
                    let gridOriginY = (geometry.size.height - gridHeight) / 2

                    ZStack {
                        // Background dots grid (subtle)
                        backgroundDotsGrid(level: level, cellSize: cellSize, spacing: spacing)

                        // Render each active beam independently
                        ForEach(viewModel.activeBeams) { beam in
                            ContinuousBeamPath(
                                cells: beam.cells,
                                gridSize: level.gridSize,
                                cellSize: cellSize,
                                spacing: spacing,
                                beamColor: getBeamColor(for: beam.color),
                                isActive: true
                            )
                            .offset(viewModel.bounceOffset[beam.id] ?? .zero)
                        }

                        // Wrong move flash overlay
                        if viewModel.wrongMoveTrigger {
                            Rectangle()
                                .fill(Color.red.opacity(0.3))
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: viewModel.wrongMoveTrigger)
                        }
                    }
                    .frame(width: gridWidth, height: gridHeight)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .shake(trigger: viewModel.wrongMoveTrigger)
                    .onTapGesture { location in
                        print("👆 Tap detected at location: \(location)")
                        // Convert tap coordinates to grid-relative coordinates
                        let gridLocation = CGPoint(
                            x: location.x - gridOriginX,
                            y: location.y - gridOriginY
                        )
                        print("👆 Grid origin: (\(gridOriginX), \(gridOriginY)), Grid location: \(gridLocation)")
                        handleTap(at: gridLocation, cellSize: cellSize, spacing: spacing)
                    }
                }
            } else {
                Text("Loading level...")
                    .foregroundColor(.gray)
            }

            Spacer() // Push content to center

            // Game state overlays
            gameStateOverlay
        }
        .frame(maxHeight: .infinity) // Ensure VStack takes full height
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

                    // Hearts with animation
                    HStack(spacing: 8) {
                        ForEach(0..<level.difficulty, id: \.self) { index in
                            HeartView(
                                isFilled: index < viewModel.heartsRemaining,
                                heartLostTrigger: viewModel.heartLostTrigger,
                                isJustLost: index == viewModel.heartsRemaining
                            )
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

                    context.fill(dotPath, with: .color(Color.black.opacity(0.3)))
                }
            }
        }
        .frame(height: calculateGridHeight(for: level, cellSize: cellSize, spacing: spacing))
    }

    @ViewBuilder
    private var gameStateOverlay: some View {
        if self.viewModel.gameState == .won {
            VStack(spacing: 20) {
                // Success icon with animation
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }
                .scaleEffect(self.viewModel.levelCompleteTrigger ? 1.0 : 0.5)
                .animation(.spring(duration: 0.6, bounce: 0.4), value: self.viewModel.levelCompleteTrigger)

                Text("Level Complete!")
                    .font(.title)
                    .fontWeight(.bold)

                Button {
                    self.viewModel.nextLevel()
                } label: {
                    HStack {
                        Text("Next Level")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .shadow(radius: 20)
            .transition(.scale.combined(with: .opacity))
        } else if self.viewModel.gameState == .lost {
            VStack(spacing: 20) {
                // Game over icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                }

                Text("Game Over")
                    .font(.title)
                    .fontWeight(.bold)

                Text("No hearts remaining")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button {
                    self.viewModel.resetLevel()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .shadow(radius: 20)
            .transition(.scale.combined(with: .opacity))
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

    private func calculateGridWidth(for level: Level, cellSize: CGFloat, spacing: CGFloat) -> CGFloat {
        let columns = CGFloat(level.gridSize.columns)
        return columns * cellSize + (columns - 1) * spacing + 60
    }

    private func calculateGridHeight(for level: Level, cellSize: CGFloat, spacing: CGFloat) -> CGFloat {
        let rows = CGFloat(level.gridSize.rows)
        return rows * cellSize + (rows - 1) * spacing + 60
    }

    private func getBeamColor(for hexColor: String) -> Color {
        return Color(hex: hexColor) ?? .gray
    }

    // MARK: - Gesture Handling

    private func handleTap(at location: CGPoint, cellSize: CGFloat, spacing: CGFloat) {
        // Pass tap to view model to detect which beam was tapped
        viewModel.tapBeam(at: location, cellSize: cellSize, spacing: spacing)
    }
}

// MARK: - Preview
#Preview {
    GridView_New(viewModel: GameViewModel())
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
