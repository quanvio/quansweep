import SwiftUI

// MARK: - Glassmorphism Design System

struct AppColors {
    static let background = Color(.sRGB, red: 0.02, green: 0.03, blue: 0.06, opacity: 1)
    static let cardBackground = Color.white.opacity(0.04)
    static let cardHover = Color.white.opacity(0.07)
    static let cardBorder = Color.white.opacity(0.09)
    static let divider = Color.white.opacity(0.06)

    static let accentCyan = Color(.sRGB, red: 0.02, green: 0.71, blue: 0.83, opacity: 1)
    static let accentBlue = Color(.sRGB, red: 0.23, green: 0.51, blue: 0.96, opacity: 1)
    static let accentPurple = Color(.sRGB, red: 0.55, green: 0.36, blue: 0.96, opacity: 1)
    static let accentGreen = Color(.sRGB, red: 0.13, green: 0.77, blue: 0.37, opacity: 1)
    static let accentOrange = Color(.sRGB, red: 0.96, green: 0.62, blue: 0.07, opacity: 1)
    static let accentYellow = Color(.sRGB, red: 0.95, green: 0.84, blue: 0.10, opacity: 1)
    static let accentRed = Color(.sRGB, red: 0.93, green: 0.27, blue: 0.27, opacity: 1)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.65)
    static let textMuted = Color.white.opacity(0.40)
}

extension View {
    func glassCard(cornerRadius: CGFloat = 12, border: Bool = true) -> some View {
        self
            .background(AppColors.cardBackground)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(border ? AppColors.cardBorder : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    func glassButton(color: Color, isProminent: Bool = true) -> some View {
        self
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isProminent ? color.opacity(0.12) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(color.opacity(0.35), lineWidth: 1)
            )
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func sectionTitle() -> some View {
        self
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(AppColors.textPrimary)
    }

    func captionLabel() -> some View {
        self
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(AppColors.textMuted)
            .textCase(.uppercase)
    }
}

struct GlassButtonStyle: ButtonStyle {
    let color: Color
    var isProminent: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .glassButton(color: color, isProminent: isProminent)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SidebarButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.10))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(color.opacity(0.30), lineWidth: 1))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
