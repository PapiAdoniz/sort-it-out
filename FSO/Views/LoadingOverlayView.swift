import SwiftUI

struct LoadingActivity: Equatable {
    var title: String
    var detail: String
    var note: String
    var completed: Int
    var total: Int
    var recent: [String]

    static let idle = LoadingActivity(
        title: "Working",
        detail: "",
        note: "",
        completed: 0,
        total: 0,
        recent: []
    )

    var fraction: Double {
        guard total > 0 else { return 0 }
        return min(1, Double(completed) / Double(total))
    }
}

struct LoadingOverlayView: View {
    let activity: LoadingActivity
    let cornerRadius: CGFloat = 18

    init(activity: LoadingActivity) {
        self.activity = activity
    }

    init(message: String) {
        self.activity = LoadingActivity(
            title: message,
            detail: "",
            note: "",
            completed: 0,
            total: 0,
            recent: []
        )
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 16) {
                    progressDisc

                    VStack(alignment: .leading, spacing: 4) {
                        Text(activity.title)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)

                        if activity.total > 0 {
                            Text("\(activity.completed) of \(activity.total)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)
                                .contentTransition(.numericText())
                        }
                    }

                    Spacer(minLength: 0)
                }

                if !activity.detail.isEmpty {
                    Text(activity.detail)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(2)
                        .id(activity.detail)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }

                if !activity.note.isEmpty {
                    Text(activity.note)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                        .id(activity.note)
                        .transition(.opacity)
                }

                progressBar

                if !activity.recent.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(activity.recent.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary.opacity(index == activity.recent.count - 1 ? 1 : 0.55))
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 460, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.cardFill.opacity(0.98))
                    .shadow(color: Color.black.opacity(0.35), radius: 22, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
            .padding(36)
            .animation(.snappy(duration: 0.28), value: activity)
        }
    }

    private var progressDisc: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let turn = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.4) / 2.4
            ZStack {
                Circle()
                    .stroke(AppTheme.lightGray.opacity(0.7), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: activity.total > 0 ? activity.fraction : 0.22)
                    .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(activity.total > 0 ? -90 : turn * 360))
            }
            .frame(width: 54, height: 54)
        }
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            let width = activity.total > 0 ? geometry.size.width * activity.fraction : geometry.size.width * 0.18
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.lightGray.opacity(0.45))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentSecondary, AppTheme.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(width, 12))
            }
        }
        .frame(height: 7)
    }
}
