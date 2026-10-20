import Foundation

enum SmartPlaceService {
    struct AmbiguousTrack {
        let sourceURL: URL
        let albumName: String?
        let releaseID: String?
        let releaseGroupID: String?
    }

    struct ArtistAmbiguity {
        let artist: String
        let isUnknown: Bool
        let matchingFolders: [URL]
        let tracks: [AmbiguousTrack]
    }

    struct DuplicateConflict {
        let sourceURL: URL
        let destinationURL: URL
        let artist: String
        let fileName: String
    }

    private struct PlacementGroup: Hashable {
        let artist: String
        let albumFolderName: String?
    }

    struct PlanResult {
        let plans: [MusicFilePlan]
        let matchedCount: Int
        let newArtistCount: Int
        let needsArtistCount: Int
        let ambiguities: [ArtistAmbiguity]
        let duplicates: [DuplicateConflict]
    }

    struct ExecutionResult {
        let movedCount: Int
        let matchedCount: Int
        let newArtistCount: Int
        let needsArtistCount: Int
        let errors: [String]
    }

    struct Progress: Sendable {
        var title: String
        var detail: String
        var note: String
        var completed: Int
        var total: Int
        var log: Bool = false
    }

    static func plan(
        watchFolder: URL,
        destinationFolder: URL
    ) async throws -> PlanResult {
        let watchFiles = try audioFiles(in: watchFolder, excluding: destinationFolder)
        var plans: [MusicFilePlan] = []
        var matchedCount = 0
        var newArtistCount = 0
        var needsArtistCount = 0
        let existingArtistFolders = existingArtistFolders(in: destinationFolder)
        print("Smart Place: Found \(existingArtistFolders.count) existing artist folders")
        for url in existingArtistFolders {
            print("  - '\(url.lastPathComponent)' at \(url.path)")
        }

        for fileURL in watchFiles {
            let artist = await MusicMetadataReader.artist(from: fileURL)
            let normalizedArtist = artist.lowercased().trimmingCharacters(in: .whitespaces)

            let plan: MusicFilePlan
            if let artistFolderURL = findMatchingArtistFolder(normalizedArtist, in: existingArtistFolders) {
                // Artist folder exists, put it there
                let destination = uniqueDestinationURL(in: artistFolderURL, filename: fileURL.lastPathComponent)
                plan = MusicFilePlan(
                    sourceURL: fileURL,
                    sourceOrigin: watchFolder.standardizedFileURL,
                    artist: artist,
                    destinationURL: destination
                )
                matchedCount += 1
                print("Smart Place: Matched artist '\(artist)' to existing folder '\(artistFolderURL.lastPathComponent)'")
            } else if artist == "Unknown Artist" {
                // Unknown artist, put in _Needs Artist folder
                let needsArtistFolder = destinationFolder.appendingPathComponent("_Needs Artist", isDirectory: true)
                let destination = uniqueDestinationURL(in: needsArtistFolder, filename: fileURL.lastPathComponent)
                plan = MusicFilePlan(
                    sourceURL: fileURL,
                    sourceOrigin: watchFolder.standardizedFileURL,
                    artist: artist,
                    destinationURL: destination
                )
                needsArtistCount += 1
                print("Smart Place: Unknown artist '\(artist)' -> _Needs Artist")
            } else {
                // New artist, create folder and put it there
                let artistFolder = artistFolder(named: artist, in: destinationFolder)
                let destination = uniqueDestinationURL(in: artistFolder, filename: fileURL.lastPathComponent)
                plan = MusicFilePlan(
                    sourceURL: fileURL,
                    sourceOrigin: watchFolder.standardizedFileURL,
                    artist: artist,
                    destinationURL: destination
                )
                newArtistCount += 1
                print("Smart Place: New artist '\(artist)' -> creating new folder at \(artistFolder.path)")
            }

            plans.append(plan)
        }

        return PlanResult(
            plans: plans,
            matchedCount: matchedCount,
            newArtistCount: newArtistCount,
            needsArtistCount: needsArtistCount,
            ambiguities: [],
            duplicates: []
        )
    }

