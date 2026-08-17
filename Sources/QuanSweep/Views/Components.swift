import SwiftUI

// MARK: - Gauge

struct GaugeView: View {
    let value: Double
    let maxValue: Double
    let title: String
    let subtitle: String
    var colors: [Color] = [AppColors.accentCyan, AppColors.accentBlue, AppColors.accentPurple]
    var lineWidth: CGFloat = 16

    private var progress: Double {
        maxValue > 0 ? min(max(value / maxValue, 0), 1) : 0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: colors,
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppColors.textMuted)
                    .textCase(.uppercase)

                Text(formattedValue)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)

                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold))
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

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    var history: [Double] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .captionLabel()

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppColors.textMuted)

            sparkline
                .frame(height: 24)
                .padding(.top, 2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
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
                .stroke(color.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
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
                    .fill(color.opacity(0.08))
                )
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.06))
            }
        }
    }
}

// MARK: - System Ring

struct RingView: View {
    let progress: Double
    let color: Color
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(width: 40, height: 40)

            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .textCase(.uppercase)
                Text(subtitle)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: 60)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Safety Badge

struct SafetyBadge: View {
    let safety: SafetyLevel

    var body: some View {
        Text(safety.rawValue.uppercased())
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.30), lineWidth: 1))
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

// MARK: - Detail Row

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

// MARK: - Helpers

private extension Array where Element == Double {
    func normalized() -> [Double] {
        guard let min = self.min(), let max = self.max(), max > min else {
            return map { _ in 0.5 }
        }
        return map { ($0 - min) / (max - min) }
    }
}
