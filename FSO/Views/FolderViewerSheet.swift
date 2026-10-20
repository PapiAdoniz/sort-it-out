import SwiftUI

struct FolderViewerSheet: View {
    @Binding var trackedFolders: [URL]
    let selectedFolderURL: URL?
    @Binding var selectedFolderFiles: [ScannedFile]
    let onSelectFolder: (URL) -> Void
    let onAddFolder: () -> Void
    let onRemoveFolder: (URL) -> Void
    let onDisplayModeChange: (FolderStalkerDisplayMode) -> Void
    var audioPreview: AudioPreviewManager
    let isLoadingFolderFiles: Bool
    let displayMode: FolderStalkerDisplayMode
    @Binding var songTitleColor: Color
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFolder: URL?
    @State private var localFiles: [ScannedFile] = []
    @State private var showSettingsSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                mainScrollView

                VStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        closeButtonContent
                    }
                    .buttonStyle(.plain)
                    .help("Close")

                    if !trackedFolders.isEmpty {
                        Button(action: { showSettingsSheet = true }) {
                            settingsButtonContent
                        }
                        .buttonStyle(.plain)
                        .help("Manage tracked folders")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(30)

                if isLoadingFolderFiles {
                    LoadingOverlayView(message: "Loading music files…")
                }
            }
        }
        .tint(.clear)
        .preferredColorScheme(.dark)
        .frame(minWidth: 900, idealWidth: 1000)
        .onAppear {
            selectedFolder = selectedFolderURL
            localFiles = selectedFolderFiles
        }
        .onChange(of: selectedFolderFiles) { _, newFiles in
            localFiles = newFiles
        }
        .onChange(of: selectedFolderURL) { _, newURL in
            selectedFolder = newURL
        }
        .sheet(isPresented: $showSettingsSheet) {
            FolderStalkerSettingsSheet(
                trackedFolders: $trackedFolders,
                onAddFolder: onAddFolder,
                onRemoveFolder: onRemoveFolder,
                displayMode: displayMode,
                onDisplayModeChange: onDisplayModeChange,
                songTitleColor: $songTitleColor
            )
        }
    }

    private var artistsReady: Bool {
        !localFiles.isEmpty && localFiles.allSatisfy { !$0.artist.isEmpty }
    }

    private var songLines: [FolderStalkerLine] {
        guard displayMode == .byArtist, artistsReady else {
            return localFiles.map { .file($0) }
        }

        let grouped = Dictionary(grouping: localFiles, by: \.artist)
        return grouped.keys.sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }.flatMap { artist in
            let files = grouped[artist] ?? []
            let header = FolderStalkerLine.header(artist, files.first?.url.deletingLastPathComponent())
            return [header] + files.map { FolderStalkerLine.file($0) }
        }
    }

    private var mainScrollView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                if trackedFolders.isEmpty {
                    emptyFoldersState
                } else {
                    folderListSection

                    if selectedFolder ?? selectedFolderURL != nil {
                        songList
                    } else {
                        selectFolderPrompt
                    }
                }
            }
            .padding(20)
            .foregroundStyle(AppTheme.textPrimary)
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Folder Stalker")
    }

    @ViewBuilder
    private var songList: some View {
        if localFiles.isEmpty {
            emptySongsState
        } else {
            if displayMode == .byArtist, !artistsReady {
                Text("Reading artists…")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            ForEach(songLines) { line in
                switch line {
                case .header(let artist, let folder):
                    artistHeader(artist, folder: folder)
                case .file(let file):
                    fileRow(file)
                }
            }
        }
    }

    private func artistHeader(_ artist: String, folder: URL?) -> some View {
        HStack(spacing: 8) {
            Text(artist)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
            if let folder {
                Button {
                    #if os(macOS)
                    NSWorkspace.shared.activateFileViewerSelecting([folder])
                    #endif
                } label: {
                    Image(systemName: "folder")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Show folder")
            }
        }
        .padding(.top, 12)
    }

    private var closeButtonContent: some View {
        Image(systemName: "xmark.circle.fill")
            .font(.title2)
            .foregroundStyle(AppTheme.textPrimary)
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.lightGray.opacity(0.7),
                                AppTheme.lightGray.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
            .shadow(color: Color.white.opacity(0.12), radius: 6, x: -2, y: -2)
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 2, y: 2)
    }

    private var settingsButtonContent: some View {
        Image(systemName: "gear")
            .font(.title2)
            .foregroundStyle(AppTheme.textPrimary)
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.lightGray.opacity(0.7),
                                AppTheme.lightGray.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
            .shadow(color: Color.white.opacity(0.12), radius: 6, x: -2, y: -2)
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 2, y: 2)
    }

    private var emptyFoldersState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textSecondary)

            Text("No folders being stalked")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Add folders to stalk and monitor their music files.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: {
                showSettingsSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Add First Folder")
                        .font(.headline.weight(.semibold))
                }
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.lightGray.opacity(0.7),
                                    AppTheme.lightGray.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
                .shadow(color: Color.white.opacity(0.12), radius: 6, x: -2, y: -2)
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 2, y: 2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var folderListSection: some View {
        ModernCard(title: "Tracked Folders", systemImage: "folder.fill") {
            EmptyView()
        } content: {
            VStack(spacing: 8) {
                ForEach(trackedFolders, id: \.self) { folder in
                    folderListItem(folder)
                }
            }
        }
    }

    private var selectFolderPrompt: some View {
        ModernCard(title: "Songs", systemImage: "music.note") {
            EmptyView()
        } content: {
            VStack(spacing: 12) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 32))
                    .foregroundStyle(AppTheme.textSecondary)

                Text("Select a folder to view its music files")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    private func folderListItem(_ folder: URL) -> some View {
        Button {
            selectedFolder = folder
            onSelectFolder(folder)
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.lightGray)
                        .frame(width: 32, height: 32)
                    Image(systemName: "folder.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(folder.lastPathComponent)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    Text(folder.path)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer(minLength: 0)

                if selectedFolder?.standardizedFileURL == folder.standardizedFileURL ||
                   selectedFolderURL?.standardizedFileURL == folder.standardizedFileURL {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                (selectedFolder?.standardizedFileURL == folder.standardizedFileURL ||
                 selectedFolderURL?.standardizedFileURL == folder.standardizedFileURL)
                ? AppTheme.accent.opacity(0.2)
                : AppTheme.rowFill,
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private var emptySongsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.house")
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.textSecondary)

            Text("No music files found")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textPrimary)

            Text("This folder doesn't contain any supported audio files.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func fileRow(_ file: ScannedFile) -> some View {
        FolderStalkerFileRow(
            file: file,
            titleColor: songTitleColor,
            audioPreview: audioPreview
        )
    }
}