    static func planWithAmbiguities(
        watchFolder: URL,
        destinationFolder: URL,
        useAlbumFolders: Bool = false,
        onProgress: (@Sendable (Progress) -> Void)? = nil
    ) async throws -> PlanResult {
        MusicMetadataReader.clearCache()
        let alreadyFiledFolders = existingArtistFolders(in: destinationFolder)
        let scannedFiles = try audioFiles(in: watchFolder, excluding: destinationFolder).filter { fileURL in
            !isNestedInsideArtistFolder(fileURL, of: alreadyFiledFolders)
        }
        let watchFiles = scannedFiles
        var plans: [MusicFilePlan] = []
        var matchedCount = 0
        var newArtistCount = 0
        let needsArtistCount = 0
        var ambiguities: [ArtistAmbiguity] = []
        var duplicates: [DuplicateConflict] = []

        let existingArtistFolders = existingArtistFolders(in: destinationFolder)
        print("Smart Place: Found \(existingArtistFolders.count) existing artist folders")

        var detectedArtistsByFile: [URL: String] = [:]
        var albumByFile: [URL: String] = [:]
        var releaseByFile: [URL: MusicBrainzMetadata.Match] = [:]
        let lookupTotal = watchFiles.count
        for (index, fileURL) in watchFiles.enumerated() {
            let fileName = fileURL.lastPathComponent
            onProgress?(Progress(
                title: "Smart Place",
                detail: fileName,
                note: "Reading the tags, then looking for the official release.",
                completed: index,
                total: lookupTotal
            ))

            let taggedArtist = await MusicMetadataReader.artist(from: fileURL)
            let title = await MusicMetadataReader.title(from: fileURL)
            let taggedAlbum = await MusicMetadataReader.album(from: fileURL)
            if let identified = await MusicBrainzMetadata.match(
                artist: taggedArtist,
                title: title,
                album: taggedAlbum
            ) {
                detectedArtistsByFile[fileURL] = identified.artist
                albumByFile[fileURL] = MusicMetadataReader.cleanAlbumName(identified.album)
                releaseByFile[fileURL] = identified
                onProgress?(Progress(
                    title: "Smart Place",
                    detail: fileName,
                    note: "\(identified.artist) · \(albumByFile[fileURL] ?? identified.album)",
                    completed: index + 1,
                    total: lookupTotal,
                    log: true
                ))
            } else {
                detectedArtistsByFile[fileURL] = taggedArtist
                if let taggedAlbum, taggedAlbum != "Unknown Artist" {
                    albumByFile[fileURL] = MusicMetadataReader.cleanAlbumName(taggedAlbum)
                }
                onProgress?(Progress(
                    title: "Smart Place",
                    detail: fileName,
                    note: "No confident match. Keeping the tags already on the file.",
                    completed: index + 1,
                    total: lookupTotal,
                    log: true
                ))
            }
        }

        onProgress?(Progress(
            title: "Choosing folders",
            detail: "Sorting artists and albums",
            note: "Each album gets a folder inside the artist folder.",
            completed: lookupTotal,
            total: lookupTotal
        ))

        let root = watchFolder.standardizedFileURL
        let filesBySourceFolder = Dictionary(grouping: watchFiles) { fileURL in
            fileURL.deletingLastPathComponent().standardizedFileURL
        }
        let majorityArtistsBySourceFolder = majorityArtistsByFolder(
            filesBySourceFolder,
            detectedArtistsByFile: detectedArtistsByFile,
            root: root
        )
        let albumArtistByFile = majorityArtistByAlbum(
            filesBySourceFolder: filesBySourceFolder,
            detectedArtistsByFile: detectedArtistsByFile,
            albumByFile: albumByFile,
            folderArtists: majorityArtistsBySourceFolder
        )

        var artistToFiles: [String: [URL]] = [:]
        for fileURL in watchFiles {
            let sourceFolder = fileURL.deletingLastPathComponent().standardizedFileURL
            let artist = majorityArtistsBySourceFolder[sourceFolder]
                ?? albumArtistByFile[fileURL]
                ?? detectedArtistsByFile[fileURL]
                ?? "Unknown Artist"

            if artistToFiles[artist] == nil {
                artistToFiles[artist] = []
            }
            artistToFiles[artist]?.append(fileURL)
        }

        let filingAlbumByFile = filingAlbums(artistToFiles: artistToFiles, albumByFile: albumByFile)
        var claimedDestinations: Set<String> = []

        // Process each artist
        for (artist, files) in artistToFiles {
            let normalizedArtist = artist.lowercased().trimmingCharacters(in: .whitespaces)
            let matchingFolders = findAllMatchingArtistFolders(normalizedArtist, in: existingArtistFolders)

            print("Smart Place: Artist '\(artist)' (normalized: '\(normalizedArtist)') found \(matchingFolders.count) matching folders:")
            for url in matchingFolders {
                print("  - '\(url.lastPathComponent)' at '\(url.path)'")
            }

            if artist == "Unknown Artist" {
                ambiguities.append(ArtistAmbiguity(
                    artist: artist,
                    isUnknown: true,
                    matchingFolders: [],
                    tracks: ambiguousTracks(files, albumByFile: filingAlbumByFile, releaseByFile: releaseByFile)
                ))
            } else if matchingFolders.isEmpty {
                // No matching folder - create a new artist folder in the destination.
                let artistFolderURL = artistFolder(named: artist, in: destinationFolder)
                for fileURL in files {
                    let targetFolder = await resolvedDestinationFolder(
                        forArtistFolder: artistFolderURL,
                        fileURL: fileURL,
                        albumName: filingAlbumByFile[fileURL],
                        useAlbumFolders: useAlbumFolders
                    )
                    let placed = placeFile(fileURL, in: targetFolder, claimed: &claimedDestinations)
                    if placed.destination.standardizedFileURL == fileURL.standardizedFileURL {
                        continue
                    }
                    if placed.isDuplicate {
                        duplicates.append(DuplicateConflict(
                            sourceURL: fileURL,
                            destinationURL: placed.destination,
                            artist: artist,
                            fileName: fileURL.lastPathComponent
                        ))
                    }

                    let plan = MusicFilePlan(
                        sourceURL: fileURL,
                        sourceOrigin: watchFolder.standardizedFileURL,
                        artist: artist,
                        destinationURL: placed.destination,
                        releaseID: releaseByFile[fileURL]?.releaseID,
                        releaseGroupID: releaseByFile[fileURL]?.releaseGroupID
                    )
                    plans.append(plan)
                    newArtistCount += 1
                }
                print("Smart Place: New artist '\(artist)' -> creating new folder at \(artistFolderURL.path)")
            } else if matchingFolders.count > 1 {
                ambiguities.append(ArtistAmbiguity(
                    artist: artist,
                    isUnknown: false,
                    matchingFolders: matchingFolders,
                    tracks: ambiguousTracks(files, albumByFile: filingAlbumByFile, releaseByFile: releaseByFile)
                ))
            } else {
                // Single match - proceed normally
                let artistFolderURL = matchingFolders[0]
                for fileURL in files {
                    let targetFolder = await resolvedDestinationFolder(
                        forArtistFolder: artistFolderURL,
                        fileURL: fileURL,
                        albumName: filingAlbumByFile[fileURL],
                        useAlbumFolders: useAlbumFolders
                    )
                    let placed = placeFile(fileURL, in: targetFolder, claimed: &claimedDestinations)
                    if placed.destination.standardizedFileURL == fileURL.standardizedFileURL {
                        continue
                    }
                    if placed.isDuplicate {
                        duplicates.append(DuplicateConflict(
                            sourceURL: fileURL,
                            destinationURL: placed.destination,
                            artist: artist,
                            fileName: fileURL.lastPathComponent
                        ))
                    }

                    let plan = MusicFilePlan(
                        sourceURL: fileURL,
                        sourceOrigin: watchFolder.standardizedFileURL,
                        artist: artist,
                        destinationURL: placed.destination,
                        releaseID: releaseByFile[fileURL]?.releaseID,
                        releaseGroupID: releaseByFile[fileURL]?.releaseGroupID
                    )
                    plans.append(plan)
                    matchedCount += 1
                }
                print("Smart Place: Matched artist '\(artist)' to existing folder '\(artistFolderURL.lastPathComponent)'")
            }
        }

        return PlanResult(
            plans: plans,
            matchedCount: matchedCount,
            newArtistCount: newArtistCount,
            needsArtistCount: needsArtistCount,
            ambiguities: ambiguities,
            duplicates: duplicates
        )
    }

