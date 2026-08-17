import SwiftUI

struct ScanningOverlayView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var outerRotation: Double = 0
    @State private var innerRotation: Double = 0

    private var progressPercent: Int {
        Int(min(max(viewModel.scanProgress, 0), 1) * 100)
    }

    private var categoryIcons: [String] {
        viewModel.categories.map { $0.icon }.isEmpty
            ? ["app.dashed", "externaldrive.badge.icloud", "folder.badge.gear", "doc.text", "trash", "hammer", "terminal", "arrow.down.circle", "doc.badge.arrow.up", "brain"]
            : viewModel.categories.map { $0.icon }
    }

    var body: some View {
        ZStack {
            AppColors.background
                .opacity(0.96)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    orbitalRing(radius: 160, icons: Array(categoryIcons.prefix(4)), rotation: outerRotation)
                    orbitalRing(radius: 120, icons: Array(categoryIcons.suffix(4)), rotation: innerRotation, clockwise: false)

                    GaugeView(
                        value: Double(progressPercent),
                        maxValue: 100,
                        title: "Scanning",
                        subtitle: viewModel.statusMessage,
                        colors: [AppColors.accentCyan, AppColors.accentBlue, AppColors.accentPurple],
                        lineWidth: 14
                    )
                    .frame(width: 200, height: 200)
                }
                .frame(width: 360, height: 360)

                VStack(spacing: 8) {
                    Text("\(progressPercent)%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .glowText(color: AppColors.accentCyan)

                    Text(viewModel.statusMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                }

                Spacer()

                Button {
                    // Scan is not cancellable in current engine; button provides feedback.
                } label: {
                    Text("Cancel Scan")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(NeonButtonStyle(color: AppColors.accentRed, isProminent: false))
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                outerRotation = 360
            }
            withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) {
                innerRotation = -360
            }
        }
    }

    private func orbitalRing(radius: CGFloat, icons: [String], rotation: Double, clockwise: Bool = true) -> some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [AppColors.accentCyan.opacity(0.3), AppColors.accentPurple.opacity(0.3), AppColors.accentBlue.opacity(0.3), AppColors.accentCyan.opacity(0.3)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 6])
                )
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(rotation * (clockwise ? 1 : -1)))

            ForEach(Array(icons.enumerated()), id: \.offset) { index, icon in
                let angle = (Double(index) / Double(max(icons.count, 1))) * 360
                iconNode(icon: icon, radius: radius, angle: angle)
            }
        }
    }

    private func iconNode(icon: String, radius: CGFloat, angle: Double) -> some View {
        let rad = angle * .pi / 180
        let x = radius * cos(rad)
        let y = radius * sin(rad)

        return Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppColors.accentCyan)
            .frame(width: 36, height: 36)
            .background(AppColors.cardBackground)
            .overlay(Circle().stroke(AppColors.accentCyan.opacity(0.4), lineWidth: 1))
            .clipShape(Circle())
            .offset(x: x, y: y)
            .shadow(color: AppColors.accentCyan.opacity(0.25), radius: 8, x: 0, y: 0)
    }
}
