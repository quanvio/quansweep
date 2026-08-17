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

// MARK: - Speedometer Gauge

struct SpeedometerGauge: View {
    let value: Double
    let maxValue: Double
    let title: String
    let subtitle: String

    private var progress: Double {
        maxValue > 0 ? min(max(value / maxValue, 0), 1) : 0
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let lineWidth: CGFloat = max(10, size * 0.055)
            let radius = (size - lineWidth) / 2

            ZStack {
                // Background arc
                ArcShape(startAngle: 135, endAngle: 405)
                    .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                // Colored zones
                ArcShape(startAngle: 135, endAngle: 225)
                    .stroke(AppColors.accentGreen, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                ArcShape(startAngle: 225, endAngle: 315)
                    .stroke(AppColors.accentOrange, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                ArcShape(startAngle: 315, endAngle: 405)
                    .stroke(AppColors.accentRed, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))

                // Tick marks
                ForEach(0..<21) { i in
                    let angle = 135 + Double(i) * (270 / 20)
                    let isMajor = i % 5 == 0
                    let inner = radius - lineWidth * (isMajor ? 0.55 : 0.35)
                    let outer = radius - lineWidth * (isMajor ? 0.75 : 0.55)
                    let innerRad = angle * .pi / 180
                    let outerRad = angle * .pi / 180

                    Path { path in
                        path.move(to: CGPoint(
                            x: geo.size.width / 2 + cos(innerRad) * inner,
                            y: geo.size.height / 2 + sin(innerRad) * inner
                        ))
                        path.addLine(to: CGPoint(
                            x: geo.size.width / 2 + cos(outerRad) * outer,
                            y: geo.size.height / 2 + sin(outerRad) * outer
                        ))
                    }
                    .stroke(Color.white.opacity(isMajor ? 0.25 : 0.10), style: StrokeStyle(lineWidth: isMajor ? 1.5 : 0.8, lineCap: .round))
                }

                // Needle
                let needleAngle = 135 + progress * 270
                NeedleShape(angle: needleAngle, length: radius * 0.85, width: max(4, size * 0.02))
                    .fill(AppColors.accentCyan)
                    .shadow(color: AppColors.accentCyan.opacity(0.5), radius: 4, x: 0, y: 0)

                // Needle cap
                Circle()
                    .fill(AppColors.background)
                    .frame(width: max(14, size * 0.07), height: max(14, size * 0.07))
                    .overlay(Circle().stroke(AppColors.accentCyan, lineWidth: 2))

                // Center text
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: max(8, size * 0.045), weight: .bold))
                        .foregroundStyle(AppColors.textMuted)
                        .textCase(.uppercase)

                    Text(formattedValue)
                        .font(.system(size: max(22, size * 0.17), weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(subtitle)
                        .font(.system(size: max(8, size * 0.04), weight: .semibold))
                        .foregroundStyle(AppColors.accentCyan)
                        .lineLimit(1)
                }
                .offset(y: size * 0.08)
            }
        }
        .aspectRatio(1.25, contentMode: .fit)
    }

    private var formattedValue: String {
        if maxValue == 100 {
            return "\(Int(value))%"
        } else {
            return ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .file)
        }
    }
}

// MARK: - Arc & Needle Shapes

private struct ArcShape: Shape {
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        return path
    }
}

private struct NeedleShape: Shape {
    let angle: Double
    let length: CGFloat
    let width: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let rad = angle * .pi / 180
        let tip = CGPoint(x: center.x + cos(rad) * length, y: center.y + sin(rad) * length)
        let tailAngle1 = (angle + 180 - 25) * .pi / 180
        let tailAngle2 = (angle + 180 + 25) * .pi / 180
        let tailLength = length * 0.18
        let tail1 = CGPoint(x: center.x + cos(tailAngle1) * tailLength, y: center.y + sin(tailAngle1) * tailLength)
        let tail2 = CGPoint(x: center.x + cos(tailAngle2) * tailLength, y: center.y + sin(tailAngle2) * tailLength)

        var path = Path()
        path.move(to: tip)
        path.addLine(to: tail1)
        path.addLine(to: tail2)
        path.closeSubpath()
        return path
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
