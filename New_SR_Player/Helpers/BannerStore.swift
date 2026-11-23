//
//  BannerStore.swift
//  New_SR_Player
//

import SwiftUI


// MARK: - BannerStore

@MainActor
final class BannerStore: ObservableObject {
    @Published private(set) var message: String = ""
    @Published private(set) var isVisible: Bool = false

    private var dismissTask: Task<Void, Never>?

    func show(_ message: String, duration: Double = 3) {
        dismissTask?.cancel()
        self.message = message
        isVisible = true
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        isVisible = false
    }
}


// MARK: - BannerView

private struct BannerView: View {
    @EnvironmentObject var banner: BannerStore

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.body.bold())
            Text(banner.message)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            Spacer()
            Button {
                banner.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.bold())
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.red.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
    }
}


// MARK: - BannerModifier

private struct BannerModifier: ViewModifier {
    @EnvironmentObject var banner: BannerStore

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            if banner.isVisible {
                BannerView()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: banner.isVisible)
    }
}

extension View {
    func bannerOverlay() -> some View {
        modifier(BannerModifier())
    }
}
