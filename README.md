# Sort It Out

Sort It Out is a Mac music organizer. Add the folders and files you want to look through, scan them for artist, format, and quality, preview a song, and file new downloads into the library you already keep.

The Xcode project is named FSO. The app you install is **Sort It Out**.

## What it does

- **Add.** Choose several folders or individual songs. Command-click selects more than one item in the same folder.
- **Scan.** Reads artist, format, and quality, and leaves every file where it is. Preview a song before you move anything.
- **Scan Details.** Browse what was scanned by source, by type, or as one list, with format, quality, and paths.
- **File Inspector.** Sort the scanned files by quality and preview audio.
- **Smart Place.** Set a watch folder (such as Downloads) and a library folder. Smart Place shows where the new songs will go and moves them only after you confirm.
- **Folder styles.** Use one folder per artist, or artist and album folders. A featured credit stays with the main artist. A song tagged with both names follows the majority, and a song from the album stays with that album.
- **MusicBrainz.** A match uses the album’s artist, then saves that release’s cover in the folder.
- **Folder Stalker.** Keep folders you browse often, view them together or by artist, and choose the song title color.

Supported audio includes MP3, M4A, AAC, FLAC, WAV, AIFF, OGG, WMA, and ALAC.

## Requirements

- macOS 26.3 or later
- Apple silicon or Intel Mac

## Install on a Mac

1. Download [`Sort.It.Out-1.3.1.dmg`](https://github.com/PapiAdoniz/sort-it-out/releases/tag/v1.3.1).
2. Open the disk image.
3. Drag **Sort It Out** onto **Applications**.
4. Eject the disk image and open Sort It Out from Applications.

The first time you open it, macOS may say the app is from an unidentified developer. The build is signed for development and is not notarized. Right-click **Sort It Out**, choose **Open**, then choose **Open** again. You only need to do that once.

## First run

1. Click **Add** and choose the music you want to look through.
2. Click **Scan** to see artist, format, and quality, and to preview a song. Scanning does not move files.
3. Open **Settings**, choose a watch folder and a library folder, and pick a folder style.
4. Click **Smart Place**, review where the songs will go, then confirm the move.

## Windows

There is no Windows installer. Sort It Out uses the Mac file picker, sandboxed folder access, and Apple’s audio frameworks. Those pieces do not run on Windows, so Sort It Out is Mac only.

## Build from source

Open `FSO.xcodeproj` in Xcode 26 or later and run the **Sort It Out** scheme. To build a release from the command line:

```bash
xcodebuild -project FSO.xcodeproj -scheme "Sort It Out" -configuration Release -destination "platform=macOS" -sdk macosx build
```

The built app is `Sort It Out.app`.
