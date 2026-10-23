import Foundation
#if os(macOS)
import AppKit
#endif

enum MusicBrainzMetadata {
    struct Match: Sendable {
        let artist: String
        let album: String
        let releaseID: String
        let releaseGroupID: String?
    }

    private static let userAgent = "SortItOut/1.2 ( https://musicbrainz.org/doc/MusicBrainz_API )"
    private static let throttle = RequestThrottle()
    private static let cache = MatchCache()

    static func match(artist: String?, title: String?, album: String?) async -> Match? {
        let hintedArtist = cleaned(artist).map(MusicMetadataReader.sanitizePrimaryArtistName)
        let hintedTitle = cleaned(title).map(searchTitle)
        let hintedAlbum = cleaned(album).map(MusicMetadataReader.cleanAlbumName)
        guard hintedTitle != nil || hintedAlbum != nil else { return nil }

        let cacheKey = [hintedArtist, hintedTitle, hintedAlbum].map { $0 ?? "" }.joined(separator: "\n")
        if let cached = await cache.stored(cacheKey) {
            return cached.match
        }

        var found: Match?
        for query in searchQueries(artist: hintedArtist, title: hintedTitle, album: hintedAlbum) {
            guard let recordings = await searchRecordings(query: query) else { continue }
            if let match = chooseMatch(
                recordings: recordings,
                hintedArtist: hintedArtist,
                hintedAlbum: hintedAlbum
            ) {
                found = match
                break
            }
        }

        await cache.store(found, for: cacheKey)
        return found
    }

    static func saveCover(releaseID: String, releaseGroupID: String?, in folder: URL) async {
        let existing = ["cover.jpg", "cover.png", "folder.jpg"]
        if existing.contains(where: { FileManager.default.fileExists(atPath: folder.appendingPathComponent($0).path) }) {
            return
        }

        guard let image = await coverImage(releaseID: releaseID, releaseGroupID: releaseGroupID) else {
            return
        }

        let filename = image.starts(with: [0x89, 0x50, 0x4E, 0x47]) ? "cover.png" : "cover.jpg"
        let destination = folder.appendingPathComponent(filename)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try image.write(to: destination, options: .atomic)
            #if os(macOS)
            if let icon = NSImage(data: image) {
                NSWorkspace.shared.setIcon(icon, forFile: folder.path, options: [])
            }
            #endif
        } catch {
            print("Smart Place: Could not save cover for \(folder.lastPathComponent): \(error.localizedDescription)")
        }
    }

    private static func cleaned(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "Unknown Artist" else { return nil }
        return trimmed
    }

    private static func searchQueries(artist: String?, title: String?, album: String?) -> [String] {
        var queries: [String] = []
        if let title, let artist {
            queries.append("recording:\(quoted(title)) AND artist:\(quoted(artist))")
        }
        if let title, let album, let artist {
            queries.append("recording:\(quoted(title)) AND release:\(quoted(album)) AND artist:\(quoted(artist))")
        }
        if let title, artist == nil {
            queries.append("recording:\(quoted(title))")
        }
        if title == nil, let album, let artist {
            queries.append("release:\(quoted(album)) AND artist:\(quoted(artist))")
        }
        var seen: [String] = []
        for query in queries where !seen.contains(query) {
            seen.append(query)
        }
        return seen
    }

    /// Drops a leading track number and a featured credit so the lookup uses the song title.
    private static func searchTitle(_ title: String) -> String {
        var result = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let patterns = [
            #"^\d{1,3}[\s.\-_]+"#,
            #"\s*[\(\[]\s*(feat\.?|ft\.?|featuring|with)\b.*$"#,
            #"\s+(feat\.?|ft\.?|featuring)\b.*$"#
        ]
        for pattern in patterns {
            if let range = result.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                result.removeSubrange(range)
                result = result.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return result.isEmpty ? title : result
    }

    private static func quoted(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private static func namesLooselyMatch(_ lhs: String, _ rhs: String) -> Bool {
        if loosely(lhs, rhs) { return true }
        let left = MusicMetadataReader.leadingArtistName(lhs)
        let right = MusicMetadataReader.leadingArtistName(rhs)
        return loosely(left, right) || loosely(left, rhs) || loosely(lhs, right)
    }

    private static func loosely(_ lhs: String, _ rhs: String) -> Bool {
        let left = lhs.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let right = rhs.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        if left == right { return true }
        let short = left.count <= right.count ? left : right
        let long = left.count <= right.count ? right : left
        guard short.count >= 4 else { return false }
        guard short.count >= 2, long.hasPrefix(short) else { return false }
        guard let next = long.dropFirst(short.count).first else { return true }
        return next.isWhitespace || next == "&" || next == "," || next == "(" || next == "/"
    }

    private static func primaryName(_ credits: [ArtistCredit]?) -> String? {
        let name = credits?.first?.name ?? credits?.first?.artist?.name
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private static func searchRecordings(query: String) async -> [Recording]? {
        var components = URLComponents(string: "https://musicbrainz.org/ws/2/recording")
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "limit", value: "10")
        ]
        guard let url = components?.url else { return nil }

        await throttle.wait()
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }
            return try JSONDecoder().decode(RecordingSearch.self, from: data).recordings
        } catch {
            print("Smart Place: MusicBrainz lookup failed: \(error.localizedDescription)")
            return nil
        }
    }

    private static func chooseMatch(
        recordings: [Recording],
        hintedArtist: String?,
        hintedAlbum: String?
    ) -> Match? {
        struct Choice {
            let artist: String
            let album: String
            let releaseID: String
            let releaseGroupID: String?
            let date: String
            let kindRank: Int
            let albumMatch: Bool
        }

        var choices: [Choice] = []
        for recording in recordings where (recording.score ?? 0) >= 70 {
            guard let recordingArtist = primaryName(recording.artistCredit) else { continue }
            let creditNames = (recording.artistCredit ?? []).compactMap { credit in
                credit.name ?? credit.artist?.name
            }
            let releases = recording.releases ?? []
            let official = releases.filter { $0.status == "Official" }
            let usable = official.isEmpty ? releases.filter { $0.status != "Bootleg" } : official
            let artistOnRecording = hintedArtist.map { hinted in
                ([recordingArtist] + creditNames).contains { namesLooselyMatch($0, hinted) }
            } ?? true
            for release in usable {
                let releaseArtist = primaryName(release.artistCredit) ?? recordingArtist
                let albumTitle = release.title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !albumTitle.isEmpty else { continue }
                let albumMatches = hintedAlbum.map { loosely($0, albumTitle) } ?? false
                let artistOnRelease = hintedArtist.map { namesLooselyMatch(releaseArtist, $0) } ?? true
                // A featured credit can be the recording artist. Keep the release when it is
                // that person's album, or when the hinted artist is actually on the recording.
                guard artistOnRelease || (artistOnRecording && (albumMatches || namesLooselyMatch(releaseArtist, recordingArtist))) else {
                    continue
                }

                let kind = release.releaseGroup?.primaryType ?? ""
                if kind == "Compilation" { continue }
                let secondaries = release.releaseGroup?.secondaryTypes ?? []
                if secondaries.contains("Compilation"), kind != "Album", kind != "Single", kind != "EP" {
                    continue
                }

                let kindRank: Int
                switch kind {
                case "Album": kindRank = 0
                case "Single", "EP": kindRank = 1
                default: kindRank = 2
                }

                choices.append(Choice(
                    artist: releaseArtist,
                    album: albumTitle,
                    releaseID: release.id,
                    releaseGroupID: release.releaseGroup?.id,
                    date: release.date ?? "",
                    kindRank: kindRank,
                    albumMatch: albumMatches
                ))
            }
        }

        guard !choices.isEmpty else { return nil }
        let pool = choices.contains(where: \.albumMatch) ? choices.filter(\.albumMatch) : choices
        let counts = Dictionary(grouping: pool, by: { $0.album.lowercased() }).mapValues(\.count)
        guard let best = pool.max(by: { lhs, rhs in
            let leftCount = counts[lhs.album.lowercased()] ?? 0
            let rightCount = counts[rhs.album.lowercased()] ?? 0
            if leftCount != rightCount { return leftCount < rightCount }
            if lhs.albumMatch != rhs.albumMatch { return !lhs.albumMatch }
            if lhs.kindRank != rhs.kindRank { return lhs.kindRank > rhs.kindRank }
            let leftDate = lhs.date.isEmpty ? "9999" : lhs.date
            let rightDate = rhs.date.isEmpty ? "9999" : rhs.date
            return leftDate > rightDate
        }) else { return nil }

        return Match(
            artist: MusicMetadataReader.sanitizePrimaryArtistName(best.artist),
            album: MusicMetadataReader.cleanAlbumName(best.album),
            releaseID: best.releaseID,
            releaseGroupID: best.releaseGroupID
        )
    }

    private static func coverImage(releaseID: String, releaseGroupID: String?) async -> Data? {
        if let image = await downloadCover(urlString: "https://coverartarchive.org/release/\(releaseID)/front") {
            return image
        }
        if let releaseGroupID {
            return await downloadCover(urlString: "https://coverartarchive.org/release-group/\(releaseGroupID)/front")
        }
        return nil
    }

    private static func downloadCover(urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let isJPEG = data.starts(with: [0xFF, 0xD8, 0xFF])
            let isPNG = data.starts(with: [0x89, 0x50, 0x4E, 0x47])
            guard isJPEG || isPNG, data.count < 15_000_000 else { return nil }
            return data
        } catch {
            return nil
        }
    }
}