    static func execute(
        _ result: PlanResult,
        replacing: Set<URL> = [],
        onProgress: (@Sendable (Progress) -> Void)? = nil
    ) async throws -> ExecutionResult {
        var movedCount = 0
        var errors: [String] = []
        let replacingPaths = Set(replacing.map { $0.standardizedFileURL.path })

        // Create all necessary artist folders
        let artistFolders = Set(result.plans.map { $0.destinationURL.deletingLastPathComponent() })
        for folder in artistFolders {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }

        let moveTotal = result.plans.count
        for (index, plan) in result.plans.enumerated() {
            let fileName = plan.sourceURL.lastPathComponent
            onProgress?(Progress(
                title: "Moving songs",
                detail: fileName,
                note: plan.destinationURL.deletingLastPathComponent().lastPathComponent,
                completed: index,
                total: max(moveTotal, 1)
            ))

            if plan.sourceURL.standardizedFileURL == plan.destinationURL.standardizedFileURL {
                continue
            }

            do {
                if FileManager.default.fileExists(atPath: plan.destinationURL.path) {
                    if replacingPaths.contains(plan.sourceURL.standardizedFileURL.path) {
                        try replaceExistingFile(at: plan.sourceURL, with: plan.destinationURL)
                        movedCount += 1
                        onProgress?(Progress(
                            title: "Moving songs",
                            detail: fileName,
                            note: "Placed in \(plan.destinationURL.deletingLastPathComponent().lastPathComponent)",
                            completed: index + 1,
                            total: max(moveTotal, 1),
                            log: true
                        ))
                    } else {
                        errors.append("Skipped (already exists): \(plan.destinationURL.lastPathComponent)")
                        onProgress?(Progress(
                            title: "Moving songs",
                            detail: fileName,
                            note: "Already there, so this one stays put.",
                            completed: index + 1,
                            total: max(moveTotal, 1),
                            log: true
                        ))
                    }
                    continue
                }

                try FileManager.default.moveItem(at: plan.sourceURL, to: plan.destinationURL)
                movedCount += 1
                onProgress?(Progress(
                    title: "Moving songs",
                    detail: fileName,
                    note: "Placed in \(plan.destinationURL.deletingLastPathComponent().lastPathComponent)",
                    completed: index + 1,
                    total: max(moveTotal, 1),
                    log: true
                ))
            } catch {
                errors.append("\(plan.sourceURL.lastPathComponent): \(error.localizedDescription)")
            }
        }

        let plansByFolder = Dictionary(grouping: result.plans) {
            $0.destinationURL.deletingLastPathComponent().standardizedFileURL
        }
        for (folder, folderPlans) in plansByFolder {
            let releaseIDs = Set(folderPlans.compactMap(\.releaseID))
            guard releaseIDs.count == 1, let releaseID = releaseIDs.first else { continue }
            let releaseGroupID = folderPlans.compactMap(\.releaseGroupID).first
            onProgress?(Progress(
                title: "Fetching the cover",
                detail: folder.lastPathComponent,
                note: "Saving the artwork from the matched release.",
                completed: 0,
                total: 1
            ))
            await MusicBrainzMetadata.saveCover(
                releaseID: releaseID,
                releaseGroupID: releaseGroupID,
                in: folder
            )
            onProgress?(Progress(
                title: "Fetching the cover",
                detail: folder.lastPathComponent,
                note: "Cover saved for \(folder.lastPathComponent).",
                completed: 1,
                total: 1,
                log: true
            ))
        }

        return ExecutionResult(
            movedCount: movedCount,
            matchedCount: result.matchedCount,
            newArtistCount: result.newArtistCount,
            needsArtistCount: result.needsArtistCount,
            errors: errors
        )
    }

