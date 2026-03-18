import Foundation

enum MarkdownTokenType: Sendable {
    case heading
    case bold
    case italic
    case code
    case link
    case linkURL
    case listMarker
    case plain
}

struct MarkdownToken: Sendable {
    let text: String
    let type: MarkdownTokenType
}

enum MarkdownLineHighlighter {
    private nonisolated(unsafe) static let inlinePattern: NSRegularExpression = {
        let code = #"`([^`]+)`"#
        let bold = #"\*\*(.+?)\*\*"#
        let italic = #"\*(.+?)\*"#
        let link = #"\[([^\]]+)\]\(([^)]+)\)"#

        let combined = "(\(code))|(\(bold))|(\(italic))|(\(link))"
        return try! NSRegularExpression(pattern: combined)
    }()

    static func tokenize(_ line: String) -> [MarkdownToken] {
        if line.isEmpty { return [] }

        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Heading lines — color the entire line
        if trimmed.hasPrefix("# ") || trimmed.hasPrefix("## ") || trimmed.hasPrefix("### ") ||
           trimmed.hasPrefix("#### ") || trimmed == "#" {
            return [MarkdownToken(text: line, type: .heading)]
        }

        // List marker prefix
        var prefix: MarkdownToken?
        var contentStart = line.startIndex

        if let range = trimmed.range(of: #"^(\s*[-*]\s)"#, options: .regularExpression) {
            let marker = String(trimmed[range])
            let leadingSpaces = line.prefix(while: { $0 == " " || $0 == "\t" })
            let fullPrefix = leadingSpaces + marker
            prefix = MarkdownToken(text: String(fullPrefix), type: .listMarker)
            contentStart = line.index(line.startIndex, offsetBy: fullPrefix.count)
        } else if let range = trimmed.range(of: #"^(\s*\d+\.\s)"#, options: .regularExpression) {
            let marker = String(trimmed[range])
            let leadingSpaces = line.prefix(while: { $0 == " " || $0 == "\t" })
            let fullPrefix = leadingSpaces + marker
            prefix = MarkdownToken(text: String(fullPrefix), type: .listMarker)
            contentStart = line.index(line.startIndex, offsetBy: fullPrefix.count)
        }

        let content = String(line[contentStart...])
        let inlineTokens = tokenizeInline(content)

        if let prefix = prefix {
            return [prefix] + inlineTokens
        }
        return inlineTokens
    }

    private static func tokenizeInline(_ source: String) -> [MarkdownToken] {
        if source.isEmpty { return [] }
        if source.count > 2000 { return [MarkdownToken(text: source, type: .plain)] }

        let nsSource = source as NSString
        let matches = inlinePattern.matches(in: source, range: NSRange(location: 0, length: nsSource.length))

        if matches.isEmpty { return [MarkdownToken(text: source, type: .plain)] }

        var tokens: [MarkdownToken] = []
        var cursor = 0

        for match in matches {
            let matchRange = match.range
            if matchRange.location > cursor {
                tokens.append(MarkdownToken(
                    text: nsSource.substring(with: NSRange(location: cursor, length: matchRange.location - cursor)),
                    type: .plain
                ))
            }

            if match.range(at: 1).location != NSNotFound {
                // Code: `content`
                tokens.append(MarkdownToken(text: nsSource.substring(with: matchRange), type: .code))
            } else if match.range(at: 3).location != NSNotFound {
                // Bold: **content**
                tokens.append(MarkdownToken(text: nsSource.substring(with: matchRange), type: .bold))
            } else if match.range(at: 5).location != NSNotFound {
                // Italic: *content*
                tokens.append(MarkdownToken(text: nsSource.substring(with: matchRange), type: .italic))
            } else if match.range(at: 7).location != NSNotFound {
                // Link: [text](url)
                let linkText = nsSource.substring(with: match.range(at: 7))
                let linkURL = nsSource.substring(with: match.range(at: 8))
                tokens.append(MarkdownToken(text: "[", type: .plain))
                tokens.append(MarkdownToken(text: linkText, type: .link))
                tokens.append(MarkdownToken(text: "](", type: .plain))
                tokens.append(MarkdownToken(text: linkURL, type: .linkURL))
                tokens.append(MarkdownToken(text: ")", type: .plain))
            }

            cursor = matchRange.location + matchRange.length
        }

        if cursor < nsSource.length {
            tokens.append(MarkdownToken(
                text: nsSource.substring(from: cursor),
                type: .plain
            ))
        }

        return tokens
    }
}
