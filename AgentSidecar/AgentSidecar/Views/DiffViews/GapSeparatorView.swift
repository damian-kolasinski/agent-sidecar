import SwiftUI

struct GapSeparatorView: View {
    let remainingLines: Int
    let showExpandDown: Bool
    let showExpandUp: Bool
    let onExpandDown: () -> Void
    let onExpandUp: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 0) {
            // Gutter area matching the two line number columns
            gutter
            gutter

            // Expand controls
            HStack(spacing: DSSpacing.sm) {
                if showExpandDown {
                    expandButton(systemName: "chevron.down", action: onExpandDown)
                }
                if showExpandUp {
                    expandButton(systemName: "chevron.up", action: onExpandUp)
                }

                Text("\(remainingLines) hidden lines")
                    .font(DSFont.code)
                    .foregroundStyle(DSColor.hunkHeaderText)

                Spacer()
            }
            .padding(.horizontal, DSSpacing.sm)
        }
        .frame(height: DSSpacing.hunkHeaderHeight)
        .background(DSColor.hunkHeaderBackground.opacity(isHovering ? 0.8 : 0.5))
        .onHover { isHovering = $0 }
    }

    private var gutter: some View {
        Text("···")
            .font(DSFont.lineNumber)
            .foregroundStyle(DSColor.gutterText.opacity(0.5))
            .frame(width: DSSpacing.gutterWidth, height: DSSpacing.hunkHeaderHeight)
            .background(DSColor.hunkHeaderBackground)
    }

    private func expandButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DSColor.hunkHeaderText)
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
