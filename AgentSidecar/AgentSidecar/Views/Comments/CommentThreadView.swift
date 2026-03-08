import SwiftUI

struct CommentThreadView: View {
    let comments: [ReviewComment]
    let anchor: String
    @EnvironmentObject var detailViewModel: DiffDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thread header
            Button {
                detailViewModel.toggleThread(anchor)
            } label: {
                HStack(spacing: DSSpacing.xs) {
                    Image(systemName: detailViewModel.isThreadExpanded(anchor) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10))
                    Text("\(comments.count) comment\(comments.count == 1 ? "" : "s")")
                        .font(DSFont.caption)
                    Spacer()
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, DSSpacing.commentPadding)
                .padding(.vertical, DSSpacing.xs)
            }
            .buttonStyle(.plain)
            .padding(.leading, DSSpacing.gutterWidth * 2)

            // Expanded comments
            if detailViewModel.isThreadExpanded(anchor) {
                ForEach(comments) { comment in
                    CommentBubbleView(comment: comment)
                }
            }
        }
        .background(DSColor.commentBackground)
        .onAppear {
            // Auto-expand if there are comments
            if !comments.isEmpty {
                detailViewModel.expandedThreads.insert(anchor)
            }
        }
    }
}
