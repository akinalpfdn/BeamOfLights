//
//  BeamShape.swift
//  BeamOfLights
//
//  Custom Shape for drawing light beams in specified direction
//

import SwiftUI

struct BeamShape: Shape {
    let direction: Direction

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let beamWidth: CGFloat = rect.width * 0.18
        let beamLength: CGFloat = rect.width * 0.65

        switch direction {
        case .right:
            let startTop = CGPoint(x: center.x, y: center.y - beamWidth / 2)
            let startBottom = CGPoint(x: center.x, y: center.y + beamWidth / 2)
            let endTop = CGPoint(x: center.x + beamLength, y: center.y - beamWidth / 3)
            let endBottom = CGPoint(x: center.x + beamLength, y: center.y + beamWidth / 3)
            path.move(to: startTop)
            path.addLine(to: endTop)
            path.addQuadCurve(to: endBottom, control: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: startBottom)
            path.closeSubpath()
        case .left:
            let startTop = CGPoint(x: center.x, y: center.y - beamWidth / 2)
            let startBottom = CGPoint(x: center.x, y: center.y + beamWidth / 2)
            let endTop = CGPoint(x: center.x - beamLength, y: center.y - beamWidth / 3)
            let endBottom = CGPoint(x: center.x - beamLength, y: center.y + beamWidth / 3)
            path.move(to: startTop)
            path.addLine(to: endTop)
            path.addQuadCurve(to: endBottom, control: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: startBottom)
            path.closeSubpath()
        case .down:
            let startLeft = CGPoint(x: center.x - beamWidth / 2, y: center.y)
            let startRight = CGPoint(x: center.x + beamWidth / 2, y: center.y)
            let endLeft = CGPoint(x: center.x - beamWidth / 3, y: center.y + beamLength)
            let endRight = CGPoint(x: center.x + beamWidth / 3, y: center.y + beamLength)
            path.move(to: startLeft)
            path.addLine(to: endLeft)
            path.addQuadCurve(to: endRight, control: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: startRight)
            path.closeSubpath()
        case .up:
            let startLeft = CGPoint(x: center.x - beamWidth / 2, y: center.y)
            let startRight = CGPoint(x: center.x + beamWidth / 2, y: center.y)
            let endLeft = CGPoint(x: center.x - beamWidth / 3, y: center.y - beamLength)
            let endRight = CGPoint(x: center.x + beamWidth / 3, y: center.y - beamLength)
            path.move(to: startLeft)
            path.addLine(to: endLeft)
            path.addQuadCurve(to: endRight, control: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: startRight)
            path.closeSubpath()
        case .none:
            break
        }

        return path
    }
}

// MARK: - Beam View with Gradient
struct BeamView: View {
    let direction: Direction
    let color: Color
    let isActive: Bool
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main beam shape with a gradient that is brighter at the tip
                BeamShape(direction: direction)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: gradientStartPoint,
                            endPoint: gradientEndPoint
                        )
                    )
                
                // Glow effect
                if isActive {
                    // Outer, soft glow
                    BeamShape(direction: direction)
                        .fill(color)
                        .blur(radius: 15 + phase * 5) // Pulsing blur
                        .opacity(0.5)

                    // Inner, bright core, also pulsing
                    BeamShape(direction: direction)
                        .fill(Color.white)
                        .blur(radius: 5 + phase * 2)
                        .opacity(0.8)
                }
            }
            .scaleEffect(isActive ? 1.0 + phase * 0.05 : 1.0) // Subtle breathing effect
            .shadow(color: color.opacity(isActive ? 0.4 : 0.1), radius: 10, x: 0, y: 4)
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        phase = 1.0
                    }
                }
            }
        }
    }

    // MARK: - Gradient Configuration

    private var gradientColors: [Color] {
        if isActive {
            // Pale at start, bright at tip
            return [color.opacity(0.2), color, Color.white.opacity(0.8)]
        } else {
            return [color.opacity(0.7), color.opacity(0.1)]
        }
    }

    private var gradientStartPoint: UnitPoint {
        switch direction {
        case .right: return .leading
        case .left: return .trailing
        case .down: return .top
        case .up: return .bottom
        case .none: return .center
        }
    }

    private var gradientEndPoint: UnitPoint {
        switch direction {
        case .right: return .trailing
        case .left: return .leading
        case .down: return .bottom
        case .up: return .top
        case .none: return .center
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 30) {
        HStack(spacing: 20) {
            BeamView(
                direction: .right,
                color: Color(red: 0.66, green: 0.85, blue: 0.92),
                isActive: false
            )
            .frame(width: 80, height: 80)

            BeamView(
                direction: .down,
                color: Color(red: 1.0, green: 0.71, blue: 0.76),
                isActive: true
            )
            .frame(width: 80, height: 80)
        }

        HStack(spacing: 20) {
            BeamView(
                direction: .left,
                color: Color(red: 0.83, green: 0.71, blue: 0.94),
                isActive: false
            )
            .frame(width: 80, height: 80)

            BeamView(
                direction: .up,
                color: Color(red: 0.71, green: 0.91, blue: 0.81),
                isActive: true
            )
            .frame(width: 80, height: 80)
        }
    }
    .padding()
    .background(Color.white)
}
