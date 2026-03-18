import SwiftUI

struct PlanCommentBubbleView: View {
    let planComment: PlanComment
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            Text(planComment.comment)
                .font(DSFont.body)
                .textSelection(.enabled)
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
