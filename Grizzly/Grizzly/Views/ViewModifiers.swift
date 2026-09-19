import SwiftUI

extension View {
    /// A rounded glass surface on iOS 26+ (Liquid Glass), falling back to a
    /// translucent material on earlier OS versions this app still supports
    /// (deployment target stays 18.0).
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            self.background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

/// A large, rounded-weight number paired with a small caption label — for
/// surfacing a stat (word count, progress) rather than burying it in body text.
struct StatNumber: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// A shared, stable color-by-index palette so the same item (a project, a
/// leaderboard participant) always gets the same accent color wherever it's
/// shown, without needing any color data from the API.
enum AccentPalette {
    static let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal, .yellow, .indigo, .mint, .cyan]

    static func color(at index: Int) -> Color {
        colors[index % colors.count]
    }
}

/// A rounded, elevated card with a colored accent bar on the leading edge -
/// used for Projects and Standings rows so each item reads as a distinct
/// tile rather than a plain list row.
struct EdgeAccentCard<Content: View>: View {
    let accentColor: Color
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 0) {
            accentColor
                .frame(width: 5)
            content
                .padding(14)
            Spacer(minLength: 0)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 3)
    }
}
