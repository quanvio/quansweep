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
    var showScaleLabels: Bool = true

    private var progress: Double {
        maxValue > 0 ? min(max(value / maxValue, 0), 1) : 0
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let outerLine: CGFloat = max(10, size * 0.055)
            let innerLine: CGFloat = max(5, size * 0.028)
            let radius = (size - outerLine) / 2
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                // Outer dark track
                ArcShape(startAngle: 135, endAngle: 405)
                    .stroke(Color.white.opacity(0.04), style: StrokeStyle(lineWidth: outerLine, lineCap: .round))

                // Thin colored zone indicators on the outer track
                ArcShape(startAngle: 135, endAngle: 225)
                    .stroke(AppColors.accentGreen.opacity(0.55), style: StrokeStyle(lineWidth: outerLine, lineCap: .butt))

                ArcShape(startAngle: 225, endAngle: 315)
                    .stroke(AppColors.accentOrange.opacity(0.55), style: StrokeStyle(lineWidth: outerLine, lineCap: .butt))

                ArcShape(startAngle: 315, endAngle: 405)
                    .stroke(AppColors.accentRed.opacity(0.55), style: StrokeStyle(lineWidth: outerLine, lineCap: .butt))

                // Inner progress arc (bright neon)
                ArcShape(startAngle: 135, endAngle: 135 + progress * 270)
                    .stroke(
                        AngularGradient(
                            colors: [AppColors.accentCyan, AppColors.accentBlue, AppColors.accentPurple],
                            center: .center,
                            startAngle: .degrees(135),
                            endAngle: .degrees(135 + progress * 270)
                        ),
                        style: StrokeStyle(lineWidth: innerLine, lineCap: .round)
                    )
                    .shadow(color: AppColors.accentCyan.opacity(0.75), radius: 8, x: 0, y: 0)

                // Tick marks (thin, subtle)
                ForEach(0..<31) { i in
                    let angle = 135 + Double(i) * (270 / 30)
                    let isMajor = i % 5 == 0
                    let inner = radius - outerLine * 0.35
                    let outer = radius - outerLine * (isMajor ? 0.62 : 0.48)
                    let innerRad = angle * .pi / 180
                    let outerRad = angle * .pi / 180

                    Path { path in
                        path.move(to: CGPoint(
                            x: center.x + Darwin.cos(innerRad) * inner,
                            y: center.y + Darwin.sin(innerRad) * inner
                        ))
                        path.addLine(to: CGPoint(
                            x: center.x + Darwin.cos(outerRad) * outer,
                            y: center.y + Darwin.sin(outerRad) * outer
                        ))
                    }
                    .stroke(Color.white.opacity(isMajor ? 0.25 : 0.10), style: StrokeStyle(lineWidth: isMajor ? 1.2 : 0.7, lineCap: .round))
                }

                // Scale labels
                if showScaleLabels {
                    ForEach([0, 25, 50, 75, 100], id: \.self) { label in
                        let t = Double(label) / 100.0
                        let angle = 135 + t * 270
                        let rad = angle * .pi / 180
                        let labelRadius = radius - outerLine * 0.95
                        let x = center.x + Darwin.cos(rad) * labelRadius
                        let y = center.y + Darwin.sin(rad) * labelRadius

                        Text("\(label)")
                            .font(.system(size: max(8, size * 0.038), weight: .bold))
                            .foregroundStyle(AppColors.textMuted.opacity(0.8))
                            .position(x: x, y: y)
                    }
                }

                // Needle with glow
                let needleAngle = 135 + progress * 270
                NeedleShape(angle: needleAngle, length: radius * 0.72, width: max(3.5, size * 0.016))
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accentCyan, .white],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: AppColors.accentCyan.opacity(0.8), radius: 5, x: 0, y: 0)

                // Needle cap
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, AppColors.accentCyan, AppColors.background],
                            center: .center,
                            startRadius: 0,
                            endRadius: max(7, size * 0.035)
                        )
                    )
                    .frame(width: max(12, size * 0.05), height: max(12, size * 0.05))
                    .overlay(Circle().stroke(AppColors.accentCyan.opacity(0.8), lineWidth: 1.2))
                    .shadow(color: AppColors.accentCyan.opacity(0.6), radius: 3, x: 0, y: 0)

                // Center text
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: max(7, size * 0.028), weight: .bold))
                        .foregroundStyle(AppColors.textMuted)
                        .textCase(.uppercase)

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(valueNumber)
                            .font(.system(size: max(20, size * 0.11), weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        Text(valueUnit)
                            .font(.system(size: max(10, size * 0.042), weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                    .shadow(color: .white.opacity(0.10), radius: 4, x: 0, y: 0)

                    Text(subtitle)
                        .font(.system(size: max(8, size * 0.03), weight: .semibold))
                        .foregroundStyle(AppColors.accentCyan)
                        .lineLimit(1)
                }
                .offset(y: size * 0.16)
            }
        }
        .aspectRatio(1.25, contentMode: .fit)
    }

    private var valueNumber: String {
        if maxValue == 100 {
            return "\(Int(value))"
        } else {
            let formatted = ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .file)
            let components = formatted.split(separator: " ")
            if components.count > 1 {
                return String(components.dropLast().joined(separator: " "))
            }
            return formatted
        }
    }

    private var valueUnit: String {
        if maxValue == 100 {
            return "%"
        } else {
            let formatted = ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .file)
            let components = formatted.split(separator: " ")
            if components.count > 1, let last = components.last {
                return String(last)
            }
            return ""
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
        let tip = CGPoint(x: center.x + Darwin.cos(rad) * length, y: center.y + Darwin.sin(rad) * length)
        let tailAngle1 = (angle + 180 - 20) * .pi / 180
        let tailAngle2 = (angle + 180 + 20) * .pi / 180
        let tailLength = length * 0.16
        let tail1 = CGPoint(x: center.x + Darwin.cos(tailAngle1) * tailLength, y: center.y + Darwin.sin(tailAngle1) * tailLength)
        let tail2 = CGPoint(x: center.x + Darwin.cos(tailAngle2) * tailLength, y: center.y + Darwin.sin(tailAngle2) * tailLength)

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
