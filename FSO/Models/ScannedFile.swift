import Foundation

struct ScannedFile: Identifiable, Sendable, Equatable {
    let id = UUID()
    let url: URL
    let fileName: String
    let formatLabel: String
    let qualityLabel: String?
    let artist: String
    let plannedDestinationURL: URL
    let sourceOriginURL: URL
    let sourceOriginName: String
    let sourceIsFolder: Bool
    var isDuplicate: Bool = false
    var duplicateDestinationURL: URL?

    static func == (lhs: ScannedFile, rhs: ScannedFile) -> Bool {
        lhs.id == rhs.id
    }
}

struct SourceScanGroup: Identifiable, Sendable {
    let id: URL
    let name: String
    let path: String
    let isFolder: Bool
    let files: [ScannedFile]

    var formatSummary: String {
        let grouped = Dictionary(grouping: files, by: \.formatLabel)
        return grouped
            .map { "\($0.value.count) \($0.key)" }
            .sorted()
            .joined(separator: ", ")
    }

    static func from(files: [ScannedFile], sources: [SourceEntry]) -> [SourceScanGroup] {
        let sourceOrder = sources.map(\.id)
        let grouped = Dictionary(grouping: files) { $0.sourceOriginURL.standardizedFileURL }

        return sourceOrder.compactMap { origin in
            guard let groupFiles = grouped[origin], !groupFiles.isEmpty else { return nil }
            let source = sources.first { $0.id == origin }
            let isFolder = source?.isFolder ?? groupFiles[0].sourceIsFolder
            let sortedFiles = groupFiles.sorted {
                $0.fileName.localizedCaseInsensitiveCompare($1.fileName) == .orderedAscending
            }

            return SourceScanGroup(
                id: origin,
                name: origin.lastPathComponent,
                path: isFolder ? origin.path : origin.deletingLastPathComponent().path,
                isFolder: isFolder,
                files: sortedFiles
            )
        }
    }
}

struct ScanFormatSummary: Sendable {
    let breakdown: [(label: String, count: Int)]

    var totalCount: Int {
        breakdown.reduce(0) { $0 + $1.count }
    }

    var isMix: Bool {
        breakdown.filter { $0.count > 0 }.count > 1
    }

    var headline: String {
        let active = breakdown.filter { $0.count > 0 }
        guard !active.isEmpty else { return "No files scanned" }

        if active.count == 1 {
            return "All \(active[0].label) files"
        }

        return "Mix of " + active.map { "\($0.count) \($0.label)" }.joined(separator: ", ")
    }

    static func from(files: [ScannedFile]) -> ScanFormatSummary {
        let grouped = Dictionary(grouping: files, by: \.formatLabel)
        let breakdown = grouped
            .map { (label: $0.key, count: $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.label < rhs.label
                }
                return lhs.count > rhs.count
            }

        return ScanFormatSummary(breakdown: breakdown)
    }
}
