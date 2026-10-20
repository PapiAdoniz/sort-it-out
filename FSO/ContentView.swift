import SwiftUI

struct ContentView: View {
    @State private var viewModel = OrganizerViewModel()
    @State private var audioPreview = AudioPreviewManager()
    @State private var showThemePicker = false
    @AppStorage(AppTheme.themeKey) private var selectedThemeRawValue = AppTheme.defaultTheme.rawValue

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        actionSection
                        sourcesSection

                        if viewModel.isScanning || viewModel.isOrganizing {
                            progressSection
                        }

                        if !viewModel.artistGroups.isEmpty {
                            previewSection
                        }
                    }
                    .padding(24)
                    .foregroundStyle(AppTheme.textPrimary)
                }
                .scrollContentBackground(.hidden)
            }
            .overlay {
                if viewModel.isScanning || viewModel.isOrganizing {
                    LoadingOverlayView(activity: viewModel.loadingActivity)
                }
            }
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 10) {
                    themeMenu

                    Button(action: {
                        viewModel.showHelpSheet = true
                    }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.rowFill, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help("How to use")
                }
                .padding(20)
            }
            .overlay(alignment: .top) {
                if let completionMessage = viewModel.completionMessage {
                    CompletionBannerView(message: completionMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: completionMessage)
                }
            }
            .onChange(of: audioPreview.currentPreviewURL) { _, url in
                // Preview functionality
            }
            .navigationTitle("Sort It Out")
            .toolbarColorScheme(.dark, for: .windowToolbar)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $viewModel.showScanResultsSheet) {
                if let summary = viewModel.scanFormatSummary {
                    ScanResultsSheet(
                        files: viewModel.scannedFiles,
                        sourceGroups: viewModel.scannedSourceGroups,
                        summary: summary
                    )
                }
            }
            .sheet(isPresented: $viewModel.showFileInspectorSheet) {
                FileInspectorSheet(
                    files: viewModel.scannedFiles,
                    qualitySortOrder: $viewModel.qualitySortOrder,
                    audioPreview: audioPreview
                )
            }
            .sheet(isPresented: $viewModel.showFolderCompletionMenu) {
                if let folderURL = viewModel.completedFolderURL {
                    FolderCompletionMenu(folderURL: folderURL) {
                        viewModel.showFolderCompletionMenu = false
                    }
                }
            }
            .sheet(isPresented: $viewModel.showFolderViewerSheet) {
                FolderViewerSheet(
                    trackedFolders: $viewModel.trackedFolders,
                    selectedFolderURL: viewModel.selectedFolderURL,
                    selectedFolderFiles: $viewModel.selectedFolderFiles,
                    onSelectFolder: { url in
                        viewModel.selectFolder(url)
                    },
                    onAddFolder: {
                        viewModel.addTrackedFolder()
                    },
                    onRemoveFolder: { url in
                        viewModel.removeTrackedFolder(url)
                    },
                    onDisplayModeChange: { mode in
                        viewModel.setFolderStalkerDisplayMode(mode)
                    },
                    audioPreview: audioPreview,
                    isLoadingFolderFiles: viewModel.isLoadingFolderFiles,
                    displayMode: viewModel.folderStalkerDisplayMode,
                    songTitleColor: $viewModel.songTitleColor
                )
                .onAppear {
                    viewModel.refreshFolderStalker()
                }
            }
            .sheet(isPresented: $viewModel.showFolderStalkerSettings) {
                FolderStalkerSettingsSheet(
                    trackedFolders: $viewModel.trackedFolders,
                    onAddFolder: {
                        viewModel.addTrackedFolder()
                    },
                    onRemoveFolder: { url in
                        viewModel.removeTrackedFolder(url)
                    },
                    displayMode: viewModel.folderStalkerDisplayMode,
                    onDisplayModeChange: { mode in
                        viewModel.setFolderStalkerDisplayMode(mode)
                    },
                    songTitleColor: $viewModel.songTitleColor
                )
            }
        }
        .tint(AppTheme.textPrimary)
        .preferredColorScheme(.dark)
        .coordinateSpace(name: "root")
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 520)
        #endif
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let travel = (sin(timeline.date.timeIntervalSinceReferenceDate * 0.6) + 1) / 2
                let colors = selectedTheme.colors
                Text("Sort It Out")
                    .font(.custom("Avenir Next", size: 30))
                    .fontWeight(.medium)
                    .tracking(1.4)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [colors.accentSecondary, colors.glow, colors.accent],
                            startPoint: UnitPoint(x: travel - 0.4, y: 0),
                            endPoint: UnitPoint(x: travel + 0.7, y: 1)
                        )
                    )
                    .shadow(color: colors.accent.opacity(0.18 + travel * 0.28), radius: 6 + travel * 8, y: 0)
            }

            StatusPill(text: viewModel.statusMessage)
        }
    }

    private var themeMenu: some View {
        Button {
            showThemePicker.toggle()
        } label: {
            Image(systemName: "paintbrush.pointed.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: 44, height: 44)
                .background(AppTheme.rowFill, in: Circle())
        }
        .buttonStyle(.plain)
        .help("Change theme")
        .popover(isPresented: $showThemePicker, arrowEdge: .top) {
            ThemePickerPopover(
                selectedTheme: selectedTheme,
                onSelect: { theme in
                    selectedThemeRawValue = theme.rawValue
                }
            )
        }
    }

    private var selectedTheme: AppColorTheme {
        AppColorTheme(rawValue: selectedThemeRawValue) ?? AppTheme.defaultTheme
    }

    private var actionSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button(action: {
                    viewModel.showSettingsSheet = true
                }) {
                    Image(systemName: "gear")
                        .font(.title3)
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.rowFill, in: Circle())
                }
                .buttonStyle(.plain)
                .help("Smart Place settings")

                prominentDarkButton("Smart Place", systemImage: "wand.and.stars", isDisabled: viewModel.isScanning || viewModel.isOrganizing || !viewModel.smartPlaceReady) {
                    Task { await viewModel.smartPlace() }
                }
                .help("Move new music from watch folder to artist folders in library")
            }

            HStack(spacing: 10) {
                darkButton("Add", systemImage: "plus.circle.fill") {
                    viewModel.addFolders()
                }
                .help("Select multiple folders or music files at once. ⌘-click items in the same folder.")

                darkButton("Scan", systemImage: "magnifyingglass", isDisabled: !viewModel.canScan) {
                    Task { await viewModel.scan() }
                }
                .help("Scan music files for artist information")
            }

            if viewModel.canViewScanResults {
                darkButton(scanResultsButtonTitle, systemImage: "list.bullet.rectangle") {
                    viewModel.showScanResultsSheet = true
                }
            }

            if !viewModel.scannedFiles.isEmpty {
                darkButton("File Inspector", systemImage: "doc.text.magnifyingglass") {
                    viewModel.showFileInspectorSheet = true
                }
                .help("Inspect files with quality sorting and preview")
            }

            darkButton("Folder Stalker", systemImage: "folder.badge.gearshape") {
                viewModel.showFolderViewerSheet = true
            }
            .help("View and manage folders to stalk")
        }
        .sheet(isPresented: $viewModel.showSettingsSheet) {
            SettingsSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showHelpSheet) {
            HelpSheet()
        }
        .sheet(isPresented: $viewModel.showSmartPlaceSelectionSheet) {
            SmartPlaceSelectionSheet(
                artistChoices: viewModel.smartPlaceAmbiguities.map { ambiguity in
                    SmartPlaceSelectionSheet.ArtistChoice(
                        artist: ambiguity.artist,
                        songTitles: viewModel.smartPlaceArtistSongTitles[ambiguity.artist] ?? [],
                        existingFolders: ambiguity.matchingFolders,
                        isUnknown: ambiguity.isUnknown
                    )
                },
                duplicates: viewModel.smartPlaceDuplicates.map { duplicate in
                    SmartPlaceSelectionSheet.DuplicateConflict(
                        sourceURL: duplicate.sourceURL,
                        destinationURL: duplicate.destinationURL,
                        artist: duplicate.artist,
                        fileName: duplicate.fileName
                    )
                },
                onProceed: { selections, duplicateChoices in
                    viewModel.handleSmartPlaceSelections(selections, duplicateChoices)
                }
            )
        }
    }

    private func darkButton(_ title: String, systemImage: String, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        GlowingButton(content: {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
                .foregroundStyle(AppTheme.textPrimary)
        }, action: action, isDisabled: isDisabled)
        .buttonStyle(DarkButtonStyle(isProminent: false))
        .controlSize(.large)
    }

    private func prominentDarkButton(_ title: String, systemImage: String, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        GlowingButton(content: {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
                .foregroundStyle(AppTheme.textPrimary)
        }, action: action, isDisabled: isDisabled)
        .buttonStyle(DarkButtonStyle(isProminent: true))
        .controlSize(.large)
    }

    private var scanResultsButtonTitle: String {
        if let summary = viewModel.scanFormatSummary {
            return "View Scan · \(summary.headline)"
        }
        return "View Scan Results"
    }

    private var sourcesSection: some View {
        ModernCard(title: "Sources", systemImage: "folder.badge.plus") {
            if viewModel.canClearSourceFolders {
                GlowingSubtleButton(content: {
                    Label("Clear All", systemImage: "xmark.circle")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.textPrimary)
                }, action: {
                    audioPreview.stopPreview()
                    viewModel.clearSourceFolders()
                }, isDisabled: !viewModel.canClearSourceFolders)
                .buttonStyle(SubtleButtonStyle())
                .help("Remove all sources from this session. Your music files are not changed.")
            }
        } content: {
            if viewModel.sources.isEmpty {
                emptySourcesState
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.sources) { source in
                        sourceRow(source)
                    }
                }
            }
        }
    }

    private var emptySourcesState: some View {
        VStack(spacing: 10) {
            Image(systemName: "music.note.house")
                .font(.system(size: 28))
                .foregroundStyle(AppTheme.textSecondary)

            Text("No sources yet")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Add folders or individual tracks to begin.")
                .font(.caption)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func sourceRow(_ source: SourceEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if !source.isFolder {
                    previewButton(for: source.url)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.lightGray)
                        .frame(width: 36, height: 36)

                    Image(systemName: source.isFolder ? "folder.fill" : "music.note")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(source.url.lastPathComponent)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    Text(source.isFolder ? folderSummary(source) : source.url.deletingLastPathComponent().path)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer(minLength: 0)

                if !source.isFolder {
                    FormatBadge(
                        label: MusicMetadataReader.formatLabel(for: source.url),
                        quality: MusicMetadataReader.qualityLabel(for: source.url)
                    )
                }

                Button {
                    audioPreview.stopPreview()
                    viewModel.removeSource(source)
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 24, height: 24)
                        .background(AppTheme.lightGray, in: Circle())
                }
                .buttonStyle(.plain)
                .help("Remove this source")
            }

            if source.isFolder {
                folderContents(source)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .themedRowBackground(cornerRadius: 12)
    }

    private func folderSummary(_ source: SourceEntry) -> String {
        if viewModel.loadingSourceIDs.contains(source.id) {
            return "Looking through folders…"
        }
        let count = viewModel.folderContents[source.id]?.count ?? 0
        if count == 0 {
            return "No music files inside"
        }
        return "\(count) song\(count == 1 ? "" : "s") inside"
    }

    @ViewBuilder
    private func folderContents(_ source: SourceEntry) -> some View {
        if viewModel.loadingSourceIDs.contains(source.id) {
            EmptyView()
        } else if let files = viewModel.folderContents[source.id], !files.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(nestedGroups(files, in: source.url)) { group in
                    VStack(alignment: .leading, spacing: 4) {
                        if group.name != "In this folder" {
                            Text(group.name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)
                                .lineLimit(1)
                                .padding(.leading, 28)
                        }

                        ForEach(group.files, id: \.self) { file in
                            HStack(spacing: 8) {
                                previewButton(for: file, compact: true)

                                Text(file.deletingPathExtension().lastPathComponent)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .lineLimit(1)

                                Spacer(minLength: 0)

                                Text(MusicMetadataReader.formatLabel(for: file))
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .padding(.leading, group.name == "In this folder" ? 8 : 28)
                        }
                    }
                }
            }
        }
    }

    private func nestedGroups(_ files: [URL], in folder: URL) -> [SourceNestedGroup] {
        let root = folder.standardizedFileURL
        let rootPath = root.path.hasSuffix("/") ? root.path : root.path + "/"
        let grouped = Dictionary(grouping: files) { file -> String in
            let parent = file.deletingLastPathComponent().standardizedFileURL
            if parent == root {
                return ""
            }
            let parentPath = parent.path
            if parentPath.hasPrefix(rootPath) {
                return String(parentPath.dropFirst(rootPath.count))
            }
            return parent.lastPathComponent
        }

        return grouped.keys.sorted { lhs, rhs in
            if lhs.isEmpty { return !rhs.isEmpty }
            if rhs.isEmpty { return false }
            return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }.map { key in
            let name = key.isEmpty ? "In this folder" : key
            let sortedFiles = (grouped[key] ?? []).sorted {
                $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
            }
            return SourceNestedGroup(id: name, name: name, files: sortedFiles)
        }
    }

    private func previewButton(for url: URL, compact: Bool = false) -> some View {
        let side: CGFloat = compact ? 20 : 24
        return Button {
            audioPreview.playPreview(url: url)
        } label: {
            Image(systemName: audioPreview.currentPreviewURL == url && audioPreview.isPlaying ? "pause.fill" : "play.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: side, height: side)
                .background(AppTheme.lightGray.opacity(0.45), in: Circle())
        }
        .buttonStyle(.plain)
        .help("Preview audio file")
    }

    private var progressSection: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
                .tint(AppTheme.textPrimary)
            Text(viewModel.isScanning ? "Scanning your library…" : "Organizing files by artist…")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .themedRowBackground(cornerRadius: 14)
    }

    private var previewSection: some View {
        ModernCard(
            title: "Preview · \(viewModel.totalFileCount) files",
            systemImage: "music.note.list"
        ) {
            if viewModel.canViewScanResults {
                GlowingSubtleButton(content: {
                    Text("Details")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.textPrimary)
                }, action: {
                    viewModel.showScanResultsSheet = true
                }, isDisabled: !viewModel.canViewScanResults)
                .buttonStyle(SubtleButtonStyle())
            }
        } content: {
            VStack(spacing: 8) {
                ForEach(viewModel.artistGroups) { group in
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(group.files) { plan in
                                HStack(alignment: .top, spacing: 8) {
                                    Button {
                                        audioPreview.playPreview(url: plan.sourceURL)
                                    } label: {
                                        Image(systemName: audioPreview.currentPreviewURL == plan.sourceURL && audioPreview.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(AppTheme.textPrimary)
                                            .frame(width: 20, height: 20)
                                            .background(AppTheme.lightGray.opacity(0.4), in: Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .help("Preview audio file")

                                    Image(systemName: "doc.audio")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.textSecondary)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(plan.sourceURL.lastPathComponent)
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textPrimary)
                                            .lineLimit(1)

                                        Text("Send to: \(plan.destinationURL.path)")
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.textSecondary)
                                            .lineLimit(nil)
                                    }
                                    Spacer(minLength: 0)
                                    FormatBadge(
                                        label: MusicMetadataReader.formatLabel(for: plan.sourceURL),
                                        quality: MusicMetadataReader.qualityLabel(for: plan.sourceURL)
                                    )
                                }
                            }
                        }
                        .padding(.top, 4)
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.lightGray)
                                    .frame(width: 30, height: 30)
                                Image(systemName: "person.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)
                            }

                            Text(group.artist)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.textPrimary)

                            Spacer(minLength: 0)

                            CountBadge(count: group.files.count)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .themedRowBackground(cornerRadius: 12)
                }
            }
        }
    }

}

