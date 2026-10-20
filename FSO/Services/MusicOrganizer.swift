import Foundation

enum MusicOrganizer {
    static func scan(folders: [URL], files: [URL] = []) async throws -> [ArtistGroup] {
        var plans: [MusicFilePlan] = []

        for folder in folders {
            let folderFiles = try audioFiles(in: folder, skipArtistFolders: false)
            for fileURL in folderFiles {
                plans.append(await plan(for: fileURL, organizeRoot: folder, sourceOrigin: folder))
            }
        }

        for fileURL in files {
            let root = fileURL.deletingLastPathComponent().standardizedFileURL
            plans.append(await plan(for: fileURL, organizeRoot: root, sourceOrigin: fileURL))
        }

        let grouped = Dictionary(grouping: plans, by: \.artist)
        return grouped
            .map { ArtistGroup(artist: $0.key, files: $0.value) }
            .sorted { $0.artist.localizedCaseInsensitiveCompare($1.artist) == .orderedAscending }
    }

    private static func plan(for fileURL: URL, organizeRoot: URL, sourceOrigin: URL) async -> MusicFilePlan {
        let artist = await MusicMetadataReader.artist(from: fileURL)
        let artistFolder = artistFolder(named: artist, under: organizeRoot)
        let proposed = artistFolder.appendingPathComponent(fileURL.lastPathComponent)
        if proposed.standardizedFileURL == fileURL.standardizedFileURL {
            return MusicFilePlan(
                sourceURL: fileURL,
                sourceOrigin: sourceOrigin.standardizedFileURL,
                artist: artist,
                destinationURL: fileURL,
                isDuplicate: false
            )
        }

        let fileExistsAtDestination = FileManager.default.fileExists(atPath: proposed.path)
        return MusicFilePlan(
            sourceURL: fileURL,
            sourceOrigin: sourceOrigin.standardizedFileURL,
            artist: artist,
            destinationURL: proposed,
            isDuplicate: fileExistsAtDestination
        )
    }

    static func audioFiles(in folder: URL) throws -> [URL] {
        return try audioFiles(in: folder, skipArtistFolders: true)
    }

    static func audioFiles(in folder: URL, skipArtistFolders: Bool) throws -> [URL] {
        let root = folder.standardizedFileURL
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        var files: [URL] = []

        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            guard values.isRegularFile == true else { continue }
            guard MusicMetadataReader.isSupportedAudioFile(fileURL) else { continue }
            if skipArtistFolders {
                guard !isAlreadyInArtistFolder(fileURL: fileURL, root: root) else { continue }
            }

            files.append(fileURL)
        }

        return files.sorted {
            $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
        }
    }

    /// Uses the scan folder itself when it is already named for this artist.
    private static func artistFolder(named artist: String, under root: URL) -> URL {
        if MusicMetadataReader.folderNamesMatch(root.lastPathComponent, artist) {
            return root
        }
        return root.appendingPathComponent(artist, isDirectory: true)
    }

    /// Skips a song that already sits inside any folder under the scan root.
    /// Album folders are two levels deep, so a one-level check was listing them again.
    private static func isAlreadyInArtistFolder(fileURL: URL, root: URL) -> Bool {
        let parent = fileURL.deletingLastPathComponent().standardizedFileURL
        let scanRoot = root.standardizedFileURL
        return parent != scanRoot
    }
}
