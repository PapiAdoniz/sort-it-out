import SwiftUI

struct SubtleBackgroundView: View {
    @AppStorage(AppTheme.themeKey) private var selectedThemeRawValue = AppTheme.defaultTheme.rawValue

    private var theme: AppColorTheme {
        AppColorTheme(rawValue: selectedThemeRawValue) ?? AppTheme.defaultTheme
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                ambientGlows(size: geometry.size)

                TimelineView(.animation) { timeline in
                    WaveBackgroundView(
                        time: timeline.date.timeIntervalSinceReferenceDate,
                        theme: theme
                    )
                    .ignoresSafeArea()
                }
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func ambientGlows(size: CGSize) -> some View {
        let colors = theme.colors

        Circle()
            .fill(
                RadialGradient(
                    colors: [colors.accent.opacity(0.14), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size.width * 0.35
                )
            )
            .frame(width: size.width * 0.7, height: size.width * 0.7)
            .offset(x: -size.width * 0.22, y: -size.height * 0.28)
            .blur(radius: 40)

        Circle()
            .fill(
                RadialGradient(
                    colors: [colors.glow.opacity(0.10), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size.width * 0.30
                )
            )
            .frame(width: size.width * 0.65, height: size.width * 0.65)
            .offset(x: size.width * 0.28, y: size.height * 0.18)
            .blur(radius: 36)

        Circle()
            .fill(
                RadialGradient(
                    colors: [colors.accentSecondary.opacity(0.12), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size.width * 0.28
                )
            )
            .frame(width: size.width * 0.55, height: size.width * 0.55)
            .offset(x: size.width * 0.05, y: size.height * 0.42)
            .blur(radius: 32)
    }
}

private struct WaveLayerSpec {
    let yFraction: CGFloat
    let amplitudeScale: CGFloat
    let frequency: CGFloat
    let phaseOffset: CGFloat
    let driftScale: CGFloat
    let colorRole: WaveColorRole
    let opacity: Double
    let lineScale: CGFloat
}

private enum WaveColorRole {
    case accent
    case secondary
    case glow
    case muted
}

private struct WaveBackgroundView: View {
    let time: TimeInterval
    let theme: AppColorTheme

    private static let layers: [WaveLayerSpec] = [
        WaveLayerSpec(yFraction: 0.07, amplitudeScale: 0.036, frequency: 1.05, phaseOffset: 0.0, driftScale: 0.020, colorRole: .accent, opacity: 0.32, lineScale: 0.0020),
        WaveLayerSpec(yFraction: 0.16, amplitudeScale: 0.044, frequency: 1.30, phaseOffset: 0.5, driftScale: 0.026, colorRole: .secondary, opacity: 0.28, lineScale: 0.0022),
        WaveLayerSpec(yFraction: 0.26, amplitudeScale: 0.040, frequency: 1.55, phaseOffset: 1.0, driftScale: 0.022, colorRole: .glow, opacity: 0.24, lineScale: 0.0019),
        WaveLayerSpec(yFraction: 0.36, amplitudeScale: 0.048, frequency: 1.20, phaseOffset: 1.6, driftScale: 0.028, colorRole: .accent, opacity: 0.22, lineScale: 0.0024),
        WaveLayerSpec(yFraction: 0.46, amplitudeScale: 0.042, frequency: 1.70, phaseOffset: 0.3, driftScale: 0.024, colorRole: .muted, opacity: 0.20, lineScale: 0.0018),
        WaveLayerSpec(yFraction: 0.56, amplitudeScale: 0.046, frequency: 1.85, phaseOffset: 2.0, driftScale: 0.026, colorRole: .secondary, opacity: 0.22, lineScale: 0.0021),
        WaveLayerSpec(yFraction: 0.66, amplitudeScale: 0.038, frequency: 2.05, phaseOffset: 0.8, driftScale: 0.020, colorRole: .glow, opacity: 0.24, lineScale: 0.0019),
        WaveLayerSpec(yFraction: 0.76, amplitudeScale: 0.044, frequency: 1.45, phaseOffset: 2.5, driftScale: 0.025, colorRole: .accent, opacity: 0.26, lineScale: 0.0020),
        WaveLayerSpec(yFraction: 0.86, amplitudeScale: 0.036, frequency: 1.65, phaseOffset: 1.2, driftScale: 0.022, colorRole: .secondary, opacity: 0.30, lineScale: 0.0018),
        WaveLayerSpec(yFraction: 0.94, amplitudeScale: 0.032, frequency: 1.90, phaseOffset: 0.6, driftScale: 0.018, colorRole: .glow, opacity: 0.28, lineScale: 0.0017)
    ]

    var body: some View {
        let palette = theme.colors

        Canvas { context, size in
            let width = max(size.width, 1)
            let height = max(size.height, 1)
            let elapsed = CGFloat(time)
            let wavePhase = elapsed * 0.12

            for (index, layer) in Self.layers.enumerated() {
                let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
                drawWave(
                    in: &context,
                    size: size,
                    baseY: height * layer.yFraction,
                    amplitude: height * layer.amplitudeScale,
                    frequency: layer.frequency,
                    phase: wavePhase * direction + layer.phaseOffset,
                    verticalDrift: sin(wavePhase * 0.8 + layer.phaseOffset) * height * layer.driftScale,
                    color: color(for: layer.colorRole, palette: palette).opacity(layer.opacity),
                    lineWidth: max(width * layer.lineScale, 0.9)
                )
            }

            drawLightParticles(
                in: &context,
                size: size,
                palette: palette,
                elapsed: elapsed
            )
        }
        .blendMode(.screen)
        .opacity(0.82)
        .id(theme.rawValue)
    }

    private func color(for role: WaveColorRole, palette: ThemeColors) -> Color {
        switch role {
        case .accent: return palette.accent
        case .secondary: return palette.accentSecondary
        case .glow: return palette.glow
        case .muted: return palette.lightGray
        }
    }

    private func drawWave(
        in context: inout GraphicsContext,
        size: CGSize,
        baseY: CGFloat,
        amplitude: CGFloat,
        frequency: CGFloat,
        phase: CGFloat,
        verticalDrift: CGFloat,
        color: Color,
        lineWidth: CGFloat
    ) {
        var path = Path()
        let horizontalPadding = size.width * 0.08
        let startX = -horizontalPadding
        let endX = size.width + horizontalPadding
        let step = max(size.width / 96, 6)

        var x = startX
        var isFirstPoint = true
        while x <= endX {
            let progress = (x - startX) / max(endX - startX, 1)
            let envelope = sin(progress * .pi)
            let primary = sin(progress * .pi * 2 * frequency + phase)
            let secondary = sin(progress * .pi * 2 * (frequency * 0.48) - phase * 0.65)
            let y = baseY + verticalDrift + (primary * amplitude + secondary * amplitude * 0.38) * envelope

            if isFirstPoint {
                path.move(to: CGPoint(x: x, y: y))
                isFirstPoint = false
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }

            x += step
        }

        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        )
    }

    private func drawLightParticles(
        in context: inout GraphicsContext,
        size: CGSize,
        palette: ThemeColors,
        elapsed: CGFloat
    ) {
        for index in 0..<36 {
            let seed = CGFloat(index + 1)
            let speed = 0.020 + fractional(seed * 0.31) * 0.030
            let baseX = fractional(sin(seed * 12.9898) * 43758.5453)
            let baseY = fractional(sin(seed * 78.233) * 24634.6345)
            let stream = fractional(baseX + elapsed * speed)
            let waveOffset = sin(stream * .pi * 2 * (1.2 + fractional(seed * 0.43)) + elapsed * 0.65 + seed)
            let center = CGPoint(
                x: stream * size.width,
                y: baseY * size.height + waveOffset * 18
            )
            let radius = 0.55 + fractional(seed * 1.91) * 0.95
            let lift = (sin(elapsed * (0.55 + fractional(seed * 0.19) * 0.35) + seed) + 1) / 2
            let opacity = 0.055 + Double(lift) * 0.12
            let trailLength = 7 + fractional(seed * 2.37) * 15

            let color = index.isMultiple(of: 3)
                ? palette.glow
                : (index.isMultiple(of: 2) ? palette.accent : palette.accentSecondary)

            drawLightParticle(
                in: &context,
                center: center,
                radius: radius,
                trailLength: trailLength,
                opacity: opacity,
                color: color,
                phase: seed + elapsed * 0.45
            )
        }
    }

    private func drawLightParticle(
        in context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        trailLength: CGFloat,
        opacity: Double,
        color: Color,
        phase: CGFloat
    ) {
        let haloRadius = radius * 5
        let haloRect = CGRect(
            x: center.x - haloRadius,
            y: center.y - haloRadius,
            width: haloRadius * 2,
            height: haloRadius * 2
        )
        context.fill(
            Path(ellipseIn: haloRect),
            with: .radialGradient(
                Gradient(colors: [
                    color.opacity(opacity * 0.55),
                    color.opacity(opacity * 0.12),
                    .clear
                ]),
                center: center,
                startRadius: 0,
                endRadius: haloRadius
            )
        )

        let angle = -0.10 + sin(phase) * 0.08
        let trailEnd = CGPoint(
            x: center.x - cos(angle) * trailLength,
            y: center.y - sin(angle) * trailLength
        )
        var trail = Path()
        trail.move(to: trailEnd)
        trail.addLine(to: center)
        context.stroke(
            trail,
            with: .linearGradient(
                Gradient(colors: [
                    .clear,
                    color.opacity(opacity * 0.32),
                    color.opacity(opacity * 0.70)
                ]),
                startPoint: trailEnd,
                endPoint: center
            ),
            style: StrokeStyle(lineWidth: max(radius * 0.7, 0.6), lineCap: .round)
        )

        let coreRadius = radius
        let coreRect = CGRect(
            x: center.x - coreRadius,
            y: center.y - coreRadius,
            width: coreRadius * 2,
            height: coreRadius * 2
        )
        context.fill(
            Path(ellipseIn: coreRect),
            with: .color(color.opacity(opacity))
        )
    }

    private func fractional(_ value: CGFloat) -> CGFloat {
        value - floor(value)
    }
}

#Preview {
    SubtleBackgroundView()
}
