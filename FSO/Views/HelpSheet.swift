import SwiftUI

struct HelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    welcomeSection
                    quickStartSection
                    featuresSection
                    smartPlaceSection
                    sortingSection
                    folderStalkerSection
                    tipsSection
                }
                .padding(20)
            }
            .foregroundStyle(AppTheme.textPrimary)
            .navigationTitle("How to Use")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
        .tint(AppTheme.textPrimary)
        .preferredColorScheme(.dark)
        .frame(minWidth: 600, minHeight: 500)
    }

    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome to Sort It Out")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.accent)
            Text("Your music organizer for looking through files you add, moving downloads into your library, and keeping watched folders easy to browse.")
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var quickStartSection: some View {
        ModernCard(title: "Quick Start", systemImage: "bolt.fill") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 12) {
                helpStep(
                    number: 1,
                    title: "Add Music",
                    description: "Click the Add button to select folders or music files you want to look through."
                )
                helpStep(
                    number: 2,
                    title: "Scan",
                    description: "Click Scan to see the artist, format, and quality, and to preview a song. Scan leaves every file where it is."
                )
                helpStep(
                    number: 3,
                    title: "Use Smart Place",
                    description: "Set a watch folder and library folder in Settings, then click Smart Place to move new downloads into your library."
                )
            }
        }
    }

    private var featuresSection: some View {
        ModernCard(title: "Main Features", systemImage: "star.fill") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 16) {
                featureItem(
                    icon: "plus.circle.fill",
                    title: "Add",
                    description: "Select multiple folders or individual music files. Use ⌘-click to select multiple items in the same folder."
                )
                featureItem(
                    icon: "magnifyingglass",
                    title: "Scan",
                    description: "Reads the artist, format, and quality for each added file, and lets you preview a song."
                )
                featureItem(
                    icon: "list.bullet.rectangle",
                    title: "Scan Details",
                    description: "Shows all scanned songs by source, type, or one full list, with format, quality, source, and destination paths."
                )
                featureItem(
                    icon: "doc.text.magnifyingglass",
                    title: "File Inspector",
                    description: "Lets you inspect scanned files, sort by quality, and preview audio."
                )
            }
        }
    }

    private var smartPlaceSection: some View {
        ModernCard(title: "Smart Place", systemImage: "wand.and.stars") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 16) {
                Text("Automatically place downloads, albums, and singles")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                VStack(alignment: .leading, spacing: 12) {
                    featureItem(
                        icon: "gear",
                        title: "Settings",
                        description: "Click the gear icon to choose the watch folder, library folder, and Smart Place sorting behavior."
                    )
                    featureItem(
                        icon: "tray.and.arrow.down",
                        title: "Watch Folder",
                        description: "This is where new music lands, such as Downloads. Smart Place scans audio directly inside it and inside download subfolders."
                    )
                    featureItem(
                        icon: "music.note.list",
                        title: "Library Folder",
                        description: "This is where organized music should live. Smart Place matches existing artist folders or creates new ones."
                    )
                    featureItem(
                        icon: "person.2.fill",
                        title: "Featured Artists",
                        description: "Smart Place uses the artist most of the download belongs to. A featured credit stays with that artist. A song tagged with both names follows the majority, and a song from the album stays in the album."
                    )
                    featureItem(
                        icon: "rectangle.stack.fill",
                        title: "Already filed music",
                        description: "Scan lists every song in the folders you add, including songs inside inner folders. Smart Place files the watch folder and leaves a song already in the library where it is."
                    )
                    featureItem(
                        icon: "music.note.list",
                        title: "MusicBrainz",
                        description: "Smart Place looks each song up on MusicBrainz. A match uses the album's artist, so a featured credit stays in that artist's folder, then saves that release's cover."
                    )
                    featureItem(
                        icon: "wand.and.stars",
                        title: "Smart Place Button",
                        description: "Click Smart Place to move supported audio from the watch folder into the library folder using your sorting settings."
                    )
                }
            }
        }
    }

    private var sortingSection: some View {
        ModernCard(title: "Smart Place Sorting", systemImage: "slider.horizontal.3") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 16) {
                Text("Open Settings with the gear icon. Smart Place puts a download in the folder of the artist most of those songs belong to, then uses the folder style you pick.")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                featureItem(
                    icon: "person.2.fill",
                    title: "Majority artist",
                    description: "If most songs in a download are one artist, the rest go in that artist's folder. A featured credit stays with that artist, and a song tagged with both names follows the majority."
                )
                featureItem(
                    icon: "person.crop.square",
                    title: "Artist Folders",
                    description: "Every song goes to Artist/song.ext, in one folder for that artist."
                )
                featureItem(
                    icon: "rectangle.stack.fill",
                    title: "Artist / Album Folders",
                    description: "A song goes to Artist/Album/song.ext from its album name, even when it is the only one. A song filed with those tracks joins that album folder."
                )
            }
        }
    }

    private var folderStalkerSection: some View {
        ModernCard(title: "Folder Stalker", systemImage: "folder.badge.gearshape") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 16) {
                featureItem(
                    icon: "folder.fill",
                    title: "Tracked folders",
                    description: "Add folders you want to browse often. The app remembers them after you reopen it."
                )
                featureItem(
                    icon: "list.bullet",
                    title: "Display mode",
                    description: "Use All Together for one list, or By Artist to group the tracked folder's songs by detected artist."
                )
                featureItem(
                    icon: "paintbrush.fill",
                    title: "Song title color",
                    description: "Pick the color used for song titles in Folder Stalker."
                )
            }
        }
    }

    private var tipsSection: some View {
        ModernCard(title: "Tips", systemImage: "lightbulb.fill") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 10) {
                tip("Smart Place creates an artist folder when that artist is not already at the top of your library.")
                tip("It matches that top artist folder when the artist name is the same.")
                tip("Use Scan to review artist, format, and quality, and to preview a song. Smart Place is what moves files into your library.")
                tip("With Artist / Album Folders, one song is enough to make Artist/Album/. A song with its own album name keeps that album.")
                tip("Messy tags: use Organized for normal downloads, Cautious when tags are often wrong, or Loose if you want singles in the artist folder.")
                tip("Tidy loose songs in Settings moves songs sitting in an artist folder into album or _Unsorted subfolders, with the same review step as Smart Place.")
                tip("Unknown artists or more than one matching artist folder may ask you to choose where the music should go.")
                tip("Use the x button in settings to remove configured watch, library, or tracked folders.")
            }
        }
    }

    private func helpStep(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28, height: 28)
                .background(AppTheme.accent.opacity(0.2), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    private func featureItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    private func tip(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(AppTheme.accent)
            Text(text)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}
