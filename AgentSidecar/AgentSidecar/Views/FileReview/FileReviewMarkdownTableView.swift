import SwiftUI

struct FileReviewMarkdownTableView: View {
    let table: MarkdownTableBlock
    let commands: [FileReviewCommand]
    let onAddCommand: (Int, String, String) -> Void
    let onRemoveCommand: (UUID) -> Void

    @State private var hoveringLineNumber: Int?
    @State private var composingLineNumber: Int?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                ForEach(table.rows) { row in
                    rowSection(for: row)
                }
            }
        }
    }

    @ViewBuilder
    private func rowSection(for row: MarkdownTableRow) -> some View {
        GridRow(alignment: .top) {
            LineGutterView(
                lineNumber: row.lineNumber,
                type: .context,
                isHovering: hoveringLineNumber == row.lineNumber && canComment(on: row),
                onTap: {
                    guard canComment(on: row) else { return }
                    composingLineNumber = row.lineNumber
                }
            )

            ForEach(Array(row.cells.enumerated()), id: \.offset) { columnIndex, cell in
                MarkdownTableCellView(
                    text: cell,
                    kind: row.kind,
                    alignment: table.alignments[columnIndex],
                    isFirstColumn: columnIndex == 0
                )
            }
        }
        .onHover { isHovering in
            hoveringLineNumber = isHovering ? row.lineNumber : nil
        }

        ForEach(commandsForRow(row)) { command in
            FileReviewCommandBubbleView(
                command: command,
                onRemove: { onRemoveCommand(command.id) }
            )
            .gridCellColumns(table.columnCount + 1)
        }

        if composingLineNumber == row.lineNumber {
            InlineCommentComposer(
                onSubmit: { text in
                    onAddCommand(row.lineNumber, row.line, text)
                    composingLineNumber = nil
                },
                onCancel: {
                    composingLineNumber = nil
                }
            )
            .gridCellColumns(table.columnCount + 1)
        }
    }

    private func commandsForRow(_ row: MarkdownTableRow) -> [FileReviewCommand] {
        commands.filter { $0.lineNumber == row.lineNumber }
    }

    private func canComment(on row: MarkdownTableRow) -> Bool {
        !row.line.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
