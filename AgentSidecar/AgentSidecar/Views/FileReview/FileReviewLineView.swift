import SwiftUI

struct FileReviewLineView: View {
    let line: String
    let lineNumber: Int
    let isMarkdown: Bool
    let commandsForLine: [FileReviewCommand]
    let onAddCommand: (String) -> Void
    let onRemoveCommand: (UUID) -> Void

    @State private var isHovering = false
    @State private var isComposing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                LineGutterView(
                    lineNumber: lineNumber,
                    type: .context,
                    isHovering: isHovering && canComment,
                    onTap: {
                        guard canComment else { return }
                        isComposing = true
                    }
                )

                lineText
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

            ForEach(commandsForLine) { command in
                FileReviewCommandBubbleView(
                    command: command,
                    onRemove: { onRemoveCommand(command.id) }
                )
            }

            if isComposing {
                InlineCommentComposer(
                    onSubmit: { text in
                        onAddCommand(text)
                        isComposing = false
                    },
                    onCancel: {
                        isComposing = false
                    }
                )
            }
        }
    }

    private var canComment: Bool {
        !line.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var lineText: Text {
        guard isMarkdown else {
            return Text(verbatim: line.isEmpty ? " " : line)
                .foregroundColor(DSColor.contextForeground)
        }

        return MarkdownTextStyle.text(for: line)
    }

    private var fontForLine: Font {
        guard isMarkdown else {
            return DSFont.code
        }

        return MarkdownTextStyle.font(for: line)
    }

    private var leadingIndent: CGFloat {
        guard isMarkdown else {
            return 0
        }

        return MarkdownTextStyle.leadingIndent(for: line)
    }
}
