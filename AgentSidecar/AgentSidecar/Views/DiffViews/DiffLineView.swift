import SwiftUI

struct DiffLineView: View {
    let line: DiffLine
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
            Text(line.content + (line.noNewlineAtEnd ? " ⏎" : ""))
                .font(DSFont.code)
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, DSSpacing.sm)
        }
        .frame(minHeight: DSSpacing.lineHeight)
        .background(backgroundColor)
        .onHover { hovering in
            isHovering = hovering
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
