import Foundation
import Observation
import SwiftUI

enum FolderStalkerDisplayMode: String, CaseIterable {
    case allTogether = "All Together"
    case byArtist = "By Artist"
}

#if os(macOS)
import AppKit
#else
import UIKit
import UniformTypeIdentifiers
#endif

enum QualitySortOrder: String, CaseIterable {
    case descending = "Highest First"
    case ascending = "Lowest First"
}

enum SmartPlaceFolderMode: String, CaseIterable, Identifiable {
    case artistOnly = "Artist Folders"
    case artistAlbum = "Artist / Album Folders"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .artistOnly:
            return "Every song goes to Artist/song.ext, in one folder for that artist."
        case .artistAlbum:
            return "A song goes to Artist/Album/song.ext from its album name, even when it is the only one. A song filed with those tracks joins that album folder."
        }
    }
}

@Observable
@MainActor
final class OrganizerViewModel {
    init() {
        loadSmartPlaceFolders()
        Task {
            loadTrackedFolders()
        }
    }

    private(set) var sources: [SourceEntry] = []
    private(set) var folderContents: [URL: [URL]] = [:]
    private(set) var loadingSourceIDs: Set<URL> = []
    private(set) var artistGroups: [ArtistGroup] = []
    private(set) var scannedFiles: [ScannedFile] = []
    private(set) var scannedSourceGroups: [SourceScanGroup] = []
    private(set) var scanFormatSummary: ScanFormatSummary?
    private(set) var statusMessage = "Select one or more folders or music files."

    var isScanning = false
    var isOrganizing = false
    var loadingActivity = LoadingActivity.idle
    var showError = false
    var showScanResultsSheet = false
    var showFileInspectorSheet = false
    var showSettingsSheet = false
    var showHelpSheet = false
    var showSmartPlaceSelectionSheet = false
    var errorMessage = ""
    var completionMessage: String?
    var smartPlaceAmbiguities: [SmartPlaceService.ArtistAmbiguity] = []
    var smartPlacePendingPlans: [MusicFilePlan] = []
    var smartPlaceDuplicates: [SmartPlaceService.DuplicateConflict] = []
    var smartPlaceArtistSongTitles: [String: [String]] = [:]
    var qualitySortOrder: QualitySortOrder = .descending
    var showFolderCompletionMenu = false
    var completedFolderURL: URL?
    var showFolderViewerSheet = false
    var showFolderStalkerSettings = false
    var trackedFolders: [URL] = []
    var selectedFolderURL: URL?
    var selectedFolderFiles: [ScannedFile] = []
    var isLoadingFolderFiles: Bool = false
    var folderStalkerDisplayMode: FolderStalkerDisplayMode = .allTogether
    var songTitleColor: Color = .white
    private static let trackedFoldersKey = "folderStalker.trackedFolders"
    private static let displayModeKey = "folderStalker.displayMode"
    private static let songTitleColorKey = "folderStalker.songTitleColor"

    private var securityScopedURLs: [URL] = []
    private static let watchFolderKey = "smartPlace.watchFolderBookmark"
    private static let destinationFolderKey = "smartPlace.destinationFolderBookmark"
    private static let watchDisplayNameKey = "smartPlace.watchFolderDisplayName"
    private static let destinationDisplayNameKey = "smartPlace.destinationFolderDisplayName"
    private static let useAlbumFoldersKey = "smartPlace.useAlbumFolders"
    private static let folderModeKey = "smartPlace.folderMode"

    private(set) var smartWatchFolder: URL?
    private(set) var smartDestinationFolder: URL?
    var smartPlaceUsesAlbumFolders = false
    var smartPlaceFolderMode: SmartPlaceFolderMode = .artistOnly
    private var smartWatchBookmark: Data?
    private var smartDestinationBookmark: Data?

    var totalFileCount: Int {
        artistGroups.reduce(0) { $0 + $1.files.count }
    }

    var canScan: Bool {
        !sources.isEmpty && !isScanning && !isOrganizing
    }

    var canViewScanResults: Bool {
        !scannedFiles.isEmpty && !isScanning && !isOrganizing
    }

