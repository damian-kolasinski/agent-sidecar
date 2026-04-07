import SwiftUI

enum MarkdownTextStyle {
    static func text(for line: String) -> Text {
        guard !line.isEmpty else {
            return Text(" ")
                .foregroundColor(DSColor.contextForeground)
        }

        let tokens = MarkdownLineHighlighter.tokenize(line)
        guard !tokens.isEmpty else {
            return Text(" ")
                .foregroundColor(DSColor.contextForeground)
        }

        var result = Text("")
        for token in tokens {
            var fragment = Text(verbatim: token.text).foregroundColor(color(for: token.type))
            if token.type == .bold {
                fragment = fragment.bold()
            } else if token.type == .italic {
                fragment = fragment.italic()
            }
            result = result + fragment
        }

        return result
    }

    static func font(for line: String) -> Font {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("# ") {
            return .system(size: 18, weight: .bold, design: .monospaced)
        }
        if trimmed.hasPrefix("## ") {
            return .system(size: 15, weight: .bold, design: .monospaced)
        }
        if trimmed.hasPrefix("### ") {
            return .system(size: 13, weight: .semibold, design: .monospaced)
        }

        return DSFont.code
    }

    static func leadingIndent(for line: String) -> CGFloat {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            return DSSpacing.md
        }

        if let first = trimmed.first, first.isNumber, trimmed.contains(". ") {
            return DSSpacing.md
        }

        return 0
    }

    private static func color(for type: MarkdownTokenType) -> Color {
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
}
