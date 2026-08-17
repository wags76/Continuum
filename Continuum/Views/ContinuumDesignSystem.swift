import SwiftUI

enum ContinuumStyle {
    static let cornerRadius: CGFloat = 22

    static let canvas = LinearGradient(
        colors: [
            Color(.systemGroupedBackground),
            Color.accentColor.opacity(0.045),
            Color(.systemGroupedBackground)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

private struct ContinuumCardModifier: ViewModifier {
    let contentPadding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(contentPadding)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: ContinuumStyle.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ContinuumStyle.cornerRadius, style: .continuous)
                    .stroke(.primary.opacity(0.07), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.055), radius: 14, y: 6)
    }
}

extension View {
    func continuumCard(padding: CGFloat = 18) -> some View {
        modifier(ContinuumCardModifier(contentPadding: padding))
    }
}

struct ContinuumSymbolTile: View {
    let systemImage: String
    let color: Color
    var size: CGFloat = 42

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
            .accessibilityHidden(true)
    }
}

enum ContinuumFormatters {
    static func currency(_ value: Decimal) -> String {
        value.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}
