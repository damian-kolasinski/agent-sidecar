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
        if line.isEmpty {
            return Text(" ")
                .foregroundStyle(DSColor.contextForeground)
        }

        let tokens = MarkdownLineHighlighter.tokenize(line)
        if tokens.isEmpty {
            return Text(" ").foregroundStyle(DSColor.contextForeground)
        }

        var result = Text("")
        for token in tokens {
            var fragment = Text(token.text).foregroundColor(colorForMarkdownToken(token.type))
            if token.type == .bold {
                fragment = fragment.bold()
            } else if token.type == .italic {
                fragment = fragment.italic()
            }
            result = result + fragment
        }
        return result
    }

    private func colorForMarkdownToken(_ type: MarkdownTokenType) -> Color {
        switch type {
        case .heading: DSColor.markdownHeading
        case .bold: DSColor.markdownBold
        case .italic: DSColor.contextForeground
        case .code: DSColor.markdownCode
        case .link: DSColor.markdownLink
        case .linkURL: DSColor.markdownLinkURL
        case .listMarker: DSColor.markdownListMarker
        case .plain: DSColor.contextForeground
        }
    }

    private var fontForLine: Font {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("# ") {
            return .system(size: 18, weight: .bold, design: .monospaced)
        } else if trimmed.hasPrefix("## ") {
            return .system(size: 15, weight: .bold, design: .monospaced)
        } else if trimmed.hasPrefix("### ") {
            return .system(size: 13, weight: .semibold, design: .monospaced)
        }
        return DSFont.code
    }

    private var leadingIndent: CGFloat {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            return DSSpacing.md
        }
        if let first = trimmed.first, first.isNumber,
           trimmed.contains(". ") {
            return DSSpacing.md
        }
        return 0
    }
}