    var canClearSourceFolders: Bool {
        !sources.isEmpty && !isScanning && !isOrganizing
    }

    // MARK: Smart Place

    var hasSmartFolders: Bool {
        smartWatchFolder != nil && smartDestinationFolder != nil
    }

    var smartPlaceReady: Bool {
        smartWatchBookmark != nil && smartDestinationBookmark != nil
    }

    var smartWatchDisplayName: String {
        smartWatchFolder?.lastPathComponent
            ?? UserDefaults.standard.string(forKey: Self.watchDisplayNameKey)
            ?? "Watch folder"
    }

    var smartDestinationDisplayName: String {
        smartDestinationFolder?.lastPathComponent
            ?? UserDefaults.standard.string(forKey: Self.destinationDisplayNameKey)
            ?? "Destination folder"
    }

    func loadSmartPlaceFolders() {
        let defaults = UserDefaults.standard
        smartWatchBookmark = defaults.data(forKey: Self.watchFolderKey)
        smartDestinationBookmark = defaults.data(forKey: Self.destinationFolderKey)
        smartWatchFolder = resolveBookmark(smartWatchBookmark)
        smartDestinationFolder = resolveBookmark(smartDestinationBookmark)
        if let rawFolderMode = defaults.string(forKey: Self.folderModeKey),
           let folderMode = SmartPlaceFolderMode(rawValue: rawFolderMode) {
            smartPlaceFolderMode = folderMode
        } else {
            let usesAlbumFolders = defaults.object(forKey: Self.useAlbumFoldersKey) as? Bool ?? false
            smartPlaceFolderMode = usesAlbumFolders ? .artistAlbum : .artistOnly
        }
        smartPlaceUsesAlbumFolders = smartPlaceFolderMode == .artistAlbum
    }

    func setSmartPlaceUsesAlbumFolders(_ usesAlbumFolders: Bool) {
        setSmartPlaceFolderMode(usesAlbumFolders ? .artistAlbum : .artistOnly)
    }

    func setSmartPlaceFolderMode(_ folderMode: SmartPlaceFolderMode) {
        smartPlaceFolderMode = folderMode
        smartPlaceUsesAlbumFolders = folderMode == .artistAlbum
        UserDefaults.standard.set(folderMode.rawValue, forKey: Self.folderModeKey)
        UserDefaults.standard.set(smartPlaceUsesAlbumFolders, forKey: Self.useAlbumFoldersKey)
    }

    func loadTrackedFolders() {
        let defaults = UserDefaults.standard
        if let bookmarkData = defaults.data(forKey: Self.trackedFoldersKey),
           let bookmarks = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: bookmarkData) as? [Data] {
            trackedFolders = bookmarks.compactMap { resolveBookmark($0) }
        }

        // Load display mode
        if let displayModeString = defaults.string(forKey: Self.displayModeKey),
           let displayMode = FolderStalkerDisplayMode(rawValue: displayModeString) {
            folderStalkerDisplayMode = displayMode
        }

        // Load song title color
        if let colorName = defaults.string(forKey: Self.songTitleColorKey),
           let colorOption = SongTitleColor.allCases.first(where: { $0.name == colorName }) {
            songTitleColor = colorOption.color
        }

