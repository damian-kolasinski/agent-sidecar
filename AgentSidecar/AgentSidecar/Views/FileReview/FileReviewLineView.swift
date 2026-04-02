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
                .foregroundStyle(DSColor.contextForeground)
        }

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
        guard isMarkdown else {
            return DSFont.code
        }

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
        guard isMarkdown else {
            return 0
        }

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
