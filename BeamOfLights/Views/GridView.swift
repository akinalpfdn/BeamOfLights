//
//  GridView.swift
//  BeamOfLights
//
//  Updated: Gestures for Zoom & Pan
//

import SwiftUI
import SpriteKit

struct GridView: View {
    @ObservedObject var viewModel: GameViewModel
    
    // Zoom/Pan State
    @State private var currentZoom: CGFloat = 1.0
    @State private var finalZoom: CGFloat = 1.0
    @State private var currentPan: CGSize = .zero
    
    // Create scene lazily
    @State private var scene: GameScene = {
        let scene = GameScene()
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        ZStack {
            // 1. Background
            Color(white:0.05).ignoresSafeArea()
            
            // 2. SpriteKit Layer with Gestures
            SpriteView(scene: scene, options: [.allowsTransparency])
                .background(Color.clear)
                .ignoresSafeArea()
                // GESTURES
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / currentZoom
                                // Smooth zoom multiplier
                                let newZoom = finalZoom * value
                                scene.setCameraZoom(newZoom)
                            }
                            .onEnded { value in
                                finalZoom *= value
                                currentZoom = 1.0
                            },
                        DragGesture()
                            .onChanged { value in
                                let delta = CGSize(
                                    width: value.translation.width - currentPan.width,
                                    height: value.translation.height - currentPan.height
                                )
                                scene.panCamera(delta: delta)
                                currentPan = value.translation
                            }
                            .onEnded { _ in
                                currentPan = .zero
                            }
                    )
                )
                .onAppear {
                    scene.gameViewModel = viewModel
                    if let level = viewModel.currentLevel {
                        scene.setupLevel(level: level, beams: viewModel.activeBeams)
                    }
                }
                .onChange(of: viewModel.currentLevel?.levelNumber) { _ in
                    if let level = viewModel.currentLevel {
                        scene.setupLevel(level: level, beams: viewModel.activeBeams)
                        // Reset zoom on level change
                        finalZoom = 1.0
                        currentZoom = 1.0
                    }
                }
            
            // 3. HUD Layer
            VStack {
                levelHeader
                    .padding(.top, 50)
                Spacer()
                gameStateOverlay
                    .padding(.bottom, 50)
            }
            .allowsHitTesting(false) // Let touches pass through HUD to Grid for panning
            
            // 4. Interactive Overlay for Win/Lose buttons
            if viewModel.gameState == .lost {
                 gameStateOverlay
                     .padding(.bottom, 50)
            }
            
            if viewModel.showLevelCompleteAnimation {
                LevelCompleteView()
            }
        }
    }
    
    // MARK: - HUD Components
    
    private var levelHeader: some View {
        Group {
            if let level = viewModel.currentLevel {
                HStack {
                    VStack(alignment: .leading) {
                        Text("LEVEL \(level.levelNumber)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .tracking(2)
                            .foregroundColor(.gray)
                        Text("Beam of Lights").font(.title2).fontWeight(.bold).foregroundColor(.white)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(0..<max(level.difficulty, 3), id: \.self) { index in
                            Image(systemName: index < viewModel.heartsRemaining ? "heart.fill" : "heart")
                                .foregroundColor(index < viewModel.heartsRemaining ? .pink : .gray.opacity(0.3))
                                .font(.system(size: 20))
                                .scaleEffect(index < viewModel.heartsRemaining ? 1 : 0.8)
                                .animation(.spring(), value: viewModel.heartsRemaining)
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(.ultraThinMaterial).cornerRadius(20)
                }
                .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder
    private var gameStateOverlay: some View {
        if viewModel.gameState == .lost {
            VStack(spacing: 20) {
                Image(systemName: "heart.slash.fill")
                    .font(.system(size: 50)).foregroundColor(.pink).symbolEffect(.bounce)
                Text("Out of Moves").font(.title3).fontWeight(.bold).foregroundColor(.black)
                Button {
                    viewModel.loadLevel(at: viewModel.currentLevelIndex)
                } label: {
                    Text("Try Again").font(.headline)
                        .padding(.horizontal, 30).padding(.vertical, 12)
                        .background(Color.pink).foregroundColor(.white).cornerRadius(25)
                }
            }
            .padding(30).background(.white.opacity(0.9)).cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// Ensure LevelCompleteView and SparkleView are present here as well (from previous snippet)
// MARK: - Level Complete Animation Views

struct LevelCompleteView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Dark background for the overlay
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack {
                Text("Level Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white) // White text for dark mode
                    .shadow(color: .purple, radius: 10) // Neon glow
                    .scaleEffect(animate ? 1 : 0.5)
                    .opacity(animate ? 1 : 0)
                
                ZStack {
                    ForEach(0..<15) { i in
                        SparkleView(animate: $animate, index: i)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.4)) {
                animate = true
            }
        }
    }
}

struct SparkleView: View {
    @Binding var animate: Bool
    let index: Int
    
    private let randomX = Double.random(in: -150...150)
    private let randomY = Double.random(in: -150...150)
    private let randomScale = Double.random(in: 0.5...1.5)
    private let randomDelay = Double.random(in: 0...0.3)
    private let randomDuration = Double.random(in: 0.4...0.8)

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 20))
            // Updated colors to match the neon palette
            .foregroundColor([.cyan, .purple, .pink, .yellow].randomElement()!)
            .scaleEffect(animate ? randomScale : 0)
            .offset(x: animate ? randomX : 0, y: animate ? randomY : 0)
            .opacity(animate ? 0 : 1)
            .animation(
                .easeOut(duration: randomDuration).delay(randomDelay),
                value: animate
            )
    }
}
