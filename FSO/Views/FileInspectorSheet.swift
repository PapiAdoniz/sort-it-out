import SwiftUI

struct FileInspectorSheet: View {
    let files: [ScannedFile]
    @Binding var qualitySortOrder: QualitySortOrder
    var audioPreview: AudioPreviewManager
    @Environment(\.dismiss) private var dismiss

    private var sortedFiles: [ScannedFile] {
        let qualityOrder: [String] = ["Lossless", "High", "Medium", "Low"]
        return files.sorted { file1, file2 in
            let quality1 = file1.qualityLabel ?? "Unknown"
            let quality2 = file2.qualityLabel ?? "Unknown"
            let index1 = qualityOrder.firstIndex(of: quality1) ?? qualityOrder.count
            let index2 = qualityOrder.firstIndex(of: quality2) ?? qualityOrder.count
            
            if qualitySortOrder == .descending {
                return index1 < index2
            } else {
                return index1 > index2
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    qualitySortControls
                    fileListSection
                }
                .padding(20)
                .foregroundStyle(AppTheme.textPrimary)
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("File Inspector")
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

    private var qualitySortControls: some View {
        ModernCard(title: "Quality Sorting", systemImage: "line.3.horizontal.decrease.circle") {
            EmptyView()
        } content: {
            Picker("Sort Order", selection: $qualitySortOrder) {
                ForEach(QualitySortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue).tag(order)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: .infinity)
        }
    }

    private var fileListSection: some View {
        ModernCard(title: "Files by Quality", systemImage: "music.note.list") {
            EmptyView()
        } content: {
            VStack(spacing: 8) {
                ForEach(sortedFiles) { file in
                    fileInspectorRow(file)
                }
            }
        }
    }

    private func fileInspectorRow(_ file: ScannedFile) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(file.artist)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    Text(file.url.lastPathComponent)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                }

                Text(file.url.path)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            FormatBadge(label: file.formatLabel, quality: file.qualityLabel)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.rowFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
