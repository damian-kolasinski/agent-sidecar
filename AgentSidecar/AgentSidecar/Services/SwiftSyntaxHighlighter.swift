import Foundation

enum SyntaxTokenType: Sendable {
    case keyword
    case type
    case property
    case string
    case comment
    case number
    case plain
}

struct SyntaxToken: Sendable {
    let text: String
    let type: SyntaxTokenType
}

enum SwiftSyntaxHighlighter {
    private nonisolated(unsafe) static let pattern: NSRegularExpression = {
        let comment = #"//.*$|/\*.*?(?:\*/|$)"#
        let string = #""(?:[^"\\]|\\.)*""#
        let number = #"\b(?:0x[0-9a-fA-F_]+|0b[01_]+|0o[0-7_]+|\d[\d_]*\.?[\d_]*(?:e[+-]?\d+)?)\b"#
        let keyword = #"\b(?:actor|any|as|associatedtype|async|await|break|case|catch|class|continue|convenience|default|defer|deinit|do|else|enum|extension|fallthrough|false|fileprivate|final|for|func|guard|if|import|in|init|inout|internal|is|lazy|let|mutating|nil|nonmutating|nonisolated|open|operator|override|private|protocol|public|repeat|required|rethrows|return|self|Self|sending|some|static|struct|subscript|super|switch|throw|throws|true|try|typealias|unowned|var|weak|where|while)\b"#
        let attribute = #"@\w+"#
        let dotMember = #"\.[a-z][a-zA-Z0-9]*"#
        let typeIdent = #"\b[A-Z][a-zA-Z0-9]*\b"#

        let combined = "(\(comment))|(\(string))|(\(number))|(\(keyword))|(\(attribute))|(\(dotMember))|(\(typeIdent))"
        return try! NSRegularExpression(pattern: combined)
    }()

    static func tokenize(_ source: String) -> [SyntaxToken] {
        if source.isEmpty { return [] }
        if source.count > 1000 { return [SyntaxToken(text: source, type: .plain)] }

        let nsSource = source as NSString
        let matches = pattern.matches(in: source, range: NSRange(location: 0, length: nsSource.length))

        if matches.isEmpty { return [SyntaxToken(text: source, type: .plain)] }

        var tokens: [SyntaxToken] = []
        var cursor = 0

        for match in matches {
            let matchRange = match.range
            if matchRange.location > cursor {
                tokens.append(SyntaxToken(
                    text: nsSource.substring(with: NSRange(location: cursor, length: matchRange.location - cursor)),
                    type: .plain
                ))
            }

            let text = nsSource.substring(with: matchRange)
            let type: SyntaxTokenType =
                match.range(at: 1).location != NSNotFound ? .comment :
                match.range(at: 2).location != NSNotFound ? .string :
                match.range(at: 3).location != NSNotFound ? .number :
                match.range(at: 4).location != NSNotFound ? .keyword :
                match.range(at: 5).location != NSNotFound ? .keyword :
                match.range(at: 6).location != NSNotFound ? .property :
                match.range(at: 7).location != NSNotFound ? .type :
                .plain

            tokens.append(SyntaxToken(text: text, type: type))
            cursor = matchRange.location + matchRange.length
        }

        if cursor < nsSource.length {
            tokens.append(SyntaxToken(
                text: nsSource.substring(from: cursor),
                type: .plain
            ))
        }

        return tokens
    }
}