    /// Moves the new file into place, and puts the old library file back if that move fails.
    private static func replaceExistingFile(at source: URL, with destination: URL) throws {
        let backup = destination.deletingLastPathComponent()
            .appendingPathComponent(".sortitout-\(UUID().uuidString)-\(destination.lastPathComponent)")
        try FileManager.default.moveItem(at: destination, to: backup)
        do {
            try FileManager.default.moveItem(at: source, to: destination)
            try? FileManager.default.removeItem(at: backup)
        } catch {
            try? FileManager.default.moveItem(at: backup, to: destination)
            throw error
        }
    }

    static func audioFiles(in folder: URL, excluding excludedRoot: URL? = nil) throws -> [URL] {
        let root = folder.standardizedFileURL
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        let excluded = libraryPrefix(excludedRoot, differentFrom: root)
        var files: [URL] = []

        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            guard values.isRegularFile == true else { continue }
            guard MusicMetadataReader.isSupportedAudioFile(fileURL) else { continue }
            if let excluded, fileURL.standardizedFileURL.path.hasPrefix(excluded) {
                continue
            }

            files.append(fileURL)
        }

        return files.sorted {
            $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
        }
    }

    /// A download folder's majority artist, so a feature or a shared credit stays with that artist.
    private static func majorityArtistsByFolder(
        _ filesBySourceFolder: [URL: [URL]],
        detectedArtistsByFile: [URL: String],
        root: URL
    ) -> [URL: String] {
        var result: [URL: String] = [:]

        for (folder, files) in filesBySourceFolder {
            guard folder != root, files.count > 1 else { continue }
            let votes = votedArtistNames(for: files, detectedArtistsByFile: detectedArtistsByFile)
            if let majority = majorityName(in: votes, total: files.count) {
                result[folder] = majority
            }
        }

        return result
    }

    /// Tracks that share an album use that album's majority artist, so a feature does not open another folder.
    private static func majorityArtistByAlbum(
        filesBySourceFolder: [URL: [URL]],
        detectedArtistsByFile: [URL: String],
        albumByFile: [URL: String],
        folderArtists: [URL: String]
    ) -> [URL: String] {
        var result: [URL: String] = [:]

        for (folder, files) in filesBySourceFolder {
            guard folderArtists[folder] == nil else { continue }
            let groups = Dictionary(grouping: files) { file -> String in
                guard let album = albumByFile[file], album != "Unknown Artist" else { return "" }
                return folded(album)
            }
            for (key, group) in groups {
                guard !key.isEmpty, group.count > 1 else { continue }
                let votes = votedArtistNames(for: group, detectedArtistsByFile: detectedArtistsByFile)
                guard let artist = majorityName(in: votes, total: group.count) else { continue }
                for file in group {
                    result[file] = artist
                }
            }
        }

        return result
    }

    /// Songs in one artist group share that group's album when a song has no album name, or its album name is the artist.
    private static func filingAlbums(
        artistToFiles: [String: [URL]],
        albumByFile: [URL: String]
    ) -> [URL: String] {
        var result = albumByFile

        for (artist, files) in artistToFiles where files.count > 1 {
            let realNames = files.compactMap { file -> String? in
                guard let album = albumByFile[file], album != "Unknown Artist" else { return nil }
                guard !MusicMetadataReader.folderNamesMatch(album, artist) else { return nil }
                return album
            }
            guard let shared = sharedAlbumName(in: realNames) else { continue }

            for file in files {
                let own = albumByFile[file]
                let missing = own == nil || own == "Unknown Artist"
                let namedForArtist = own.map { MusicMetadataReader.folderNamesMatch($0, artist) } ?? false
                if missing || namedForArtist {
                    result[file] = shared
                }
            }
        }

        return result
    }

    private static func sharedAlbumName(in names: [String]) -> String? {
        guard !names.isEmpty else { return nil }
        var grouped: [String: String] = [:]
        for name in names {
            let key = folded(name)
            if grouped[key] == nil {
                grouped[key] = name
            }
        }
        if grouped.count == 1 {
            return names[0]
        }
        return majorityName(in: names, total: names.count)
    }

    private static func votedArtistNames(for files: [URL], detectedArtistsByFile: [URL: String]) -> [String] {
        let exact = files.compactMap { detectedArtistsByFile[$0] }.filter { $0 != "Unknown Artist" }
        return exact.map { votedArtist($0, exactArtists: exact) }
    }

    /// "A & B" counts as A when A is already an artist in the same batch.
    private static func votedArtist(_ name: String, exactArtists: [String]) -> String {
        if name == "Unknown Artist" { return name }
        let leading = MusicMetadataReader.leadingArtistName(name)
        if let match = exactArtists.first(where: {
            MusicMetadataReader.folderNamesMatch($0, leading) && !MusicMetadataReader.folderNamesMatch($0, name)
        }) {
            return match
        }
        return MusicMetadataReader.sanitizePrimaryArtistName(name)
    }

    private static func majorityName(in names: [String], total: Int) -> String? {
        guard total > 1, !names.isEmpty else { return nil }
        var counts: [String: (name: String, count: Int)] = [:]
        for name in names {
            let key = folded(name)
            if var existing = counts[key] {
                existing.count += 1
                counts[key] = existing
            } else {
                counts[key] = (name, 1)
            }
        }
        guard let best = counts.values.max(by: { lhs, rhs in
            if lhs.count == rhs.count {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedDescending
            }
            return lhs.count < rhs.count
        }) else { return nil }
        let minimum = max(2, Int(ceil(Double(total) / 2.0)))
        return best.count >= minimum ? best.name : nil
    }

    private static func folded(_ name: String) -> String {
        name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private static func isNestedInsideArtistFolder(_ fileURL: URL, of folders: [URL]) -> Bool {
        let parent = fileURL.deletingLastPathComponent().standardizedFileURL
        let path = fileURL.standardizedFileURL.path
        return folders.contains { folder in
            let folderURL = folder.standardizedFileURL
            guard parent != folderURL else { return false }
            let folderPath = folderURL.path
            let prefix = folderPath.hasSuffix("/") ? folderPath : folderPath + "/"
            return path.hasPrefix(prefix)
        }
    }

    private static func existingArtistFolders(in folder: URL) -> [URL] {
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        return contents.filter { folderURL in
            let values = try? folderURL.resourceValues(forKeys: [.isDirectoryKey])
            guard values?.isDirectory == true else { return false }
            return !folderURL.lastPathComponent.hasPrefix("_")
        }
    }

    private static func findMatchingArtistFolder(_ normalizedArtist: String, in folders: [URL]) -> URL? {
        let matches = findAllMatchingArtistFolders(normalizedArtist, in: folders)
        return matches.first
    }

    private static func findAllMatchingArtistFolders(_ normalizedArtist: String, in folders: [URL]) -> [URL] {
        let matches = folders.filter { folderURL in
            MusicMetadataReader.folderNamesMatch(folderURL.lastPathComponent, normalizedArtist)
        }
        return preferOutermostFolders(matches)
    }

    private static func libraryPrefix(_ library: URL?, differentFrom watch: URL) -> String? {
        guard let library else { return nil }
        let libraryURL = library.standardizedFileURL
        guard libraryURL != watch else { return nil }
        let path = libraryURL.path
        return path.hasSuffix("/") ? path : path + "/"
    }

    /// Drops a nested copy when the same artist folder already exists above it.
    private static func preferOutermostFolders(_ folders: [URL]) -> [URL] {
        let standardized = folders.map { $0.standardizedFileURL }
        return standardized.filter { folder in
            let path = folder.path
            return !standardized.contains { other in
                let otherPath = other.path
                guard otherPath != path else { return false }
                let prefix = otherPath.hasSuffix("/") ? otherPath : otherPath + "/"
                return path.hasPrefix(prefix)
            }
        }
    }

    static func artistFolder(named artist: String, in destinationFolder: URL) -> URL {
        if MusicMetadataReader.folderNamesMatch(destinationFolder.lastPathComponent, artist) {
            return destinationFolder
        }
        return destinationFolder.appendingPathComponent(artist, isDirectory: true)
    }

    static func uniqueDestinationURL(in folder: URL, filename: String, reserved: Set<String> = []) -> URL {
        let fileManager = FileManager.default
        var destination = folder.appendingPathComponent(filename)
        var counter = 1

        func blocked(_ url: URL) -> Bool {
            let path = url.standardizedFileURL.path
            if reserved.contains(path) { return true }
            return fileManager.fileExists(atPath: url.path)
        }

        while blocked(destination) {
            let ext = (filename as NSString).pathExtension
            let base = (filename as NSString).deletingPathExtension
            let newName = ext.isEmpty ? "\(base) (\(counter))" : "\(base) (\(counter)).\(ext)"
            destination = folder.appendingPathComponent(newName)
            counter += 1
        }

        return destination
    }

    /// A song already at this path stays put. A different file already there is a duplicate.
    static func placeFile(
        _ fileURL: URL,
        in folder: URL,
        claimed: inout Set<String>
    ) -> (destination: URL, isDuplicate: Bool) {
        let proposed = folder.appendingPathComponent(fileURL.lastPathComponent)
        let proposedKey = proposed.standardizedFileURL.path
        let sourceKey = fileURL.standardizedFileURL.path

        if proposedKey == sourceKey {
            return (fileURL.standardizedFileURL, false)
        }

        if FileManager.default.fileExists(atPath: proposed.path) {
            return (proposed, true)
        }

        if claimed.contains(proposedKey) {
            let destination = uniqueDestinationURL(in: folder, filename: fileURL.lastPathComponent, reserved: claimed)
            claimed.insert(destination.standardizedFileURL.path)
            return (destination, false)
        }

        claimed.insert(proposedKey)
        return (proposed, false)
    }

    private static func ambiguousTracks(
        _ files: [URL],
        albumByFile: [URL: String],
        releaseByFile: [URL: MusicBrainzMetadata.Match]
    ) -> [AmbiguousTrack] {
        files.map { fileURL in
            AmbiguousTrack(
                sourceURL: fileURL,
                albumName: albumByFile[fileURL],
                releaseID: releaseByFile[fileURL]?.releaseID,
                releaseGroupID: releaseByFile[fileURL]?.releaseGroupID
            )
        }
    }

    static func resolvedDestinationFolder(
        forArtistFolder artistFolderURL: URL,
        fileURL: URL,
        albumName: String? = nil,
        useAlbumFolders: Bool
    ) async -> URL {
        let resolvedAlbum: String?
        if let albumName {
            resolvedAlbum = albumName
        } else {
            resolvedAlbum = await MusicMetadataReader.album(from: fileURL)
        }
        guard useAlbumFolders else {
            return artistFolderURL
        }

        if let resolvedAlbum {
            let album = MusicMetadataReader.cleanAlbumName(resolvedAlbum)
            if album != "Unknown Artist",
               !MusicMetadataReader.folderNamesMatch(album, artistFolderURL.lastPathComponent) {
                return albumFolder(named: album, in: artistFolderURL)
            }
        }

        return artistFolderURL
    }

    private static func albumFolder(named album: String, in artistFolder: URL) -> URL {
        if let match = existingAlbumFolders(in: artistFolder).first(where: {
            MusicMetadataReader.folderNamesMatch($0.lastPathComponent, album)
        }) {
            return match
        }
        return artistFolder.appendingPathComponent(album, isDirectory: true)
    }

    private static func existingAlbumFolders(in artistFolder: URL) -> [URL] {
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: artistFolder,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        return contents.filter { folderURL in
            let values = try? folderURL.resourceValues(forKeys: [.isDirectoryKey])
            return values?.isDirectory == true
        }
    }

}
