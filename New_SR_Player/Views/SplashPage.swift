//
//  SplasPage.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2024-04-04.
//

import Foundation
import SwiftUI
import Lottie


struct SplashPage: View {
    
    @State private var isActive = false
    @State private var isVStackVisible = false

    var body: some View {
        ZStack {
            if isActive {
                ContentView()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                VStack {
                    Text("Välkommen")
                        .font(.largeTitle)
                        .accessibilityLabel("Välkommen")
                    Spacer()
                    GIFView(gifName: "Headphone")
                        .frame(width: 220, height: 220)
                    Spacer()
                }
                .opacity(isVStackVisible ? 1.0 : 0.0)
                .animation(.easeIn(duration: 2.0), value: isVStackVisible)
                .onAppear {
                    withAnimation {
                        isVStackVisible = true
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            showNextScreen()
        }
    }

    private func showNextScreen() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isActive = true
            }
        }
    }
        
}
    