        // Select first folder if available
        if !trackedFolders.isEmpty {
            selectedFolderURL = trackedFolders[0]
        }
    }

    func refreshFolderStalker() {
        guard let url = selectedFolderURL else { return }
        let alreadyLoaded = selectedFolderFiles.contains {
            $0.sourceOriginURL.standardizedFileURL == url.standardizedFileURL && !$0.artist.isEmpty
        }
        guard !alreadyLoaded else { return }
        loadSelectedFolderFiles()
    }

    func setFolderStalkerDisplayMode(_ mode: FolderStalkerDisplayMode) {
        folderStalkerDisplayMode = mode
        let defaults = UserDefaults.standard
        defaults.set(mode.rawValue, forKey: Self.displayModeKey)
    }

    func setSongTitleColor(_ color: Color) {
        songTitleColor = color
        let defaults = UserDefaults.standard
        if let colorOption = SongTitleColor.allCases.first(where: { $0.color == color }) {
            defaults.set(colorOption.name, forKey: Self.songTitleColorKey)
        }
    }

    func addTrackedFolder() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder to stalk"
        panel.prompt = "Add"

        guard panel.runModal() == .OK, let folder = panel.url else { return }

        // Check if already tracked
        let standardized = folder.standardizedFileURL
        guard !trackedFolders.contains(where: { $0.standardizedFileURL == standardized }) else {
            errorMessage = "This folder is already being stalked."
            showError = true
            return
        }

        trackedFolders.append(standardized)
        saveTrackedFolders()

        // Select this folder
        selectedFolderURL = standardized
        loadSelectedFolderFiles()
        #else
        errorMessage = "Folder selection requires macOS."
        showError = true
        #endif
    }

    func removeTrackedFolder(_ url: URL) {
        trackedFolders.removeAll { $0.standardizedFileURL == url.standardizedFileURL }
        saveTrackedFolders()

        // If removing selected folder, select another
        if selectedFolderURL?.standardizedFileURL == url.standardizedFileURL {
            selectedFolderURL = trackedFolders.first
            selectedFolderFiles = []
            if let newSelection = selectedFolderURL {
                loadSelectedFolderFiles()
            }
        }
    }

    func selectFolder(_ url: URL) {
        selectedFolderURL = url
        loadSelectedFolderFiles()
    }

    private func saveTrackedFolders() {
        let bookmarks = trackedFolders.compactMap { url in
            try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
        }

        let defaults = UserDefaults.standard
        if let bookmarkData = try? NSKeyedArchiver.archivedData(withRootObject: bookmarks, requiringSecureCoding: true) {
            defaults.set(bookmarkData, forKey: Self.trackedFoldersKey)
        }
    }

    private var folderLoadID = UUID()

    private func loadSelectedFolderFiles() {
        guard let url = selectedFolderURL else { return }

        folderLoadID = UUID()
        let loadID = folderLoadID
        isLoadingFolderFiles = true
        selectedFolderFiles = []

        Task.detached(priority: .userInitiated) {
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if isAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let files = try MusicOrganizer.audioFiles(in: url, skipArtistFolders: false)
                let names = files.map { fileURL in
                    ScannedFile(
                        url: fileURL,
                        fileName: fileURL.lastPathComponent,
                        formatLabel: MusicMetadataReader.formatLabel(for: fileURL),
                        qualityLabel: nil,
                        artist: "",
                        plannedDestinationURL: fileURL,
                        sourceOriginURL: url,
                        sourceOriginName: url.lastPathComponent,
                        sourceIsFolder: true
                    )
                }.sorted {
                    $0.fileName.localizedCaseInsensitiveCompare($1.fileName) == .orderedAscending
                }

                await MainActor.run {
                    guard self.folderLoadID == loadID else { return }
                    self.selectedFolderFiles = names
                    self.isLoadingFolderFiles = false
                }

                let artists = await Self.artists(for: names.map(\.url))
                let withArtists = zip(names, artists).map { file, artist in
                    ScannedFile(
                        url: file.url,
                        fileName: file.fileName,
                        formatLabel: file.formatLabel,
                        qualityLabel: nil,
                        artist: artist,
                        plannedDestinationURL: file.plannedDestinationURL,
                        sourceOriginURL: file.sourceOriginURL,
                        sourceOriginName: file.sourceOriginName,
                        sourceIsFolder: file.sourceIsFolder
                    )
                }

                await MainActor.run {
                    guard self.folderLoadID == loadID else { return }
                    self.selectedFolderFiles = withArtists
                }
            } catch {
                await MainActor.run {
                    guard self.folderLoadID == loadID else { return }
                    self.selectedFolderFiles = []
                    self.isLoadingFolderFiles = false
                }
            }
        }
    }

    private static func artists(for fileURLs: [URL]) async -> [String] {
        guard !fileURLs.isEmpty else { return [] }

        return await withTaskGroup(of: (Int, String).self) { group in
            var nextIndex = 0
            let maxConcurrent = 6

            func enqueue() {
                guard nextIndex < fileURLs.count else { return }
                let index = nextIndex
                let fileURL = fileURLs[index]
                nextIndex += 1
                group.addTask {
                    (index, await MusicMetadataReader.artist(from: fileURL))
                }
            }

            for _ in 0..<min(maxConcurrent, fileURLs.count) {
                enqueue()
            }

            var artists = Array(repeating: "Unknown Artist", count: fileURLs.count)
            while let (index, artist) = await group.next() {
                artists[index] = artist
                enqueue()
            }
            return artists
        }
    }

    func clearWatchFolder() {
        smartWatchBookmark = nil
        smartWatchFolder = nil
        UserDefaults.standard.removeObject(forKey: Self.watchFolderKey)
        UserDefaults.standard.removeObject(forKey: Self.watchDisplayNameKey)
    }

    func clearLibraryFolder() {
        smartDestinationBookmark = nil
        smartDestinationFolder = nil
        UserDefaults.standard.removeObject(forKey: Self.destinationFolderKey)
        UserDefaults.standard.removeObject(forKey: Self.destinationDisplayNameKey)
    }

    func selectWatchFolder() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select the folder where new music downloads land (for example, Downloads)."
        panel.prompt = "Select"

        guard panel.runModal() == .OK, let watch = panel.url else { return }
        storeSmartFolder(url: watch, isWatch: true)
        #else
        errorMessage = "Folder selection requires macOS."
        showError = true
        #endif
    }

    func selectLibraryFolder() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select where Smart Place should organize music into artist folders."
        panel.prompt = "Select"

        guard panel.runModal() == .OK, let library = panel.url else { return }
        storeSmartFolder(url: library, isWatch: false)
        #else
        errorMessage = "Folder selection requires macOS."
        showError = true
        #endif
    }

    func smartPlace() async {
        guard smartPlaceReady else {
            errorMessage = "Smart Place needs a watch folder and a destination folder. Click the gear icon to set them up."
            showError = true
            return
        }

        guard let watch = smartWatchFolder, let destination = smartDestinationFolder else {
            errorMessage = "Smart Place needs a watch folder and a destination folder."
            showError = true
            return
        }

        // Make sure the destination is reachable; artist folders are created as needed.
        guard FileManager.default.fileExists(atPath: destination.path) else {
            errorMessage = "Cannot access destination folder."
            showError = true
            return
        }

        // Check that the watch folder can be read.
        do {
            _ = try SmartPlaceService.audioFiles(in: watch, excluding: destination)
        } catch {
            errorMessage = "Cannot access watch folder: \(error.localizedDescription)"
            showError = true
            return
        }

        isOrganizing = true
        completionMessage = nil
        loadingActivity = LoadingActivity(
            title: "Smart Place",
            detail: watch.lastPathComponent,
            note: "Finding each song's official release.",
            completed: 0,
            total: 0,
            recent: []
        )
        statusMessage = loadingActivity.title

        let useAlbumFolders = smartPlaceUsesAlbumFolders
        let report = loadingReporter()

        do {
            let result = try await Task.detached(priority: .userInitiated) {
                try await SmartPlaceService.planWithAmbiguities(
                    watchFolder: watch,
                    destinationFolder: destination,
                    useAlbumFolders: useAlbumFolders,
                    onProgress: report
                )
            }.value

            if result.plans.isEmpty, result.ambiguities.isEmpty, result.duplicates.isEmpty {
                isOrganizing = false
                errorMessage = "Nothing to place. The watch folder has no new music."
                showError = true
                statusMessage = "Nothing to place."
                return
            }

            // If there are ambiguities, show selection sheet
            if !result.ambiguities.isEmpty {
                smartPlaceAmbiguities = result.ambiguities
                smartPlacePendingPlans = result.plans
                smartPlaceDuplicates = result.duplicates

                // Collect song titles for each artist
                var artistSongTitles: [String: [String]] = [:]
                for plan in result.plans {
                    let songTitle = plan.sourceURL.deletingPathExtension().lastPathComponent
                    artistSongTitles[plan.artist, default: []].append(songTitle)
                }
                for ambiguity in result.ambiguities {
                    let titles = ambiguity.tracks.map { $0.sourceURL.deletingPathExtension().lastPathComponent }
                    artistSongTitles[ambiguity.artist] = titles
                }
                smartPlaceArtistSongTitles = artistSongTitles

                showSmartPlaceSelectionSheet = true
                isOrganizing = false
                statusMessage = "Please select where to place each artist's music"
                return
            }

            // If there are duplicates but no ambiguities, show selection sheet for duplicates
            if !result.duplicates.isEmpty {
                smartPlaceAmbiguities = []
                smartPlacePendingPlans = result.plans
                smartPlaceDuplicates = result.duplicates

                var artistSongTitles: [String: [String]] = [:]
                for plan in result.plans {
                    let songTitle = plan.sourceURL.deletingPathExtension().lastPathComponent
                    artistSongTitles[plan.artist, default: []].append(songTitle)
                }
                smartPlaceArtistSongTitles = artistSongTitles

                showSmartPlaceSelectionSheet = true
                isOrganizing = false
                statusMessage = "Please choose how to handle duplicate files"
                return
            }

            // No ambiguities, proceed with execution
            statusMessage = "Smart Place organizing into \(destination.lastPathComponent)…"
            let execution = try await Task.detached(priority: .userInitiated) {
                try await SmartPlaceService.execute(result, onProgress: report)
            }.value

            artistGroups = []
            scannedFiles = []
            scannedSourceGroups = []
            scanFormatSummary = nil
            refreshAddedFolderContents()

            let summary = smartPlaceSummaryMessage(for: execution)
            statusMessage = summary
            completionMessage = summary
            clearCompletionMessage(after: 6)

            // Show folder completion menu if new folders were created
            if execution.newArtistCount > 0 {
                completedFolderURL = destination
                showFolderCompletionMenu = true
            }

            if !execution.errors.isEmpty {
                errorMessage = execution.errors.joined(separator: "\n")
                showError = true
            }
        } catch {
            errorMessage = "Can't perform this action. \(error.localizedDescription)"
            showError = true
            statusMessage = "Smart Place failed."
        }

        isOrganizing = false
    }

    func handleSmartPlaceSelections(_ selections: [String: URL], _ duplicateChoices: [URL: Bool]) {
        guard let watch = smartWatchFolder, let destination = smartDestinationFolder else {
            return
        }

        isOrganizing = true
        showSmartPlaceSelectionSheet = false
        loadingActivity = LoadingActivity(
            title: "Moving songs",
            detail: "Using the folders you picked",
            note: "Then the album covers get saved.",
            completed: 0,
            total: 0,
            recent: []
        )
        statusMessage = loadingActivity.title
        let useAlbumFolders = smartPlaceUsesAlbumFolders
        let report = loadingReporter()

        Task {
            do {
                // Create plans for the selected folders
                var allPlans = smartPlacePendingPlans

                // Filter out duplicates that were marked to skip
                allPlans = allPlans.filter { plan in
                    if let shouldReplace = duplicateChoices[plan.sourceURL] {
                        return shouldReplace // true = replace, false = skip
                    }
                    return true
                }

                // For duplicates marked to replace, keep the library file until the new one is in place.
                let replacing = Set(duplicateChoices.compactMap { source, shouldReplace in
                    shouldReplace ? source : nil
                })

                var claimedDestinations = Set(allPlans.map { $0.destinationURL.standardizedFileURL.path })

                for ambiguity in smartPlaceAmbiguities {
                    let artist = ambiguity.artist
                    let artistFolder = selections[artist] ?? SmartPlaceService.artistFolder(named: artist, in: destination)

                    for track in ambiguity.tracks {
                        let targetFolder = await SmartPlaceService.resolvedDestinationFolder(
                            forArtistFolder: artistFolder,
                            fileURL: track.sourceURL,
                            albumName: track.albumName,
                            useAlbumFolders: useAlbumFolders
                        )
                        let placed = SmartPlaceService.placeFile(
                            track.sourceURL,
                            in: targetFolder,
                            claimed: &claimedDestinations
                        )
                        let plan = MusicFilePlan(
                            sourceURL: track.sourceURL,
                            sourceOrigin: watch.standardizedFileURL,
                            artist: artist,
                            destinationURL: placed.destination,
                            releaseID: track.releaseID,
                            releaseGroupID: track.releaseGroupID
                        )
                        allPlans.append(plan)
                    }
                }

                // Execute all plans
                let result = SmartPlaceService.PlanResult(
                    plans: allPlans,
                    matchedCount: 0,
                    newArtistCount: 0,
                    needsArtistCount: 0,
                    ambiguities: [],
                    duplicates: []
                )

                let execution = try await Task.detached(priority: .userInitiated) {
                    try await SmartPlaceService.execute(result, replacing: replacing, onProgress: report)
                }.value

                isOrganizing = false
                smartPlaceAmbiguities = []
                smartPlacePendingPlans = []
                smartPlaceDuplicates = []

                artistGroups = []
                scannedFiles = []
                scannedSourceGroups = []
                scanFormatSummary = nil
                refreshAddedFolderContents()

                let summary = smartPlaceSummaryMessage(for: execution)
                statusMessage = summary
                completionMessage = summary
                clearCompletionMessage(after: 6)

                if !execution.errors.isEmpty {
                    errorMessage = execution.errors.joined(separator: "\n")
                    showError = true
                }
            } catch {
                isOrganizing = false
                smartPlaceAmbiguities = []
                smartPlacePendingPlans = []
                smartPlaceDuplicates = []
                errorMessage = "Smart Place failed: \(error.localizedDescription)"
                showError = true
                statusMessage = "Smart Place failed"
            }
        }
    }

    func cancelSmartPlaceSelection() {
        showSmartPlaceSelectionSheet = false
        smartPlaceAmbiguities = []
        smartPlacePendingPlans = []
        smartPlaceDuplicates = []
        smartPlaceArtistSongTitles = [:]
        statusMessage = "Smart Place cancelled"
    }

    private func smartPlaceSummaryMessage(for execution: SmartPlaceService.ExecutionResult) -> String {
        let total = execution.movedCount
        let totalText = "Moved \(total) file\(total == 1 ? "" : "s")."

        var parts: [String] = []
        if execution.matchedCount > 0 {
            parts.append("\(execution.matchedCount) into existing artist folder\(execution.matchedCount == 1 ? "" : "s")")
        }
        if execution.newArtistCount > 0 {
            parts.append("\(execution.newArtistCount) into new artist folder\(execution.newArtistCount == 1 ? "" : "s")")
        }
        if execution.needsArtistCount > 0 {
            parts.append("\(execution.needsArtistCount) sent to _Needs Artist")
        }

        if parts.isEmpty {
            return totalText
        }

        return totalText + " " + parts.joined(separator: ", ") + "."
    }

    private func storeSmartFolder(url: URL, isWatch: Bool) {
        let bookmark = try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        let defaults = UserDefaults.standard
        if isWatch {
            smartWatchBookmark = bookmark
            smartWatchFolder = url
            if let bookmark {
                defaults.set(bookmark, forKey: Self.watchFolderKey)
            } else {
                defaults.set(url.path, forKey: Self.watchFolderKey)
            }
            defaults.set(url.lastPathComponent, forKey: Self.watchDisplayNameKey)
        } else {
            smartDestinationBookmark = bookmark
            smartDestinationFolder = url
            if let bookmark {
                defaults.set(bookmark, forKey: Self.destinationFolderKey)
            } else {
                defaults.set(url.path, forKey: Self.destinationFolderKey)
            }
            defaults.set(url.lastPathComponent, forKey: Self.destinationDisplayNameKey)
        }
    }

    private func resolveBookmark(_ data: Data?) -> URL? {
        guard let data else { return nil }
        var stale = false
        if let url = try? URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ) {
            _ = url.startAccessingSecurityScopedResource()
            return url
        }
        return nil
    }

    func addFolders() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.showsHiddenFiles = false
        panel.message = "Select folders and/or music files. Use ⌘-click to select multiple items in a folder."
        panel.prompt = "Add"

        guard panel.runModal() == .OK else { return }

        addURLs(panel.urls)
        #else
        errorMessage = "Use the folder picker button to add folders on this platform."
        showError = true
        #endif
    }

    func addURLs(_ urls: [URL]) {
        var addedCount = 0
        var skippedCount = 0

        for url in urls {
            if addSource(url) {
                addedCount += 1
            } else {
                skippedCount += 1
            }
        }

        guard addedCount > 0 else {
            if skippedCount > 0 {
                errorMessage = "No supported folders or music files were added. Supported formats include MP3, M4A, AAC, FLAC, WAV, AIFF, OGG, and WMA."
                showError = true
            }
            return
        }

        artistGroups = []
        scannedFiles = []
        scannedSourceGroups = []
        scanFormatSummary = nil
        updateSourceStatusMessage()
    }

    @discardableResult
    private func addSource(_ url: URL) -> Bool {
        let standardized = url.standardizedFileURL
        guard !sources.contains(where: { $0.id == standardized }) else { return false }

        guard let isDirectory = try? standardized.resourceValues(forKeys: [.isDirectoryKey]).isDirectory else {
            return false
        }

        if isDirectory {
            if url.startAccessingSecurityScopedResource() {
                securityScopedURLs.append(standardized)
            }
            sources.append(SourceEntry(url: standardized, isFolder: true))
            loadFolderContents(standardized)
            return true
        }

        guard MusicMetadataReader.isSupportedAudioFile(standardized) else { return false }

        if url.startAccessingSecurityScopedResource() {
            securityScopedURLs.append(standardized)
        }
        sources.append(SourceEntry(url: standardized, isFolder: false))
        return true
    }

    private func refreshAddedFolderContents() {
        for source in sources where source.isFolder {
            loadFolderContents(source.url)
        }
    }

    private func loadFolderContents(_ folder: URL) {
        let key = folder.standardizedFileURL
        loadingSourceIDs.insert(key)
        Task {
            let files = (try? await Task.detached {
                try MusicOrganizer.audioFiles(in: key, skipArtistFolders: false)
            }.value) ?? []
            guard sources.contains(where: { $0.id == key }) else { return }
            folderContents[key] = files
            loadingSourceIDs.remove(key)
        }
    }

    func removeSource(_ source: SourceEntry) {
        source.url.stopAccessingSecurityScopedResource()
        securityScopedURLs.removeAll { $0 == source.id }
        sources.removeAll { $0.id == source.id }
        folderContents[source.id] = nil
        loadingSourceIDs.remove(source.id)

        artistGroups = []
        scannedFiles = []
        scannedSourceGroups = []
        scanFormatSummary = nil
        updateSourceStatusMessage()
    }

    func removeSources(at offsets: IndexSet) {
        let entriesToRemove = offsets.map { sources[$0] }
        for entry in entriesToRemove {
            removeSource(entry)
        }
    }

    /// Clears the in-app source list only. Does not modify files on disk.
    func clearSourceFolders() {
        guard canClearSourceFolders else { return }

        for url in securityScopedURLs {
            url.stopAccessingSecurityScopedResource()
        }

        securityScopedURLs = []
        sources = []
        folderContents = [:]
        loadingSourceIDs = []
        artistGroups = []
        scannedFiles = []
        scannedSourceGroups = []
        scanFormatSummary = nil
        statusMessage = "Sources cleared. Select folders or music files to scan again."
    }

    func updateLoading(_ progress: SmartPlaceService.Progress) {
        var recent = loadingActivity.recent
        if progress.log {
            let line = "\(progress.detail) — \(progress.note)"
            if recent.last != line {
                recent.append(line)
                if recent.count > 4 {
                    recent.removeFirst(recent.count - 4)
                }
            }
        }
        loadingActivity = LoadingActivity(
            title: progress.title,
            detail: progress.detail,
            note: progress.note,
            completed: progress.completed,
            total: progress.total,
            recent: recent
        )
        statusMessage = progress.note.isEmpty ? progress.title : "\(progress.title): \(progress.detail)"
    }

    private func loadingReporter() -> @Sendable (SmartPlaceService.Progress) -> Void {
        { progress in
            Task { @MainActor in
                self.updateLoading(progress)
            }
        }
    }

    func scan() async {
        guard canScan else { return }

        isScanning = true
        completionMessage = nil
        loadingActivity = LoadingActivity(
            title: "Scanning your music",
            detail: "Reading artist tags",
            note: "Building the destination for each file.",
            completed: 0,
            total: 0,
            recent: []
        )
        statusMessage = loadingActivity.title
        MusicMetadataReader.clearCache()

        let folders = sources.filter(\.isFolder).map(\.url)
        let files = sources.filter { !$0.isFolder }.map(\.url)

        do {
            let groups = try await Task.detached(priority: .userInitiated) {
                try await MusicOrganizer.scan(folders: folders, files: files)
            }.value

            artistGroups = groups
            scannedFiles = buildScannedFiles(from: groups)
            scannedSourceGroups = SourceScanGroup.from(files: scannedFiles, sources: sources)
            scanFormatSummary = ScanFormatSummary.from(files: scannedFiles)
            let count = scannedFiles.count

            if count == 0 {
                statusMessage = "No music files found in the selected sources."
            } else {
                let artistCount = groups.count
                let formatNote = scanFormatSummary?.headline ?? ""
                statusMessage = "Found \(count) file\(count == 1 ? "" : "s") across \(artistCount) artist\(artistCount == 1 ? "" : "s"). Destinations are listed in the scan details. \(formatNote)"
                showScanResultsSheet = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            statusMessage = "Scan failed."
        }

        isScanning = false
    }

    private func clearCompletionMessage(after seconds: TimeInterval) {
        Task {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            completionMessage = nil
        }
    }

    private func buildScannedFiles(from groups: [ArtistGroup]) -> [ScannedFile] {
        let originLookup = Dictionary(uniqueKeysWithValues: sources.map { ($0.id, $0.isFolder) })

        return groups
            .flatMap(\.files)
            .map { plan in
                let origin = plan.sourceOrigin.standardizedFileURL
                let isFolder = originLookup[origin] ?? (origin != plan.sourceURL.standardizedFileURL)

                var scannedFile = ScannedFile(
                    url: plan.sourceURL,
                    fileName: plan.sourceURL.lastPathComponent,
                    formatLabel: MusicMetadataReader.formatLabel(for: plan.sourceURL),
                    qualityLabel: MusicMetadataReader.qualityLabel(for: plan.sourceURL),
                    artist: plan.artist,
                    plannedDestinationURL: plan.destinationURL,
                    sourceOriginURL: origin,
                    sourceOriginName: origin.lastPathComponent,
                    sourceIsFolder: isFolder
                )
                scannedFile.isDuplicate = plan.isDuplicate
                scannedFile.duplicateDestinationURL = plan.isDuplicate ? plan.destinationURL : nil
                return scannedFile
            }
            .sorted {
                $0.fileName.localizedCaseInsensitiveCompare($1.fileName) == .orderedAscending
            }
    }

    private func updateSourceStatusMessage() {
        if sources.isEmpty {
            statusMessage = "Select one or more folders or music files."
            return
        }

        let folderCount = sources.filter(\.isFolder).count
        let fileCount = sources.count - folderCount

        switch (folderCount, fileCount) {
        case let (folders, 0):
            statusMessage = "\(folders) folder\(folders == 1 ? "" : "s") selected."
        case let (0, files):
            statusMessage = "\(files) file\(files == 1 ? "" : "s") selected."
        case let (folders, files):
            statusMessage = "\(folders) folder\(folders == 1 ? "" : "s") and \(files) file\(files == 1 ? "" : "s") selected."
        }
    }
}
