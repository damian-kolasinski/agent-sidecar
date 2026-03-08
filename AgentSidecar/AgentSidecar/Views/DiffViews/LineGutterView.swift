import SwiftUI

struct LineGutterView: View {
    let lineNumber: Int?
    let type: DiffLineType
    let isHovering: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            // Line number
            if let lineNumber {
                Text("\(lineNumber)")
                    .font(DSFont.lineNumber)
                    .foregroundStyle(DSColor.gutterText)
                    .opacity(isHovering ? 0.3 : 1.0)
            }

            // Hover "+" icon
            if isHovering {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(DSColor.gutterHoverIcon)
            }
        }
        .frame(width: DSSpacing.gutterWidth, height: DSSpacing.lineHeight)
        .background(gutterBackground)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    private var gutterBackground: Color {
        switch type {
        case .addition: DSColor.gutterAdditionBackground
        case .deletion: DSColor.gutterDeletionBackground
        case .context: DSColor.gutterBackground
        }
    }
}
