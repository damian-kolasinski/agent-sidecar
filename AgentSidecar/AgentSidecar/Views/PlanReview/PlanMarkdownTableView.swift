import SwiftUI

struct PlanMarkdownTableView: View {
    let table: MarkdownTableBlock
    let comments: [PlanComment]
    let onAddComment: (String, String) -> Void
    let onRemoveComment: (UUID) -> Void

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
            ZStack {
                if hoveringLineNumber == row.lineNumber && canComment(on: row) {
                    Button {
                        composingLineNumber = row.lineNumber
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

        ForEach(commentsForRow(row)) { planComment in
            PlanCommentBubbleView(
                planComment: planComment,
                onRemove: { onRemoveComment(planComment.id) }
            )
            .gridCellColumns(table.columnCount + 1)
        }

        if composingLineNumber == row.lineNumber {
            InlineCommentComposer(
                onSubmit: { comment in
                    onAddComment(row.line, comment)
                    composingLineNumber = nil
                },
                onCancel: {
                    composingLineNumber = nil
                }
            )
            .gridCellColumns(table.columnCount + 1)
        }
    }

    private func commentsForRow(_ row: MarkdownTableRow) -> [PlanComment] {
        comments.filter { $0.line == row.line }
    }

    private func canComment(on row: MarkdownTableRow) -> Bool {
        !row.line.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
