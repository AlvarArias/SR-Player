//
//  LottieStruc.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2024-04-04.
//

import SwiftUI
import Lottie
import ImageIO

struct LottieView: UIViewRepresentable {
    let lottieFile: String

    func makeCoordinator() -> LottieAnimationView {
        let animationView = LottieAnimationView()
        animationView.animation = LottieAnimation.named(lottieFile)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.play()
        return animationView
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let animationView = context.coordinator
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        animationView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}


// MARK: - GIFView

struct GIFView: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.image = UIImage.animatedGIF(named: gifName)
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}
}

// MARK: - PulsingRing

struct PulsingRing: ViewModifier {
    let isActive: Bool
    let color: Color
    @State private var animate = false

    func body(content: Content) -> some View {
        content.overlay {
            if isActive {
                ZStack {
                    pulseCircle(delay: 0)
                    pulseCircle(delay: 0.45)
                }
                .onAppear { animate = true }
                .onDisappear { animate = false }
            }
        }
    }

    private func pulseCircle(delay: Double) -> some View {
        Circle()
            .stroke(color.opacity(animate ? 0 : 0.65), lineWidth: 2)
            .scaleEffect(animate ? 2.0 : 1.0)
            .animation(
                .easeOut(duration: 1.1)
                    .repeatForever(autoreverses: false)
                    .delay(delay),
                value: animate
            )
    }
}

extension View {
    func pulsingRing(isActive: Bool, color: Color = .white) -> some View {
        modifier(PulsingRing(isActive: isActive, color: color))
    }
}


// MARK: - EqualizerView

struct EqualizerView: View {
    let color: Color
    @State private var animate = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            bar(maxHeight: 10, duration: 0.5)
            bar(maxHeight: 14, duration: 0.4)
            bar(maxHeight:  8, duration: 0.6)
        }
        .frame(height: 14)
        .onAppear { withAnimation { animate = true } }
        .onDisappear { animate = false }
    }

    private func bar(maxHeight: CGFloat, duration: Double) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 3, height: animate ? maxHeight : 3)
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: animate
            )
    }
}


// MARK: - PlayPulseButtonStyle

struct PlayPulseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.82 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PlayPulseButtonStyle {
    static var playPulse: PlayPulseButtonStyle { PlayPulseButtonStyle() }
}


private extension UIImage {
    static func animatedGIF(named name: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        let count = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        var totalDuration: Double = 0

        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            frames.append(UIImage(cgImage: cgImage))
            let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any]
            let gifProps = props?[kCGImagePropertyGIFDictionary as String] as? [String: Any]
            let delay = gifProps?[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double
                     ?? gifProps?[kCGImagePropertyGIFDelayTime as String] as? Double
                     ?? 0.1
            totalDuration += delay
        }

        return UIImage.animatedImage(with: frames, duration: totalDuration)
    }
}
