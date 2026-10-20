import SwiftUI

struct FolderCompletionMenu: View {
    let folderURL: URL
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Success icon and message
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.accent)

                    Text("Smart Place Complete!")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("New artist folders have been created")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.top, 20)

                // Folder information
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppTheme.lightGray)
                                .frame(width: 56, height: 56)
                            Image(systemName: "folder.fill")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(folderURL.lastPathComponent)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text(folderURL.path)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineLimit(2)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(AppTheme.rowFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
                    }
                }

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showInFinder()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "folder.badge.gearshape")
                                .font(.headline)
                            Text("Show in Finder")
                                .font(.headline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.accent)
                        .foregroundStyle(AppTheme.textPrimary)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .help("Open Finder with the folder selected")

                    Button(action: {
                        dismiss()
                        onDismiss()
                    }) {
                        Text("Done")
                            .font(.headline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.rowFill)
                            .foregroundStyle(AppTheme.textPrimary)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 20)
            }
            .padding(24)
            .foregroundStyle(AppTheme.textPrimary)
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .frame(width: 400, height: 380)
    }

    private func showInFinder() {
        #if os(macOS)
        NSWorkspace.shared.activateFileViewerSelecting([folderURL])
        #endif
        dismiss()
        onDismiss()
    }
}
