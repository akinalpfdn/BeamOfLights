//
//  BeamShape.swift
//  BeamOfLights
//
//  Enhanced custom Shape for drawing professional light beams in specified direction
//

import SwiftUI

struct BeamShape: Shape {
    let direction: Direction

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let beamWidth: CGFloat = rect.width * 0.22  // Slightly wider for more presence
        let beamLength: CGFloat = rect.width * 0.7  // Slightly longer for better flow

        switch direction {
        case .right:
            // More elegant tapered beam shape
            let startTop = CGPoint(x: center.x - beamWidth * 0.2, y: center.y - beamWidth / 2)
            let startBottom = CGPoint(x: center.x - beamWidth * 0.2, y: center.y + beamWidth / 2)
            let midTop = CGPoint(x: center.x + beamLength * 0.6, y: center.y - beamWidth * 0.35)
            let midBottom = CGPoint(x: center.x + beamLength * 0.6, y: center.y + beamWidth * 0.35)
            let endTop = CGPoint(x: center.x + beamLength, y: center.y - beamWidth * 0.15)
            let endBottom = CGPoint(x: center.x + beamLength, y: center.y + beamWidth * 0.15)

            path.move(to: startTop)
            path.addLine(to: midTop)
            path.addLine(to: endTop)
            path.addQuadCurve(to: endBottom, control: CGPoint(x: rect.maxX + beamWidth * 0.1, y: rect.midY))
            path.addLine(to: midBottom)
            path.addLine(to: startBottom)
            path.addQuadCurve(to: startTop, control: CGPoint(x: center.x - beamWidth * 0.3, y: rect.midY))
            path.closeSubpath()

        case .left:
            let startTop = CGPoint(x: center.x + beamWidth * 0.2, y: center.y - beamWidth / 2)
            let startBottom = CGPoint(x: center.x + beamWidth * 0.2, y: center.y + beamWidth / 2)
            let midTop = CGPoint(x: center.x - beamLength * 0.6, y: center.y - beamWidth * 0.35)
            let midBottom = CGPoint(x: center.x - beamLength * 0.6, y: center.y + beamWidth * 0.35)
            let endTop = CGPoint(x: center.x - beamLength, y: center.y - beamWidth * 0.15)
            let endBottom = CGPoint(x: center.x - beamLength, y: center.y + beamWidth * 0.15)

            path.move(to: startTop)
            path.addLine(to: midTop)
            path.addLine(to: endTop)
            path.addQuadCurve(to: endBottom, control: CGPoint(x: rect.minX - beamWidth * 0.1, y: rect.midY))
            path.addLine(to: midBottom)
            path.addLine(to: startBottom)
            path.addQuadCurve(to: startTop, control: CGPoint(x: center.x + beamWidth * 0.3, y: rect.midY))
            path.closeSubpath()

        case .down:
            let startLeft = CGPoint(x: center.x - beamWidth / 2, y: center.y - beamWidth * 0.2)
            let startRight = CGPoint(x: center.x + beamWidth / 2, y: center.y - beamWidth * 0.2)
            let midLeft = CGPoint(x: center.x - beamWidth * 0.35, y: center.y + beamLength * 0.6)
            let midRight = CGPoint(x: center.x + beamWidth * 0.35, y: center.y + beamLength * 0.6)
            let endLeft = CGPoint(x: center.x - beamWidth * 0.15, y: center.y + beamLength)
            let endRight = CGPoint(x: center.x + beamWidth * 0.15, y: center.y + beamLength)

            path.move(to: startLeft)
            path.addLine(to: midLeft)
            path.addLine(to: endLeft)
            path.addQuadCurve(to: endRight, control: CGPoint(x: rect.midX, y: rect.maxY + beamWidth * 0.1))
            path.addLine(to: midRight)
            path.addLine(to: startRight)
            path.addQuadCurve(to: startLeft, control: CGPoint(x: rect.midX, y: center.y - beamWidth * 0.3))
            path.closeSubpath()

        case .up:
            let startLeft = CGPoint(x: center.x - beamWidth / 2, y: center.y + beamWidth * 0.2)
            let startRight = CGPoint(x: center.x + beamWidth / 2, y: center.y + beamWidth * 0.2)
            let midLeft = CGPoint(x: center.x - beamWidth * 0.35, y: center.y - beamLength * 0.6)
            let midRight = CGPoint(x: center.x + beamWidth * 0.35, y: center.y - beamLength * 0.6)
            let endLeft = CGPoint(x: center.x - beamWidth * 0.15, y: center.y - beamLength)
            let endRight = CGPoint(x: center.x + beamWidth * 0.15, y: center.y - beamLength)

            path.move(to: startLeft)
            path.addLine(to: midLeft)
            path.addLine(to: endLeft)
            path.addQuadCurve(to: endRight, control: CGPoint(x: rect.midX, y: rect.minY - beamWidth * 0.1))
            path.addLine(to: midRight)
            path.addLine(to: startRight)
            path.addQuadCurve(to: startLeft, control: CGPoint(x: rect.midX, y: center.y + beamWidth * 0.3))
            path.closeSubpath()

        case .none:
            break
        }

