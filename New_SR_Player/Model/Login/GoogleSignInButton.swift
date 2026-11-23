//
//  GoogleSignInButton.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2024-04-18.
//

import SwiftUI
import GoogleSignIn


// MARK: - GoogleSignInButton
struct GoogleSignInButton: UIViewRepresentable {
    var action: () -> Void = {}

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    func makeUIView(context: Context) -> GIDSignInButton {
        let button = GIDSignInButton()
        button.style = .wide
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: GIDSignInButton, context: Context) {}

    class Coordinator: NSObject {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func tapped() { action() }
    }
}
