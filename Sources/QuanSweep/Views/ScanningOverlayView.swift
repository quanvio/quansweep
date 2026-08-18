import SwiftUI

struct ScanningOverlayView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var outerRotation: Double = 0
    @State private var innerRotation: Double = 0
    @State private var animatedProgress: Double = 0

    private var progressPercent: Int {
        Int(min(max(animatedProgress, 0), 1) * 100)
    }

    private var categoryIcons: [String] {
        viewModel.categories.map { $0.icon }.isEmpty
            ? ["app.dashed", "externaldrive.badge.icloud", "folder.badge.gear", "doc.text", "trash", "hammer", "terminal", "arrow.down.circle"]
            : viewModel.categories.map { $0.icon }
    }

    var body: some View {
        ZStack {
            AppColors.background
                .opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 20)

                ZStack {
                    orbitalRing(radius: 150, icons: Array(categoryIcons.prefix(4)), rotation: outerRotation)
                    orbitalRing(radius: 110, icons: Array(categoryIcons.suffix(4)), rotation: innerRotation, clockwise: false)

                    GaugeView(
                        value: Double(progressPercent),
                        maxValue: 100,
                        title: "Scanning",
                        subtitle: viewModel.statusMessage,
                        colors: [AppColors.accentCyan, AppColors.accentBlue, AppColors.accentPurple],
                        lineWidth: 12
                    )
                    .frame(width: 180, height: 180)
                }
                .frame(width: 340, height: 340)
                .onChange(of: viewModel.scanProgress) { _, newValue in
                    withAnimation(.easeOut(duration: 0.55)) {
                        animatedProgress = newValue
                    }
                }

                Text(viewModel.statusMessage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)

                Spacer(minLength: 20)

                Button {
                    // Scan is not cancellable in current engine; button provides feedback.
                } label: {
                    Text("Cancel Scan")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(GlassButtonStyle(color: AppColors.accentRed, isProminent: false))
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) {
                outerRotation = 360
            }
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                innerRotation = -360
            }
        }
    }

    private func orbitalRing(radius: CGFloat, icons: [String], rotation: Double, clockwise: Bool = true) -> some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            AppColors.accentCyan.opacity(0.45),
                            AppColors.accentPurple.opacity(0.35),
                            AppColors.accentBlue.opacity(0.45),
                            AppColors.accentCyan.opacity(0.45)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 1.5, dash: [5, 5])
                )
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(rotation * (clockwise ? 1 : -1)))

            Circle()
                .stroke(AppColors.accentCyan.opacity(0.08), lineWidth: 1)
                .frame(width: radius * 2, height: radius * 2)

            ForEach(Array(icons.enumerated()), id: \.offset) { index, icon in
                let angle = (Double(index) / Double(max(icons.count, 1))) * 360
                iconNode(icon: icon, radius: radius, angle: angle, rotation: rotation, clockwise: clockwise)
            }
        }
    }

    private func iconNode(icon: String, radius: CGFloat, angle: Double, rotation: Double, clockwise: Bool) -> some View {
        let rad = angle * .pi / 180
        let x = radius * cos(rad)
        let y = radius * sin(rad)

        return Image(systemName: icon)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppColors.accentCyan)
            .frame(width: 34, height: 34)
            .background(AppColors.cardBackground.opacity(0.95))
            .overlay(Circle().stroke(AppColors.accentCyan.opacity(0.45), lineWidth: 1))
            .clipShape(Circle())
            .shadow(color: AppColors.accentCyan.opacity(0.25), radius: 6, x: 0, y: 0)
            .offset(x: x, y: y)
            .rotationEffect(.degrees(-rotation * (clockwise ? 1 : -1)))
    }
}
