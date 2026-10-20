import Foundation

struct SourceEntry: Identifiable, Hashable, Sendable {
    let url: URL
    let isFolder: Bool

    var id: URL { url.standardizedFileURL }
}
