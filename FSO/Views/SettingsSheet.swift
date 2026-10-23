import SwiftUI

struct SettingsSheet: View {
    @Bindable var viewModel: OrganizerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    watchFolderSection
                    libraryFolderSection
                    behaviorSection
                }
                .padding(20)
            }
            .foregroundStyle(AppTheme.textPrimary)
            .navigationTitle("Smart Place Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
        .tint(AppTheme.textPrimary)
        .preferredColorScheme(.dark)
        .frame(minWidth: 520, minHeight: 400)
    }

    private var watchFolderSection: some View {
        ModernCard(title: "Watch Folder", systemImage: "tray.and.arrow.down") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 12) {
                Text("Where your new music downloads land (e.g., Downloads folder)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)

                if let watchFolder = viewModel.smartWatchFolder {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(AppTheme.accent)
                        Text(watchFolder.path)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button(action: {
                            viewModel.clearWatchFolder()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.rowFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Button("Select Watch Folder") {
                    viewModel.selectWatchFolder()
                }
                .buttonStyle(SubtleButtonStyle())
            }
        }
    }

    private var libraryFolderSection: some View {
        ModernCard(title: "Library Folder", systemImage: "music.note.list") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 12) {
                Text("Where Smart Place organizes music into artist folders")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)

                if let libraryFolder = viewModel.smartDestinationFolder {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(AppTheme.accent)
                        Text(libraryFolder.path)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button(action: {
                            viewModel.clearLibraryFolder()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.rowFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Button("Select Library Folder") {
                    viewModel.selectLibraryFolder()
                }
                .buttonStyle(SubtleButtonStyle())
            }
        }
    }

    private var behaviorSection: some View {
        ModernCard(title: "Sorting", systemImage: "slider.horizontal.3") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 12) {
                Text("Smart Place puts a download in the folder of the artist the album belongs to. A featured artist on a few songs stays inside that folder. A song tagged with both names follows the artist most of the album belongs to.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Folder structure")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Pick where those songs go inside the artist folder.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)

                    ForEach(SmartPlaceFolderMode.allCases) { mode in
                        Button {
                            viewModel.setSmartPlaceFolderMode(mode)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: viewModel.smartPlaceFolderMode == mode ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(viewModel.smartPlaceFolderMode == mode ? AppTheme.accent : AppTheme.textSecondary)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(mode.rawValue)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text(mode.description)
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }

                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.smartPlaceFolderMode == mode ? AppTheme.accent.opacity(0.12) : AppTheme.rowFill,
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
