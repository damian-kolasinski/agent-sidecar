import Testing
@testable import AgentSidecar

@Suite("MarkdownTableParser Tests")
struct MarkdownTableParserTests {

    @Test("Parses a markdown table into a single table block")
    func parsesTableBlock() {
        let lines = [
            "| File | Goal | Pattern |",
            "|------|------|---------|",
            "| `a`  | Ship | Builder |",
        ]

        let blocks = MarkdownTableParser.blocks(from: lines)

        #expect(blocks.count == 1)

        guard case .table(let table) = blocks[0] else {
            Issue.record("Expected a table block")
            return
        }

        #expect(table.columnCount == 3)
        #expect(table.rows.count == 3)
        #expect(table.rows[0].kind == .header)
        #expect(table.rows[1].kind == .separator)
        #expect(table.rows[2].kind == .body)
        #expect(table.rows[0].cells == ["File", "Goal", "Pattern"])
        #expect(table.rows[2].cells == ["`a`", "Ship", "Builder"])
    }

    @Test("Does not parse tables inside fenced code blocks")
    func skipsCodeFenceTables() {
        let lines = [
            "```md",
            "| File | Goal |",
            "|------|------|",
            "```",
        ]

        let blocks = MarkdownTableParser.blocks(from: lines)

        #expect(blocks.count == 4)
        #expect(blocks.allSatisfy {
            if case .line = $0 {
                true
            } else {
                false
            }
        })
    }

    @Test("Leaves ordinary lines outside the table untouched")
    func preservesNonTableLines() {
        let lines = [
            "Intro",
            "| File | Goal |",
            "|------|------|",
            "| a.md | Ship |",
            "",
            "Outro",
        ]

        let blocks = MarkdownTableParser.blocks(from: lines)

        #expect(blocks.count == 4)

        guard case .line(let firstLine) = blocks[0] else {
            Issue.record("Expected the first block to be a line")
            return
        }

        guard case .table(let table) = blocks[1] else {
            Issue.record("Expected the second block to be a table")
            return
        }

        guard case .line(let emptyLine) = blocks[2] else {
            Issue.record("Expected the third block to be the separating line")
            return
        }

        #expect(firstLine.line == "Intro")
        #expect(table.rows.count == 3)
        #expect(emptyLine.line.isEmpty)
    }
}
