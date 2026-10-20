import SwiftUI

struct CompletionBannerView: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(AppTheme.textPrimary)
                .font(.subheadline.weight(.semibold))

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.rowFill)
                .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }
}

struct CompletionBannerView_Previews: PreviewProvider {
    static var previews: some View {
        CompletionBannerView(message: "Smart Place complete — moved 42 files.")
            .preferredColorScheme(.dark)
    }
}
