import Foundation

struct MarkdownLineBlock: Equatable, Sendable {
    let lineIndex: Int
    let line: String

    var lineNumber: Int {
        lineIndex + 1
    }
}

enum MarkdownTableAlignment: Equatable, Sendable {
    case leading
    case center
    case trailing
}

struct MarkdownTableRow: Equatable, Identifiable, Sendable {
    enum Kind: Equatable, Sendable {
        case header
        case separator
        case body
    }

    let lineIndex: Int
    let line: String
    let kind: Kind
    let cells: [String]

    var id: Int {
        lineIndex
    }

    var lineNumber: Int {
        lineIndex + 1
    }
}

struct MarkdownTableBlock: Equatable, Sendable {
    let startLineIndex: Int
    let columnCount: Int
    let alignments: [MarkdownTableAlignment]
    let rows: [MarkdownTableRow]
}

enum MarkdownBlock: Equatable, Sendable {
    case line(MarkdownLineBlock)
    case table(MarkdownTableBlock)
}

enum MarkdownTableParser {
    static func blocks(from lines: [String]) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var index = 0
        var activeFence: Character?

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if let fenceDelimiter = activeFence {
                blocks.append(.line(MarkdownLineBlock(lineIndex: index, line: line)))
                if closesFence(trimmed, delimiter: fenceDelimiter) {
                    activeFence = nil
                }
                index += 1
                continue
            }

            if let delimiter = openingFenceDelimiter(in: trimmed) {
                activeFence = delimiter
                blocks.append(.line(MarkdownLineBlock(lineIndex: index, line: line)))
                index += 1
                continue
            }

            if let table = tableBlock(startingAt: index, in: lines) {
                blocks.append(.table(table))
                index = table.rows.last!.lineIndex + 1
                continue
            }

            blocks.append(.line(MarkdownLineBlock(lineIndex: index, line: line)))
            index += 1
        }

        return blocks
    }

    private static func tableBlock(startingAt index: Int, in lines: [String]) -> MarkdownTableBlock? {
        guard index + 1 < lines.count else { return nil }

        let headerLine = lines[index]
        let separatorLine = lines[index + 1]

        guard !isIndentedCodeBlockLine(headerLine), !isIndentedCodeBlockLine(separatorLine) else {
            return nil
        }

        guard let headerCells = parseCells(from: headerLine),
              let separatorCells = parseCells(from: separatorLine),
              headerCells.count == separatorCells.count,
              !isSeparatorRow(headerCells),
              isSeparatorRow(separatorCells)
        else {
            return nil
        }

        let columnCount = headerCells.count
        let alignments = separatorCells.map(alignment(for:))
        var rows = [
            MarkdownTableRow(
                lineIndex: index,
                line: headerLine,
                kind: .header,
                cells: normalize(headerCells, columnCount: columnCount)
            ),
            MarkdownTableRow(
                lineIndex: index + 1,
                line: separatorLine,
                kind: .separator,
                cells: normalize(separatorCells, columnCount: columnCount)
            ),
        ]

        var nextIndex = index + 2
        while nextIndex < lines.count {
            let line = lines[nextIndex]
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty,
                  !isIndentedCodeBlockLine(line),
                  let bodyCells = parseCells(from: line),
                  !isSeparatorRow(bodyCells)
            else {
                break
            }

            rows.append(
                MarkdownTableRow(
                    lineIndex: nextIndex,
                    line: line,
                    kind: .body,
                    cells: normalize(bodyCells, columnCount: columnCount)
                )
            )
            nextIndex += 1
        }

        return MarkdownTableBlock(
            startLineIndex: index,
            columnCount: columnCount,
            alignments: alignments,
            rows: rows
        )
    }

    private static func parseCells(from line: String) -> [String]? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.contains("|") else {
            return nil
        }

        var content = trimmed
        if content.hasPrefix("|") {
            content.removeFirst()
        }
        if content.hasSuffix("|") {
            content.removeLast()
        }

        var cells: [String] = []
        var current = ""
        var iterator = content.makeIterator()

        while let character = iterator.next() {
            if character == "\\" {
                if let escaped = iterator.next() {
                    current.append(escaped)
                } else {
                    current.append(character)
                }
                continue
            }

            if character == "|" {
                cells.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
                continue
            }

            current.append(character)
        }

        cells.append(current.trimmingCharacters(in: .whitespaces))

        guard cells.count > 1 else {
            return nil
        }

        return cells
    }

    private static func isSeparatorRow(_ cells: [String]) -> Bool {
        !cells.isEmpty && cells.allSatisfy {
            $0.range(of: #"^:?-{3,}:?$"#, options: .regularExpression) != nil
        }
    }

    private static func alignment(for separatorCell: String) -> MarkdownTableAlignment {
        let hasLeadingColon = separatorCell.hasPrefix(":")
        let hasTrailingColon = separatorCell.hasSuffix(":")

        return switch (hasLeadingColon, hasTrailingColon) {
        case (true, true):
            MarkdownTableAlignment.center
        case (false, true):
            MarkdownTableAlignment.trailing
        default:
            MarkdownTableAlignment.leading
        }
    }

    private static func normalize(_ cells: [String], columnCount: Int) -> [String] {
        let normalized = Array(cells.prefix(columnCount))
        if normalized.count == columnCount {
            return normalized
        }

        return normalized + Array(repeating: "", count: columnCount - normalized.count)
    }

    private static func isIndentedCodeBlockLine(_ line: String) -> Bool {
        line.hasPrefix("    ") || line.hasPrefix("\t")
    }

    private static func openingFenceDelimiter(in trimmedLine: String) -> Character? {
        if trimmedLine.hasPrefix("```") {
            return "`"
        }
        if trimmedLine.hasPrefix("~~~") {
            return "~"
        }
        return nil
    }

    private static func closesFence(_ trimmedLine: String, delimiter: Character) -> Bool {
        switch delimiter {
        case "`":
            trimmedLine.hasPrefix("```")
        case "~":
            trimmedLine.hasPrefix("~~~")
        default:
            false
        }
    }
}
