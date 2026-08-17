import SwiftUI

struct AppColors {
    static let background = Color(red: 0.02, green: 0.03, blue: 0.06)
    static let cardBackground = Color(red: 0.06, green: 0.09, blue: 0.15).opacity(0.85)
    static let cardBorder = Color.white.opacity(0.08)

    static let accentCyan = Color(red: 0.00, green: 0.82, blue: 1.00)
    static let accentBlue = Color(red: 0.20, green: 0.45, blue: 1.00)
    static let accentPurple = Color(red: 0.55, green: 0.25, blue: 1.00)
    static let accentGreen = Color(red: 0.13, green: 0.77, blue: 0.37)
    static let accentOrange = Color(red: 1.00, green: 0.62, blue: 0.12)
    static let accentRed = Color(red: 1.00, green: 0.27, blue: 0.27)

    static let glowCyan = Color(red: 0.00, green: 0.82, blue: 1.00).opacity(0.55)
    static let glowPurple = Color(red: 0.55, green: 0.25, blue: 1.00).opacity(0.55)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.65)
    static let textMuted = Color.white.opacity(0.40)
}

extension View {
    func neonCard(color: Color = AppColors.accentCyan, lineWidth: CGFloat = 1.5) -> some View {
        self
            .background(AppColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(color.opacity(0.45), lineWidth: lineWidth)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(color.opacity(0.12), lineWidth: 3)
                    .blur(radius: 4)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: color.opacity(0.12), radius: 12, x: 0, y: 4)
    }

    func glowText(color: Color = AppColors.accentCyan) -> some View {
        self
            .shadow(color: color.opacity(0.75), radius: 6, x: 0, y: 0)
            .shadow(color: color.opacity(0.35), radius: 12, x: 0, y: 0)
    }
}

struct NeonButtonStyle: ButtonStyle {
    let color: Color
    var isProminent: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isProminent ? color.opacity(0.18) : Color.clear)
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(color.opacity(configuration.isPressed ? 0.8 : 0.55), lineWidth: 1.5)
                }
            )
            .foregroundStyle(color)
            .glowText(color: color)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
