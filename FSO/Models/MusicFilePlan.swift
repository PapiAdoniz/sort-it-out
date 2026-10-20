import Foundation

struct MusicFilePlan: Identifiable, Sendable {
    let id = UUID()
    let sourceURL: URL
    let sourceOrigin: URL
    let artist: String
    let destinationURL: URL
    var releaseID: String? = nil
    var releaseGroupID: String? = nil
    var isDuplicate: Bool = false
}

struct ArtistGroup: Identifiable, Sendable {
    let id: String
    let artist: String
    let files: [MusicFilePlan]

    init(artist: String, files: [MusicFilePlan]) {
        self.artist = artist
        self.files = files
        self.id = artist
    }
}
