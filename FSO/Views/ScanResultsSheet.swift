import SwiftUI

enum ScanResultsViewMode: String, CaseIterable, Identifiable {
    case bySource = "By Source"
    case byType = "By Type"
    case all = "All Files"

    var id: String { rawValue }
}

struct ScanResultsSheet: View {
    let files: [ScannedFile]
    let sourceGroups: [SourceScanGroup]
    let summary: ScanFormatSummary
    @Environment(\.dismiss) private var dismiss
    @State private var audioPreview = AudioPreviewManager()

    @State private var viewMode: ScanResultsViewMode = .bySource

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summaryBanner
                    formatBreakdown
                    fileListSection
                }
                .padding(20)
                .foregroundStyle(AppTheme.textPrimary)
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Scan Results")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.textPrimary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Picker("View", selection: $viewMode) {
                        ForEach(ScanResultsViewMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 280)
                }
            }
        }
        .tint(AppTheme.textPrimary)
        .preferredColorScheme(.dark)
        .frame(minWidth: 900, idealWidth: 1000)
        .onDisappear {
            audioPreview.stopPreview()
        }
    }

    private var summaryBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: summary.isMix ? "square.stack.3d.up.fill" : "doc.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.textPrimary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(summary.totalCount) file\(summary.totalCount == 1 ? "" : "s") scanned")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(summary.headline)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)

                    if sourceGroups.count > 1 {
                        Text("From \(sourceGroups.count) sources")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.rowFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
        }
    }

    private var formatBreakdown: some View {
        ModernCard(title: "File Types", systemImage: "waveform") {
            EmptyView()
        } content: {
            FlowLayout(spacing: 8) {
                ForEach(summary.breakdown, id: \.label) { item in
                    HStack(spacing: 6) {
                        FormatBadge(label: item.label, quality: nil)
                        Text("×\(item.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
            }
        }
    }

    private var fileListSection: some View {
        ModernCard(title: listSectionTitle, systemImage: "music.note.list") {
            EmptyView()
        } content: {
            switch viewMode {
            case .bySource:
                bySourceList
            case .byType:
                byTypeList
            case .all:
                flatFileList
            }
        }
    }

    private var listSectionTitle: String {
        switch viewMode {
        case .bySource: return "Songs by Source"
        case .byType: return "Songs by File Type"
        case .all: return "All Scanned Songs"
        }
    }

    private var bySourceList: some View {
        VStack(spacing: 8) {
            ForEach(sourceGroups.flatMap(\.files)) { file in
                scannedFileRow(file, showSource: true)
            }
        }
    }

    private func sourceGroupHeader(_ group: SourceScanGroup) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.lightGray)
                    .frame(width: 32, height: 32)
                Image(systemName: group.isFolder ? "folder.fill" : "music.note")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                Text(group.path)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                CountBadge(count: group.files.count)
                if !group.formatSummary.isEmpty {
                    Text(group.formatSummary)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.midGray, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
        }
    }

    private var byTypeList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(summary.breakdown, id: \.label) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        FormatBadge(label: item.label, quality: nil)
                        Text("\(item.count) file\(item.count == 1 ? "" : "s")")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    ForEach(files.filter { $0.formatLabel == item.label }) { file in
                        scannedFileRow(file, showFormat: false)
                    }
                }
            }
        }
    }

    private var flatFileList: some View {
        VStack(spacing: 8) {
            ForEach(files) { file in
                scannedFileRow(file, showSource: true)
            }
        }
    }

    private func scannedFileRow(_ file: ScannedFile, showFormat: Bool = true, showSource: Bool = false) -> some View {
        HStack(spacing: 14) {
            Button {
                audioPreview.playPreview(url: file.url)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.accent.opacity(0.3))
                        .frame(width: 36, height: 36)
                    Image(systemName: audioPreview.currentPreviewURL == file.url && audioPreview.isPlaying ? "pause.fill" : "play.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .buttonStyle(.plain)
            .help("Preview audio file")

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    Text(file.artist)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    Text(file.url.lastPathComponent)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    if file.isDuplicate {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text("Already exists")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Text(file.url.path)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(nil)

                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.accent)
                    Text("Send to: \(file.plannedDestinationURL.path)")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(nil)
                }

                if showSource {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(file.sourceOriginName)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(1)
                    }
                }

                if file.isDuplicate, let destURL = file.duplicateDestinationURL {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("Destination: \(destURL.path)")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)

            if showFormat {
                FormatBadge(label: file.formatLabel, quality: file.qualityLabel)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(file.isDuplicate ? Color.orange.opacity(0.1) : AppTheme.rowFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(file.isDuplicate ? Color.orange : AppTheme.cardStroke, lineWidth: file.isDuplicate ? 2 : 1)
                }
        )
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
    }
}

/// Simple horizontal flow for format chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
