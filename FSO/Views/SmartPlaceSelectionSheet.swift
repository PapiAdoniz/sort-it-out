import SwiftUI

struct SmartPlaceSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let artistChoices: [ArtistChoice]
    let duplicates: [DuplicateConflict]
    let onProceed: ([String: URL], [URL: Bool]) -> Void

    @State private var selections: [String: URL] = [:]
    @State private var duplicateChoices: [URL: Bool] = [:] // true = replace, false = skip

    struct ArtistChoice: Identifiable {
        let id = UUID()
        let artist: String
        let songTitles: [String]
        let existingFolders: [URL]
        let isUnknown: Bool
    }

    struct DuplicateConflict: Identifiable {
        let id = UUID()
        let sourceURL: URL
        let destinationURL: URL
        let artist: String
        let fileName: String
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                content
                footer
            }
            .navigationTitle("Select Artist Folders")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Choose where to place each artist's music")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text("Select a folder for each artist below, or choose to create a new folder")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding()
        .background(AppTheme.rowFill)
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 12) {
                if !artistChoices.isEmpty {
                    Text("Artist Folders")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(artistChoices) { choice in
                        artistChoiceRow(choice)
                    }
                }

                if !duplicates.isEmpty {
                    Divider()
                        .padding(.vertical, 8)

                    Text("Duplicate Files")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(duplicates) { duplicate in
                        duplicateConflictRow(duplicate)
                    }
                }
            }
            .padding()
        }
    }

    private func artistChoiceRow(_ choice: ArtistChoice) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(choice.artist)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                // Show parent folder name next to artist if there's only one matching folder
                if choice.existingFolders.count == 1, let folder = choice.existingFolders.first {
                    if folder.pathComponents.count > 1 {
                        let parentFolder = folder.pathComponents.dropLast().last ?? ""
                        Text("• \(parentFolder)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.accent)
                    }
                }

                Spacer()
                if choice.isUnknown {
                    Text("Unknown Artist")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.accent)
                }
            }

            if !choice.songTitles.isEmpty {
                Text("Songs: \(choice.songTitles.prefix(3).joined(separator: ", "))\(choice.songTitles.count > 3 ? "..." : "")")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            if !choice.existingFolders.isEmpty {
                Text("Found in \(choice.existingFolders.count) existing folder\(choice.existingFolders.count == 1 ? "" : "s"):")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)

                VStack(spacing: 4) {
                    ForEach(choice.existingFolders, id: \.self) { folder in
                        folderOption(folder, artist: choice.artist)
                    }
                }
            }

            // Only show create new folder option if there are no existing folders
            if choice.existingFolders.isEmpty {
                createNewFolderOption(choice.artist)
            }
        }
        .padding()
        .background(AppTheme.rowFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func folderOption(_ folder: URL, artist: String) -> some View {
        HStack(spacing: 8) {
            Button {
                selections[artist] = folder
            } label: {
                HStack {
                    Image(systemName: "folder")
                        .foregroundStyle(AppTheme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(folder.lastPathComponent)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textPrimary)
                        // Show parent folder name as header
                        if folder.pathComponents.count > 1 {
                            let parentFolder = folder.pathComponents.dropLast().last ?? folder.path
                            Text(parentFolder)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    Spacer()
                    if selections[artist] == folder {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.accent)
                    } else {
                        Image(systemName: "circle")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    selections[artist] == folder ? AppTheme.accent.opacity(0.1) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                )
            }
            .buttonStyle(.plain)

            Button {
                #if os(macOS)
                NSWorkspace.shared.open(folder)
                #endif
            } label: {
                Image(systemName: "folder.badge.gearshape")
                    .foregroundStyle(AppTheme.textSecondary)
                    .help("Open in Finder")
            }
            .buttonStyle(.plain)
        }
    }

    private func createNewFolderOption(_ artist: String) -> some View {
        Button {
            selections[artist] = nil // nil means create new folder
        } label: {
            HStack {
                Image(systemName: "plus.circle")
                    .foregroundStyle(AppTheme.accent)
                Text("Create new folder '\(artist)'")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                if selections[artist] == nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                selections[artist] == nil ? AppTheme.accent.opacity(0.1) : Color.clear,
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func duplicateConflictRow(_ duplicate: DuplicateConflict) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text(duplicate.fileName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(duplicate.artist)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Text("File already exists at destination")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 8) {
                Button {
                    duplicateChoices[duplicate.sourceURL] = true // replace
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(AppTheme.accent)
                        Text("Replace")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        if duplicateChoices[duplicate.sourceURL] == true {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.accent)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        duplicateChoices[duplicate.sourceURL] == true ? AppTheme.accent.opacity(0.1) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    duplicateChoices[duplicate.sourceURL] = false // skip
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(.red)
                        Text("Skip")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        if duplicateChoices[duplicate.sourceURL] == false {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.accent)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        duplicateChoices[duplicate.sourceURL] == false ? AppTheme.accent.opacity(0.1) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(AppTheme.rowFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)

            Button("Proceed") {
                onProceed(selections, duplicateChoices)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!allSelectionsMade)
        }
        .padding()
        .background(AppTheme.rowFill)
    }

    private var allSelectionsMade: Bool {
        let artistSelectionsComplete = artistChoices.allSatisfy { choice in
            selections[choice.artist] != nil || choice.existingFolders.isEmpty
        }
        let duplicateSelectionsComplete = duplicates.allSatisfy { duplicate in
            duplicateChoices[duplicate.sourceURL] != nil
        }
        return artistSelectionsComplete && duplicateSelectionsComplete
    }
}

#Preview {
    SmartPlaceSelectionSheet(
        artistChoices: [
            SmartPlaceSelectionSheet.ArtistChoice(
                artist: "Taylor Swift",
                songTitles: ["Shake It Off", "Blank Space", "Love Story"],
                existingFolders: [
                    URL(fileURLWithPath: "/Music/Taylor Swift"),
                    URL(fileURLWithPath: "/Music/Artists/Taylor Swift")
                ],
                isUnknown: false
            ),
            SmartPlaceSelectionSheet.ArtistChoice(
                artist: "Unknown Artist",
                songTitles: ["Unknown Song 1", "Unknown Song 2"],
                existingFolders: [],
                isUnknown: true
            )
        ],
        duplicates: [
            SmartPlaceSelectionSheet.DuplicateConflict(
                sourceURL: URL(fileURLWithPath: "/Downloads/song.mp3"),
                destinationURL: URL(fileURLWithPath: "/Music/Taylor Swift/song.mp3"),
                artist: "Taylor Swift",
                fileName: "song.mp3"
            )
        ],
        onProceed: { _, _ in }
    )
}
