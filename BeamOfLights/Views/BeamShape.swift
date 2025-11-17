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
        let beamWidth: CGFloat = rect.width * 0.15  // Beam thickness
        let beamLength: CGFloat = rect.width * 0.7   // Beam length from center

        switch direction {
        case .right:
            // Beam pointing right
            let startTop = CGPoint(x: center.x, y: center.y - beamWidth / 2)
            let startBottom = CGPoint(x: center.x, y: center.y + beamWidth / 2)
            let endTop = CGPoint(x: center.x + beamLength, y: center.y - beamWidth / 3)
            let endBottom = CGPoint(x: center.x + beamLength, y: center.y + beamWidth / 3)

            path.move(to: startTop)
            path.addLine(to: endTop)
            path.addArc(tangent1End: CGPoint(x: center.x + beamLength + 5, y: center.y),
                       tangent2End: endBottom,
                       radius: beamWidth / 3)
            path.addLine(to: endBottom)
            path.addLine(to: startBottom)
            path.addArc(tangent1End: CGPoint(x: center.x - 5, y: center.y),
                       tangent2End: startTop,
                       radius: beamWidth / 2)
            path.closeSubpath()

        case .left:
            // Beam pointing left
            let startTop = CGPoint(x: center.x, y: center.y - beamWidth / 2)
            let startBottom = CGPoint(x: center.x, y: center.y + beamWidth / 2)
            let endTop = CGPoint(x: center.x - beamLength, y: center.y - beamWidth / 3)
            let endBottom = CGPoint(x: center.x - beamLength, y: center.y + beamWidth / 3)

            path.move(to: startTop)
            path.addLine(to: endTop)
            path.addArc(tangent1End: CGPoint(x: center.x - beamLength - 5, y: center.y),
                       tangent2End: endBottom,
                       radius: beamWidth / 3)
            path.addLine(to: endBottom)
            path.addLine(to: startBottom)
            path.addArc(tangent1End: CGPoint(x: center.x + 5, y: center.y),
                       tangent2End: startTop,
                       radius: beamWidth / 2)
            path.closeSubpath()

        case .down:
            // Beam pointing down
            let startLeft = CGPoint(x: center.x - beamWidth / 2, y: center.y)
            let startRight = CGPoint(x: center.x + beamWidth / 2, y: center.y)
            let endLeft = CGPoint(x: center.x - beamWidth / 3, y: center.y + beamLength)
            let endRight = CGPoint(x: center.x + beamWidth / 3, y: center.y + beamLength)

            path.move(to: startLeft)
            path.addLine(to: endLeft)
            path.addArc(tangent1End: CGPoint(x: center.x, y: center.y + beamLength + 5),
                       tangent2End: endRight,
                       radius: beamWidth / 3)
            path.addLine(to: endRight)
            path.addLine(to: startRight)
            path.addArc(tangent1End: CGPoint(x: center.x, y: center.y - 5),
                       tangent2End: startLeft,
                       radius: beamWidth / 2)
            path.closeSubpath()

        case .up:
            // Beam pointing up
            let startLeft = CGPoint(x: center.x - beamWidth / 2, y: center.y)
            let startRight = CGPoint(x: center.x + beamWidth / 2, y: center.y)
            let endLeft = CGPoint(x: center.x - beamWidth / 3, y: center.y - beamLength)
            let endRight = CGPoint(x: center.x + beamWidth / 3, y: center.y - beamLength)

            path.move(to: startLeft)
            path.addLine(to: endLeft)
            path.addArc(tangent1End: CGPoint(x: center.x, y: center.y - beamLength - 5),
                       tangent2End: endRight,
                       radius: beamWidth / 3)
            path.addLine(to: endRight)
            path.addLine(to: startRight)
            path.addArc(tangent1End: CGPoint(x: center.x, y: center.y + 5),
                       tangent2End: startLeft,
                       radius: beamWidth / 2)
            path.closeSubpath()

        case .none:
            // No beam
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

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main beam with gradient
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
                    BeamShape(direction: direction)
                        .fill(color)
                        .blur(radius: 8)
                        .opacity(0.6)
                }
            }
            .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Gradient Configuration

    private var gradientColors: [Color] {
        if isActive {
            return [color, color.opacity(0.3)]
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
