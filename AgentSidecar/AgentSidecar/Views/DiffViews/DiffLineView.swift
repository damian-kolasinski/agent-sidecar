import SwiftUI

struct DiffLineView: View {
    let line: DiffLine
    var syntaxHighlight = false
    let onGutterClick: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 0) {
            // Old line number gutter
            LineGutterView(
                lineNumber: line.oldLineNumber,
                type: line.type,
                isHovering: isHovering,
                onTap: onGutterClick
            )

            // New line number gutter
            LineGutterView(
                lineNumber: line.newLineNumber,
                type: line.type,
                isHovering: isHovering,
                onTap: onGutterClick
            )

            // Prefix
            Text(prefix)
                .font(DSFont.code)
                .foregroundStyle(foregroundColor)
                .frame(width: 14, alignment: .center)

            // Content
            highlightedContent
                .font(DSFont.code)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, DSSpacing.sm)
        }
        .frame(minHeight: DSSpacing.lineHeight)
        .background(backgroundColor)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var highlightedContent: Text {
        let suffix = line.noNewlineAtEnd ? " ⏎" : ""

        guard syntaxHighlight else {
            return Text(line.content + suffix)
                .foregroundColor(foregroundColor)
        }

        let tokens = SwiftSyntaxHighlighter.tokenize(line.content)
        var result = Text("")
        for token in tokens {
            result = result + Text(token.text).foregroundColor(colorForToken(token.type))
        }
        if !suffix.isEmpty {
            result = result + Text(suffix).foregroundColor(foregroundColor)
        }
        return result
    }

    private func colorForToken(_ type: SyntaxTokenType) -> Color {
        switch type {
        case .keyword: DSColor.syntaxKeyword
        case .type: DSColor.syntaxType
        case .property: DSColor.syntaxProperty
        case .string: DSColor.syntaxString
        case .comment: DSColor.syntaxComment
        case .number: DSColor.syntaxNumber
        case .plain: foregroundColor
        }
    }

    private var prefix: String {
        switch line.type {
        case .addition: "+"
        case .deletion: "-"
        case .context: " "
        }
    }

    private var backgroundColor: Color {
        switch line.type {
        case .addition: DSColor.additionBackground
        case .deletion: DSColor.deletionBackground
        case .context: DSColor.contextBackground
        }
    }

    private var foregroundColor: Color {
        switch line.type {
        case .addition: DSColor.additionForeground
        case .deletion: DSColor.deletionForeground
        case .context: DSColor.contextForeground
        }
    }
}
