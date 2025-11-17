//
//  HeartView.swift
//  BeamOfLights
//
//  Animated heart view for life system
//

import SwiftUI

struct HeartView: View {
    let isFilled: Bool
    let heartLostTrigger: Bool
    let isJustLost: Bool

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: isFilled ? "heart.fill" : "heart")
            .foregroundColor(isFilled ? .red : .gray.opacity(0.3))
            .font(.title3)
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .onChange(of: heartLostTrigger) { _, _ in
                if isJustLost {
                    playLostAnimation()
                }
            }
            .onAppear {
                if isFilled {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        scale = 1.1
                    }
                }
            }
    }

    private func playLostAnimation() {
        // Heart break animation
        withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
            scale = 1.5
            rotation = 15
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            opacity = 0
        }

        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            scale = 1.0
            opacity = 1.0
            rotation = 0
        }
    }
}

// MARK: - Preview
#Preview {
    HStack(spacing: 12) {
        HeartView(isFilled: true, heartLostTrigger: false, isJustLost: false)
        HeartView(isFilled: true, heartLostTrigger: false, isJustLost: false)
        HeartView(isFilled: false, heartLostTrigger: false, isJustLost: false)
    }
    .padding()
}
