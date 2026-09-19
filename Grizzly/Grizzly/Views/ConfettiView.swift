import SwiftUI

/// A short, GPU-cheap confetti burst. Set `trigger` to a changing value
/// (e.g. an incrementing counter) to fire a new burst; the view is inert
/// and draws nothing between bursts.
struct ConfettiView: View {
    let trigger: Int

    @State private var isActive = false
    @State private var pieces: [ConfettiPiece] = []
    @State private var startDate = Date()

    private let duration: Double = 1.8
    private let pieceCount = 60
    private let gravity: Double = 0.85

    var body: some View {
        TimelineView(.animation(paused: !isActive)) { timeline in
            Canvas { context, size in
                guard isActive else { return }
                let elapsed = timeline.date.timeIntervalSince(startDate)
                guard elapsed < duration else { return }

                for piece in pieces {
                    let t = elapsed
                    let x = piece.startX * size.width + piece.velocityX * size.width * t
                    let y = piece.startY * size.height
                        + piece.velocityY * size.height * t
                        + 0.5 * gravity * size.height * t * t
                    guard y < size.height + 40 else { continue }

                    let progress = t / duration
                    let opacity = progress < 0.6 ? 1.0 : max(0, 1.0 - (progress - 0.6) / 0.4)

                    var layer = context
                    layer.opacity = opacity
                    layer.translateBy(x: x, y: y)
                    layer.rotate(by: .radians(piece.rotationStart + piece.rotationSpeed * t))
                    let rect = CGRect(x: -piece.size / 2, y: -piece.size * 0.2, width: piece.size, height: piece.size * 0.4)
                    layer.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(piece.color))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onChange(of: trigger) { _, _ in
            burst()
        }
    }

    private func burst() {
        pieces = (0..<pieceCount).map { _ in .random() }
        startDate = Date()
        isActive = true
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            isActive = false
        }
    }
}

private struct ConfettiPiece {
    var startX: Double
    var startY: Double
    var velocityX: Double
    var velocityY: Double
    var rotationStart: Double
    var rotationSpeed: Double
    var size: Double
    var color: Color

    static let palette: [Color] = [.accentColor, .yellow, .green, .pink, .blue, .orange, .purple]

    static func random() -> ConfettiPiece {
        ConfettiPiece(
            startX: .random(in: 0...1),
            startY: .random(in: -0.08...0),
            velocityX: .random(in: -0.3...0.3),
            velocityY: .random(in: 0.05...0.25),
            rotationStart: .random(in: 0...(2 * .pi)),
            rotationSpeed: .random(in: -6...6),
            size: .random(in: 6...12),
            color: palette.randomElement() ?? .accentColor
        )
    }
}
