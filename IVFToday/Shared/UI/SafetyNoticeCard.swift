import SwiftUI

struct SafetyNoticeCard: View {
    let title: String
    let message: String
    let theme: AppTheme.Palette

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "cross.case.fill")
                .foregroundColor(theme.secondaryAccent)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundColor(theme.mutedText)
            }
            Spacer()
        }
        .padding(12)
        .background(theme.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
