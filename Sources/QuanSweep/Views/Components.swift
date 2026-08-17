import SwiftUI

struct GaugeView: View {
    let value: Double
    let maxValue: Double
    let title: String
    let subtitle: String
    var colors: [Color] = [AppColors.accentCyan, AppColors.accentBlue, AppColors.accentPurple]
    var lineWidth: CGFloat = 18

    private var progress: Double {
        maxValue > 0 ? min(max(value / maxValue, 0), 1) : 0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: colors, center: .center, startAngle: .degrees(0), endAngle: .degrees(360)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: colors.first?.opacity(0.5) ?? .clear, radius: 12, x: 0, y: 0)

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)

                Text(formattedValue)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .glowText(color: colors.first ?? AppColors.accentCyan)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(colors.first ?? AppColors.accentCyan)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var formattedValue: String {
        if maxValue == 100 {
            return "\(Int(value))%"
        } else {
            return ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .file)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    var history: [Double] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .glowText(color: color)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppColors.textMuted)

            sparkline
                .frame(height: 28)
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard(color: color.opacity(0.6))
    }

    private var sparkline: some View {
        GeometryReader { geo in
            if history.count >= 2 {
                let points = history.normalized()
                Path { path in
                    let stepX = geo.size.width / CGFloat(points.count - 1)
                    for (index, point) in points.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = geo.size.height - (CGFloat(point) * geo.size.height)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color.opacity(0.7), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .overlay(
                    Path { path in
                        let stepX = geo.size.width / CGFloat(points.count - 1)
                        path.move(to: CGPoint(x: 0, y: geo.size.height))
                        for (index, point) in points.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = geo.size.height - (CGFloat(point) * geo.size.height)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    }
                    .fill(color.opacity(0.12))
                )
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.1))
            }
        }
    }
}

struct RingView: View {
    let progress: Double
    let color: Color
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.6), radius: 6, x: 0, y: 0)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(width: 44, height: 44)

            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .textCase(.uppercase)
                Text(subtitle)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: 70)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct SafetyBadge: View {
    let safety: SafetyLevel

    var body: some View {
        Text(safety.rawValue.uppercased())
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.45), lineWidth: 1))
    }

    private var color: Color {
        switch safety {
        case .safe: return AppColors.accentGreen
        case .review: return AppColors.accentOrange
        case .advanced: return AppColors.accentRed
        case .protected: return AppColors.accentBlue
        }
    }
}

private extension Array where Element == Double {
    func normalized() -> [Double] {
        guard let min = self.min(), let max = self.max(), max > min else {
            return map { _ in 0.5 }
        }
        return map { ($0 - min) / (max - min) }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .lineLimit(2)

            Spacer()
        }
    }
}
