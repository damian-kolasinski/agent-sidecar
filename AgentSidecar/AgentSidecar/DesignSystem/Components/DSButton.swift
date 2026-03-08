import SwiftUI

enum DSButtonVariant {
    case primary
    case secondary
}

struct DSButton: View {
    let title: String
    let variant: DSButtonVariant
    let action: () -> Void

    init(_ title: String, variant: DSButtonVariant = .primary, action: @escaping () -> Void) {
        self.title = title
        self.variant = variant
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DSFont.body)
                .padding(.horizontal, DSSpacing.md)
                .padding(.vertical, DSSpacing.xs)
        }
        .buttonStyle(.plain)
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(borderColor, lineWidth: variant == .secondary ? 1 : 0)
        )
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary: Color.accentColor
        case .secondary: Color.clear
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary: Color.white
        case .secondary: Color.primary
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary: Color.clear
        case .secondary: DSColor.separator
        }
    }
}
