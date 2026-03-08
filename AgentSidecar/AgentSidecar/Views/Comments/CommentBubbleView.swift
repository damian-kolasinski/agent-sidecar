import SwiftUI

struct CommentBubbleView: View {
    let comment: ReviewComment
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            HStack {
                Text(comment.author)
                    .font(DSFont.heading)

                Text(formattedDate)
                    .font(DSFont.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    appViewModel.toggleResolved(commentID: comment.id)
                } label: {
                    HStack(spacing: DSSpacing.xxs) {
                        Image(systemName: comment.resolved ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 12))
                        Text(comment.resolved ? "Resolved" : "Resolve")
                            .font(DSFont.caption)
                    }
                    .foregroundStyle(comment.resolved ? .green : .secondary)
                }
                .buttonStyle(.plain)
            }

            Text(comment.body)
                .font(DSFont.body)
                .textSelection(.enabled)
                .opacity(comment.resolved ? 0.6 : 1.0)
        }
        .padding(DSSpacing.commentPadding)
        .padding(.leading, DSSpacing.gutterWidth * 2)
        .background(DSColor.commentBackground)
        .overlay(
            Rectangle()
                .fill(DSColor.commentBorder)
                .frame(height: 1),
            alignment: .top
        )
    }

    private var formattedDate: String {
        comment.createdAt.formatted(date: .abbreviated, time: .shortened)
    }
}