private actor RequestThrottle {
    private var lastRequest = Date.distantPast

    func wait() async {
        let gap = Date().timeIntervalSince(lastRequest)
        if gap < 1.1 {
            let remaining = 1.1 - gap
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }
        lastRequest = Date()
    }
}

private struct CachedMatch {
    let match: MusicBrainzMetadata.Match?
}

private actor MatchCache {
    private var values: [String: CachedMatch] = [:]

    func stored(_ key: String) -> CachedMatch? {
        values[key]
    }

    func store(_ match: MusicBrainzMetadata.Match?, for key: String) {
        values[key] = CachedMatch(match: match)
    }
}

private struct RecordingSearch: Decodable {
    let recordings: [Recording]
}

private struct Recording: Decodable {
    let score: Int?
    let title: String
    let artistCredit: [ArtistCredit]?
    let releases: [Release]?

    enum CodingKeys: String, CodingKey {
        case score, title, releases
        case artistCredit = "artist-credit"
    }
}

private struct Release: Decodable {
    let id: String
    let title: String
    let status: String?
    let date: String?
    let artistCredit: [ArtistCredit]?
    let releaseGroup: ReleaseGroup?

    enum CodingKeys: String, CodingKey {
        case id, title, status, date
        case artistCredit = "artist-credit"
        case releaseGroup = "release-group"
    }
}

private struct ReleaseGroup: Decodable {
    let id: String
    let primaryType: String?
    let secondaryTypes: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case primaryType = "primary-type"
        case secondaryTypes = "secondary-types"
    }
}

private struct ArtistCredit: Decodable {
    let name: String?
    let artist: NamedArtist?
}

private struct NamedArtist: Decodable {
    let name: String
}