private enum FolderStalkerLine: Identifiable {
    case header(String, URL?)
    case file(ScannedFile)

    var id: String {
        switch self {
        case .header(let artist, _):
            return "header-\(artist)"
        case .file(let file):
            return file.url.path
        }
    }
}

private struct FolderStalkerFileRow: View {
    let file: ScannedFile
    let titleColor: Color
    var audioPreview: AudioPreviewManager

    private var isPlayingThisFile: Bool {
        audioPreview.currentPreviewURL == file.url && audioPreview.isPlaying
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(file.fileName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(titleColor)
                    .lineLimit(1)

                if !file.artist.isEmpty {
                    Text(file.artist)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button {
                    audioPreview.playPreview(url: file.url)
                } label: {
                    Image(systemName: isPlayingThisFile ? "pause.fill" : "play.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isPlayingThisFile ? AppTheme.accent : AppTheme.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.lightGray, in: Circle())
                }
                .buttonStyle(.plain)
                .help(isPlayingThisFile ? "Pause" : "Play")

                Button {
                    #if os(macOS)
                    NSWorkspace.shared.activateFileViewerSelecting([file.url])
                    #endif
                } label: {
                    Image(systemName: "folder")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.lightGray, in: Circle())
                }
                .buttonStyle(.plain)
                .help("Show in Finder")

                FormatBadge(label: file.formatLabel, quality: nil)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.rowFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
