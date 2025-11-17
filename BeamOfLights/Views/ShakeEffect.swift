//
//  ShakeEffect.swift
//  BeamOfLights
//
//  Shake animation effect for wrong moves
//

import SwiftUI

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0
        ))
    }
}

extension View {
    func shake(trigger: Bool) -> some View {
        self.modifier(ShakeModifier(trigger: trigger))
    }
}

struct ShakeModifier: ViewModifier {
    @State private var attempts: CGFloat = 0
    let trigger: Bool

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: attempts))
            .onChange(of: trigger) { _, _ in
                withAnimation(.spring(duration: 0.5)) {
                    attempts += 1
                }
            }
    }
}
