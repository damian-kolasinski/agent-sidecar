import SwiftUI

struct HunkHeaderView: View {
    let header: String

    var body: some View {
        HStack(spacing: 0) {
            // Gutter area
            Rectangle()
                .fill(DSColor.hunkHeaderBackground)
                .frame(width: DSSpacing.gutterWidth * 2)

            // Header content
            Text(header)
                .font(DSFont.code)
                .foregroundStyle(DSColor.hunkHeaderText)
                .padding(.horizontal, DSSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: DSSpacing.hunkHeaderHeight)
        .background(DSColor.hunkHeaderBackground)
    }
}
