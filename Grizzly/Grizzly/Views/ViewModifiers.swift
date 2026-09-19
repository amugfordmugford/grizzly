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