private struct SourceNestedGroup: Identifiable {
    let id: String
    let name: String
    let files: [URL]
}

struct DarkButtonStyle: ButtonStyle {
    let isProminent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                (isProminent ? AppTheme.buttonFillProminent : AppTheme.buttonFill).opacity(0.92),
                                (isProminent ? AppTheme.buttonFillProminent : AppTheme.buttonFill).opacity(0.78)
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
            .offset(y: configuration.isPressed ? 2 : 0)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct SubtleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.buttonFill.opacity(0.80),
                                AppTheme.buttonFill.opacity(0.65)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 3)
            .shadow(color: Color.white.opacity(0.1), radius: 4, x: -1, y: -1)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 1, y: 1)
            .offset(y: configuration.isPressed ? 1 : 0)
            .opacity(configuration.isPressed ? 0.75 : 0.95)
    }
}

private struct ThemePickerPopover: View {
    let selectedTheme: AppColorTheme
    let onSelect: (AppColorTheme) -> Void
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 92, maximum: 112), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Themes")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer(minLength: 0)

                Text("\(AppColorTheme.allCases.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.pillFill, in: Capsule())
            }

            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    ForEach(AppColorTheme.allCases) { theme in
                        themeButton(theme)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(height: 340)
        }
        .padding(14)
        .frame(width: 440)
        .background(AppTheme.backgroundGradient)
        .preferredColorScheme(.dark)
    }

    private func themeButton(_ theme: AppColorTheme) -> some View {
        let colors = AppTheme.colors(for: theme)
        let isSelected = selectedTheme == theme

        return Button {
            onSelect(theme)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    colors.black,
                                    colors.accentSecondary.opacity(0.78),
                                    colors.accent.opacity(0.92),
                                    colors.glow.opacity(0.75)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 42)
                        .overlay(alignment: .bottomLeading) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(colors.accent)
                                    .frame(width: 8, height: 8)
                                Circle()
                                    .fill(colors.accentSecondary)
                                    .frame(width: 8, height: 8)
                                Circle()
                                    .fill(colors.glow)
                                    .frame(width: 8, height: 8)
                            }
                            .padding(6)
                        }

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(5)
                    }
                }

                HStack(spacing: 5) {
                    Image(systemName: theme.icon)
                        .font(.caption2)
                        .foregroundStyle(colors.accent)
                    Text(theme.rawValue)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading)
            .background(AppTheme.rowFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? colors.accent : AppTheme.cardStroke, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct GlowingButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    let isDisabled: Bool
    @State private var isHovering = false

    init(@ViewBuilder content: () -> Content, action: @escaping () -> Void, isDisabled: Bool = false) {
        self.content = content()
        self.action = action
        self.isDisabled = isDisabled
    }

    var body: some View {
        Button(action: action) {
            content
        }
        .disabled(isDisabled)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.accent.opacity(0.18))
                .blur(radius: 12)
                .opacity(isHovering && !isDisabled ? 1 : 0)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

struct GlowingSubtleButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    let isDisabled: Bool
    @State private var isHovering = false

    init(@ViewBuilder content: () -> Content, action: @escaping () -> Void, isDisabled: Bool = false) {
        self.content = content()
        self.action = action
        self.isDisabled = isDisabled
    }

    var body: some View {
        Button(action: action) {
            content
        }
        .disabled(isDisabled)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.accent.opacity(0.14))
                .blur(radius: 10)
                .opacity(isHovering && !isDisabled ? 1 : 0)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    ContentView()
}
