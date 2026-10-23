import SwiftUI

struct SmartPlaceReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let lines: [String]
    let onMove: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("These songs will move into your library. Nothing moves until you confirm.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(lines, id: \.self) { line in
                            Text(line)
                                .font(.body)
                                .foregroundStyle(AppTheme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AppTheme.rowFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }

                HStack {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)

                    Spacer()

                    Button("Move Songs") {
                        onMove()
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(20)
            .navigationTitle("Review Smart Place")
        }
        .tint(AppTheme.textPrimary)
        .preferredColorScheme(.dark)
        .frame(minWidth: 460, minHeight: 320)
    }
}
