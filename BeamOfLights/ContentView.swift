//
//  ContentView.swift
//  BeamOfLights
//
//  Created by Akinalp Fidan on 17.11.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.white, Color.blue.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Game grid - NEW continuous path design
            GridView_New(viewModel: viewModel)
        }
    }
}

#Preview {
    ContentView()
}
