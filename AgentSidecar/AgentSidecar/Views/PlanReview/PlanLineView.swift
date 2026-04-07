import SwiftUI

struct PlanLineView: View {
    let line: String
    let lineIndex: Int
    let commentsForLine: [PlanComment]
    let onAddComment: (String) -> Void
    let onRemoveComment: (UUID) -> Void

    @State private var isHovering = false
    @State private var isComposing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                // Gutter with + button
                ZStack {
                    if isHovering && !line.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button {
                            isComposing = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(DSColor.gutterHoverIcon)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: DSSpacing.gutterWidth, height: DSSpacing.lineHeight)
                .background(DSColor.gutterBackground)
                .contentShape(Rectangle())

                // Line content
                styledText
                    .font(fontForLine)
                    .padding(.leading, leadingIndent)
                    .frame(maxWidth: .infinity, minHeight: DSSpacing.lineHeight, alignment: .leading)
                    .padding(.horizontal, DSSpacing.sm)
                    .textSelection(.enabled)
            }
            .background(DSColor.contextBackground)
            .onHover { hovering in
                isHovering = hovering
            }

            // Inline comments
            ForEach(commentsForLine) { planComment in
                PlanCommentBubbleView(
                    planComment: planComment,
                    onRemove: { onRemoveComment(planComment.id) }
                )
            }

            // Composer
            if isComposing {
                InlineCommentComposer(
                    onSubmit: { text in
                        onAddComment(text)
                        isComposing = false
                    },
                    onCancel: {
                        isComposing = false
                    }
                )
            }
        }
    }

    private var styledText: Text {
        MarkdownTextStyle.text(for: line)
    }

    private var fontForLine: Font {
        MarkdownTextStyle.font(for: line)
    }

    private var leadingIndent: CGFloat {
        MarkdownTextStyle.leadingIndent(for: line)
    }
}
