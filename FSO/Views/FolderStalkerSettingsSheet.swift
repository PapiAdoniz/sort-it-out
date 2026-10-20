import SwiftUI

enum SongTitleColor: CaseIterable {
    case white
    case cyan
    case green
    case yellow
    case orange
    case pink
    case purple
    case red

    var color: Color {
        switch self {
        case .white: return .white
        case .cyan: return .cyan
        case .green: return .green
        case .yellow: return .yellow
        case .orange: return .orange
        case .pink: return .pink
        case .purple: return .purple
        case .red: return .red
        }
    }

    var name: String {
        switch self {
        case .white: return "White"
        case .cyan: return "Cyan"
        case .green: return "Green"
        case .yellow: return "Yellow"
        case .orange: return "Orange"
        case .pink: return "Pink"
        case .purple: return "Purple"
        case .red: return "Red"
        }
    }
}

struct FolderStalkerSettingsSheet: View {
    @Binding var trackedFolders: [URL]
    let onAddFolder: () -> Void
    let onRemoveFolder: (URL) -> Void
    let displayMode: FolderStalkerDisplayMode
    let onDisplayModeChange: (FolderStalkerDisplayMode) -> Void
    @Binding var songTitleColor: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    infoSection
                    displayModeSection

                    if trackedFolders.isEmpty {
                        emptyState
                    } else {
                        foldersList
                    }

                    songTitleColorSection
                }
                .padding(20)
                .foregroundStyle(AppTheme.textPrimary)
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Manage Folders")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
        .tint(AppTheme.textPrimary)
        .preferredColorScheme(.dark)
        .frame(minWidth: 500, minHeight: 400)
    }

    private var infoSection: some View {
        ModernCard(title: "About", systemImage: "info.circle") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Add folders you want to stalk and monitor their music files.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Folders are saved and will persist when you reopen the app.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    private var displayModeSection: some View {
        ModernCard(title: "Display Mode", systemImage: "list.bullet") {
            EmptyView()
        } content: {
            VStack(spacing: 8) {
                ForEach(FolderStalkerDisplayMode.allCases, id: \.self) { mode in
                    Button {
                        onDisplayModeChange(mode)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: displayMode == mode ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(displayMode == mode ? AppTheme.accent : AppTheme.textSecondary)

                            Text(mode.rawValue)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.textPrimary)

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(displayMode == mode ? AppTheme.accent.opacity(0.15) : AppTheme.rowFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var songTitleColorSection: some View {
        ModernCard(title: "Song Title Color", systemImage: "paintbrush.fill") {
            EmptyView()
        } content: {
            VStack(spacing: 12) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                    ForEach(SongTitleColor.allCases, id: \.self) { colorOption in
                        Button {
                            songTitleColor = colorOption.color
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(colorOption.color)
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        Circle()
                                            .strokeBorder(
                                                songTitleColor == colorOption.color ? Color.white : Color.clear,
                                                lineWidth: 3
                                            )
                                    }
                                    .shadow(color: songTitleColor == colorOption.color ? colorOption.color.opacity(0.5) : Color.black.opacity(0.2), radius: 8)

                                if songTitleColor == colorOption.color {
                                    Image(systemName: "checkmark")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(.white)
                                        .shadow(color: .black, radius: 2)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .help(colorOption.name)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.textSecondary)

            Text("No folders being stalked")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textPrimary)

            Button(action: onAddFolder) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add First Folder")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.accent)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var foldersList: some View {
        ModernCard(title: "Tracked Folders", systemImage: "folder.fill") {
            Button(action: onAddFolder) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Folder")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.accent)
            }
            .buttonStyle(.plain)
        } content: {
            VStack(spacing: 8) {
                ForEach(trackedFolders, id: \.self) { folder in
                    folderRow(folder)
                }
            }
        }
    }

    private func folderRow(_ folder: URL) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.lightGray)
                    .frame(width: 44, height: 44)
                Image(systemName: "folder.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(folder.lastPathComponent)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(folder.path)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Button {
                onRemoveFolder(folder)
            } label: {
                Image(systemName: "trash")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.lightGray, in: Circle())
            }
            .buttonStyle(.plain)
            .help("Remove folder from stalking")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.rowFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
