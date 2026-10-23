import AVFoundation
import CoreMedia
import Foundation

extension Double {
    var clean: String {
        String(format: "%.1f", self).replacingOccurrences(of: ".0", with: "")
    }
}

enum MusicMetadataReader {
    private static let supportedExtensions: Set<String> = [
        "mp3", "m4a", "aac", "flac", "wav", "aiff", "aif", "ogg", "wma", "alac"
    ]

    private static let displayNames: [String: String] = [
        "mp3": "MP3", "m4a": "M4A", "aac": "AAC", "flac": "FLAC",
        "wav": "WAV", "aiff": "AIFF", "aif": "AIF", "ogg": "OGG",
        "wma": "WMA", "alac": "ALAC"
    ]

    private static var qualityCache: [String: String?] = [:]
    private static var artistCache: [String: String] = [:]
    private static var albumCache: [String: String?] = [:]
    private static let cacheLock = NSLock()

    static func isSupportedAudioFile(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }

    static func formatLabel(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        return displayNames[ext] ?? ext.uppercased()
    }

    static func qualityLabel(for url: URL) -> String? {
        let cacheKey = url.path
        cacheLock.lock()
        if let cached = qualityCache[cacheKey] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        let asset = AVURLAsset(url: url)

        guard let track = asset.tracks(withMediaType: .audio).first else {
            cacheLock.lock()
            qualityCache[cacheKey] = nil
            cacheLock.unlock()
            return nil
        }

        guard let formatDescriptions = track.formatDescriptions as? [CMFormatDescription],
              let formatDescription = formatDescriptions.first else {
            cacheLock.lock()
            qualityCache[cacheKey] = nil
            cacheLock.unlock()
            return nil
        }

        // Try to get audio format description
        guard let audioFormatDescription = formatDescription as? CMAudioFormatDescription else {
            cacheLock.lock()
            qualityCache[cacheKey] = nil
            cacheLock.unlock()
            return nil
        }

        // Get stream basic description (returns pointer directly)
        guard let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDescription) else {
            cacheLock.lock()
            qualityCache[cacheKey] = nil
            cacheLock.unlock()
            return nil
        }

        // Format quality label
        let sampleRateKHz = Double(asbd.pointee.mSampleRate) / 1000.0
        let bitsPerChannel = asbd.pointee.mBitsPerChannel

        let result: String?
        if bitsPerChannel > 0 {
            result = "\(sampleRateKHz.clean)kHz / \(bitsPerChannel)bit"
        } else {
            result = "\(sampleRateKHz.clean)kHz"
        }