        return path
    }
}

// MARK: - Enhanced Beam View with Professional Effects
struct BeamView: View {
    let direction: Direction
    let color: Color
    let isActive: Bool
    @State private var pulsePhase: CGFloat = 0
    @State private var glowPhase: CGFloat = 0
    @State private var sparklePhase: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Multi-layered glow effects
                if isActive {
                    // Outermost glow layer
                    BeamShape(direction: direction)
                        .fill(
                            RadialGradient(
                                colors: [color.opacity(0.1), color.opacity(0.05), Color.clear],
                                center: gradientCenter,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.6
                            )
                        )
                        .blur(radius: 20 + glowPhase * 8)
                        .opacity(0.7)

                    // Middle glow layer
                    BeamShape(direction: direction)
                        .fill(
                            RadialGradient(
                                colors: [color.opacity(0.3), color.opacity(0.15), color.opacity(0.05)],
                                center: gradientCenter,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.4
                            )
                        )
                        .blur(radius: 12 + pulsePhase * 4)
                        .opacity(0.8)

                    // Inner glow layer
                    BeamShape(direction: direction)
                        .fill(color.opacity(0.4))
                        .blur(radius: 6 + pulsePhase * 2)
                        .opacity(0.9)
                }

                // Main beam with sophisticated gradient
                BeamShape(direction: direction)
                    .fill(
                        LinearGradient(
                            colors: mainGradientColors,
                            startPoint: gradientStartPoint,
                            endPoint: gradientEndPoint
                        )
                    )

                // Bright core for active beams
                if isActive {
                    BeamShape(direction: direction)
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.2),           // Pale core at start
                                    color.opacity(0.5),           // Getting brighter
                                    color.opacity(0.8),           // Quite bright
                                    Color.white.opacity(0.9),     // White near end
                                    Color.white.opacity(1.0)      // Lively at end
                                ],
                                startPoint: gradientStartPoint,
                                endPoint: gradientEndPoint
                            )
                        )
                        .scaleEffect(0.4) // Core is smaller
                        .blur(radius: 1)

                    // Energy flow effect - pale to lively
                    BeamShape(direction: direction)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.1), Color.white.opacity(0.8)],
                                startPoint: gradientStartPoint,
                                endPoint: gradientEndPoint
                            )
                        )
                        .scaleEffect(0.2)
                        .opacity(0.3 + sparklePhase * 0.4)
                }
            }
            .scaleEffect(isActive ? 1.0 + pulsePhase * 0.03 : 1.0) // Very subtle breathing
            .shadow(color: color.opacity(isActive ? 0.6 : 0.2), radius: isActive ? 15 : 8, x: 0, y: isActive ? 6 : 3)
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                        pulsePhase = 1.0
                    }
                    withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                        glowPhase = 1.0
                    }
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        sparklePhase = 1.0
                    }
                }
            }
        }
    }

    // MARK: - Enhanced Gradient Configuration

    private var mainGradientColors: [Color] {
        if isActive {
            // Professional gradient - PALE at start, LIVELY at end
            return [
                color.opacity(0.15),          // Very pale at start
                color.opacity(0.25),          // Getting slightly brighter
                color.opacity(0.4),           // Moderately bright
                color.opacity(0.65),          // Quite bright
                color.opacity(0.85),          // Very bright
                Color.white.opacity(0.7),     // White flash near end
                color.opacity(0.95),          // Almost full color
                Color.white.opacity(0.9)      // Lively white at end
            ]
        } else {
            // Subtle gradient for inactive beams - pale to slightly brighter
            return [
                color.opacity(0.1),           // Very pale at start
                color.opacity(0.2),           // Slightly brighter
                color.opacity(0.3)            // Less pale at end
            ]
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

    private var gradientCenter: UnitPoint {
        switch direction {
        case .right: return UnitPoint(x: 0.7, y: 0.5)
        case .left: return UnitPoint(x: 0.3, y: 0.5)
        case .down: return UnitPoint(x: 0.5, y: 0.7)
        case .up: return UnitPoint(x: 0.5, y: 0.3)
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
