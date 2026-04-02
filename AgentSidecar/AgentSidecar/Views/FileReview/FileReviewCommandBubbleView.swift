import SwiftUI

struct FileReviewCommandBubbleView: View {
    let command: FileReviewCommand
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text("Command")
                    .font(DSFont.caption)
                    .foregroundStyle(.secondary)
                Text(command.command)
                    .font(DSFont.body)
                    .textSelection(.enabled)
            }
            Spacer()
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(DSSpacing.commentPadding)
        .padding(.leading, DSSpacing.gutterWidth)
        .background(DSColor.commentBackground)
        .overlay(
            Rectangle()
                .fill(DSColor.commentBorder)
                .frame(height: 1),
            alignment: .top
        )
    }
}