        cacheLock.lock()
        qualityCache[cacheKey] = result
        cacheLock.unlock()
        return result
    }

    static func clearCache() {
        cacheLock.lock()
        artistCache.removeAll()
        albumCache.removeAll()
        cacheLock.unlock()
    }

    static func artist(from url: URL) async -> String {
        let cacheKey = url.standardizedFileURL.path
        cacheLock.lock()
        if let cached = artistCache[cacheKey] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        var result: String
        let taggedArtist = await readTaggedArtist(from: url).map(sanitizePrimaryArtistName)
        let filenameArtist = artistFromFilename(url.deletingPathExtension().lastPathComponent)
            .map(sanitizePrimaryArtistName)
        if let taggedArtist, !isTrackNumber(taggedArtist) {
            result = taggedArtist
        } else if let filenameArtist, !isTrackNumber(filenameArtist) {
            result = filenameArtist
        } else if let albumArtist = await readAlbumArtist(from: url) {
            let cleaned = sanitizePrimaryArtistName(albumArtist)
            result = isTrackNumber(cleaned) ? "Unknown Artist" : cleaned
        } else {
            result = "Unknown Artist"
        }

        cacheLock.lock()
        artistCache[cacheKey] = result
        cacheLock.unlock()
        return result
    }

    static func title(from url: URL) async -> String? {
        if let tagged = await readMetadataString(from: url, identifiers: [
            .commonIdentifierTitle,
            .iTunesMetadataSongName,
            .id3MetadataTitleDescription
        ]) {
            let trimmed = tagged.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return titleFromFilename(url.deletingPathExtension().lastPathComponent)
    }

    static func album(from url: URL) async -> String? {
        let cacheKey = url.standardizedFileURL.path
        cacheLock.lock()
        if let cached = albumCache[cacheKey] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        let result = await readMetadataString(from: url, identifiers: [
            .commonIdentifierAlbumName,
            .iTunesMetadataAlbum,
            .id3MetadataAlbumTitle
        ]).map { sanitizeArtistName($0) }

        cacheLock.lock()
        albumCache[cacheKey] = result
        cacheLock.unlock()
        return result
    }

    private static func readAlbumArtist(from url: URL) async -> String? {
        await readMetadataString(from: url, identifiers: [
            .iTunesMetadataAlbumArtist,
            .id3MetadataBand
        ])
    }

    private static func readTaggedArtist(from url: URL) async -> String? {
        await readMetadataString(from: url, identifiers: [
            .commonIdentifierArtist,
            .iTunesMetadataArtist,
            .id3MetadataLeadPerformer
        ])
    }

    private static func readMetadataString(from url: URL, identifiers: [AVMetadataIdentifier]) async -> String? {
        let asset = AVURLAsset(url: url)

        do {
            let metadata = try await asset.load(.metadata)
            for identifier in identifiers {
                let items = AVMetadataItem.metadataItems(
                    from: metadata,
                    filteredByIdentifier: identifier
                )

                for item in items {
                    if let value = try? await item.load(.stringValue) {
                        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            return trimmed
                        }
                    }
                }
            }
        } catch {
            return nil
        }

        return nil
    }

    private static func titleFromFilename(_ filename: String) -> String? {
        var name = filename.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = name.range(of: #"^\d{1,3}[\s.\-_]+"#, options: .regularExpression) {
            name.removeSubrange(range)
        }

        let separators = [" - ", " – ", " — "]
        for separator in separators {
            let parts = name.components(separatedBy: separator)
            if parts.count >= 2 {
                let title = parts.dropFirst().joined(separator: separator)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty {
                    return title
                }
            }
        }

        return name.isEmpty ? nil : name
    }

    private static func artistFromFilename(_ filename: String) -> String? {
        let separators = [" - ", " – ", " — "]
        for separator in separators {
            let parts = filename.components(separatedBy: separator)
            guard parts.count >= 2 else { continue }
            for candidate in parts.dropLast() {
                let name = nameWithoutLeadingTrackNumber(candidate)
                if name.isEmpty || isTrackNumber(name) { continue }
                return name
            }
        }
        return nil
    }

    private static func nameWithoutLeadingTrackNumber(_ text: String) -> String {
        var name = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = name.range(of: #"^\d{1,3}[\s.\-_]+"#, options: .regularExpression) {
            name.removeSubrange(range)
        }
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isTrackNumber(_ text: String) -> Bool {
        text.range(
            of: #"^\d{1,3}([.\-_]\d{1,3})?$"#,
            options: .regularExpression
        ) != nil
    }

    private static func year(in text: String) -> String? {
        guard let range = text.range(of: #"(?:19|20)\d{2}"#, options: .regularExpression) else { return nil }
        return String(text[range])
    }

    private static func isAlbumExtra(_ text: String) -> Bool {
        text.range(
            of: #"\b(?:deluxe|explicit|remaster(?:ed)?|edition|version|bonus|expanded|anniversary|web|flac|aac|mp3|alac|clean|dirty|single|ep|feat\.?|ft\.?|featuring|radio edit)\b"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }

    /// Drops edition and format tags. A year in the name is kept.
    static func cleanAlbumName(_ name: String) -> String {
        var result = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var keptYear: String?
        let trailingGroup = #"\s*[\(\[]([^\)\]]*)[\)\]]\s*$"#
        let trailingLabel = #"(?i)\s+-\s+(?:single|ep)\s*$"#

        var didStrip = true
        while didStrip {
            didStrip = false
            if let range = result.range(of: trailingLabel, options: .regularExpression) {
                result.removeSubrange(range)
                result = result.trimmingCharacters(in: .whitespacesAndNewlines)
                didStrip = true
                continue
            }

            guard let range = result.range(of: trailingGroup, options: .regularExpression),
                  let innerRange = result.range(of: #"[\(\[]([^\)\]]*)[\)\]]\s*$"#, options: .regularExpression) else {
                break
            }
            let inside = String(result[innerRange])
                .trimmingCharacters(in: CharacterSet(charactersIn: "()[] \t"))
            let year = year(in: inside)

            if year != nil, inside.range(of: #"^(19|20)\d{2}$"#, options: .regularExpression) != nil {
                keptYear = year
                result.removeSubrange(range)
                result = result.trimmingCharacters(in: .whitespacesAndNewlines)
                didStrip = true
                continue
            }

            if isAlbumExtra(inside) {
                if keptYear == nil {
                    keptYear = year
                }
                result.removeSubrange(range)
                result = result.trimmingCharacters(in: .whitespacesAndNewlines)
                didStrip = true
            }
        }

        if let keptYear, result.range(of: keptYear) == nil {
            result += " (\(keptYear))"
        }

        let cleaned = sanitizeArtistName(result)
        if cleaned == "Unknown Artist" {
            return sanitizeArtistName(name)
        }
        return cleaned
    }

    static func folderNamesMatch(_ lhs: String, _ rhs: String) -> Bool {
        let left = lhs.trimmingCharacters(in: .whitespacesAndNewlines)
        let right = rhs.trimmingCharacters(in: .whitespacesAndNewlines)
        return left.compare(right, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
    }

    static func sanitizeArtistName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Unknown Artist" }

        let invalidCharacters = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        var sanitized = trimmed
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if sanitized.count > 240 {
            sanitized = String(sanitized.prefix(240))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return sanitized.isEmpty ? "Unknown Artist" : sanitized
    }

    static func sanitizePrimaryArtistName(_ name: String) -> String {
        let patterns = [
            #"\s*[\(\[]\s*(feat\.?|ft\.?|featuring|with)\b.*$"#,
            #"\s+(feat\.?|ft\.?|featuring|with)\b.*$"#,
            #"\s+x\s+.*$"#
        ]

        var primary = name.trimmingCharacters(in: .whitespacesAndNewlines)
        for pattern in patterns {
            if let range = primary.range(
                of: pattern,
                options: [.regularExpression, .caseInsensitive]
            ) {
                primary = String(primary[..<range.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }

        return sanitizeArtistName(primary)
    }

    /// Name before a shared credit such as "A & B" or "A and B".
    static func leadingArtistName(_ name: String) -> String {
        let featured = sanitizePrimaryArtistName(name)
        let patterns = [
            #"\s+&\s+.*$"#,
            #"\s+and\s+.*$"#,
            #"\s+/\s+.*$"#
        ]

        var primary = featured
        for pattern in patterns {
            if let range = primary.range(
                of: pattern,
                options: [.regularExpression, .caseInsensitive]
            ) {
                primary = String(primary[..<range.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }

        return sanitizeArtistName(primary)
    }
}
