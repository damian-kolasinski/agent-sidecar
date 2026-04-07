import SwiftUI

struct MarkdownTableCellView: View {
    let text: String
    let kind: MarkdownTableRow.Kind
    let alignment: MarkdownTableAlignment
    let isFirstColumn: Bool

    var body: some View {
        Group {
            switch kind {
            case .separator:
                separatorCell
            case .header, .body:
                textCell
            }
        }
        .background(backgroundColor)
        .overlay(alignment: .top) {
            if kind == .header {
                Rectangle()
                    .fill(DSColor.separator)
                    .frame(height: 1)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DSColor.separator)
                .frame(height: 1)
        }
        .overlay(alignment: .leading) {
            if isFirstColumn {
                Rectangle()
                    .fill(DSColor.separator)
                    .frame(width: 1)
            }
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(DSColor.separator)
                .frame(width: 1)
        }
    }

    private var textCell: some View {
        MarkdownTextStyle.text(for: text.isEmpty ? " " : text)
            .font(kind == .header ? .system(size: 12, weight: .semibold, design: .monospaced) : DSFont.code)
            .lineLimit(1)
            .truncationMode(.tail)
            .textSelection(.enabled)
            .padding(.horizontal, DSSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: DSSpacing.lineHeight, alignment: frameAlignment)
    }

    private var separatorCell: some View {
        Color.clear
            .frame(maxWidth: .infinity, minHeight: DSSpacing.lineHeight)
            .overlay {
                Rectangle()
                    .fill(DSColor.separator)
                    .frame(height: 1)
                    .padding(.horizontal, DSSpacing.sm)
            }
    }

    private var backgroundColor: Color {
        switch kind {
        case .header:
            DSColor.gutterBackground
        case .separator, .body:
            DSColor.contextBackground
        }
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .leading:
            .leading
        case .center:
            .center
        case .trailing:
            .trailing
        }
    }
}
