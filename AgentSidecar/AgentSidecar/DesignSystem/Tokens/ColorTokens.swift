import SwiftUI

extension Color {
    init(light: Color, dark: Color) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? NSColor(dark) : NSColor(light)
        })
    }
}

enum DSColor {
    // MARK: - Diff Backgrounds
    static let additionBackground = Color(
        light: Color(red: 0.91, green: 0.97, blue: 0.91),
        dark: Color(red: 0.12, green: 0.17, blue: 0.13)
    )
    static let deletionBackground = Color(
        light: Color(red: 0.98, green: 0.91, blue: 0.91),
        dark: Color(red: 0.20, green: 0.12, blue: 0.12)
    )
    static let contextBackground = Color(
        light: Color.white,
        dark: Color(red: 0.13, green: 0.13, blue: 0.15)
    )

    // MARK: - Diff Foregrounds
    static let additionForeground = Color(
        light: Color(red: 0.10, green: 0.50, blue: 0.10),
        dark: Color(red: 0.45, green: 0.92, blue: 0.45)
    )
    static let deletionForeground = Color(
        light: Color(red: 0.68, green: 0.12, blue: 0.12),
        dark: Color(red: 0.95, green: 0.45, blue: 0.45)
    )
    static let contextForeground = Color(
        light: Color(red: 0.2, green: 0.2, blue: 0.2),
        dark: Color(red: 0.85, green: 0.85, blue: 0.85)
    )

    // MARK: - Gutter
    static let gutterBackground = Color(
        light: Color(red: 0.96, green: 0.96, blue: 0.97),
        dark: Color(red: 0.16, green: 0.16, blue: 0.18)
    )
    static let gutterText = Color(
        light: Color(red: 0.55, green: 0.55, blue: 0.58),
        dark: Color(red: 0.5, green: 0.5, blue: 0.53)
    )
    static let gutterAdditionBackground = Color(
        light: Color(red: 0.83, green: 0.94, blue: 0.83),
        dark: Color(red: 0.10, green: 0.15, blue: 0.11)
    )
    static let gutterDeletionBackground = Color(
        light: Color(red: 0.95, green: 0.85, blue: 0.85),
        dark: Color(red: 0.18, green: 0.11, blue: 0.11)
    )

    // MARK: - Hunk Header
    static let hunkHeaderBackground = Color(
        light: Color(red: 0.91, green: 0.95, blue: 1.0),
        dark: Color(red: 0.14, green: 0.17, blue: 0.24)
    )
    static let hunkHeaderText = Color(
        light: Color(red: 0.3, green: 0.45, blue: 0.72),
        dark: Color(red: 0.55, green: 0.7, blue: 0.92)
    )

    // MARK: - Comments
    static let commentBackground = Color(
        light: Color(red: 1.0, green: 0.98, blue: 0.9),
        dark: Color(red: 0.2, green: 0.19, blue: 0.14)
    )
    static let commentBorder = Color(
        light: Color(red: 0.9, green: 0.86, blue: 0.7),
        dark: Color(red: 0.35, green: 0.33, blue: 0.25)
    )
    static let composerBackground = Color(
        light: Color.white,
        dark: Color(red: 0.15, green: 0.15, blue: 0.17)
    )

    // MARK: - Chrome
    static let sidebarBackground = Color(
        light: Color(red: 0.97, green: 0.97, blue: 0.98),
        dark: Color(red: 0.11, green: 0.11, blue: 0.13)
    )
    static let selectedRow = Color(
        light: Color.accentColor.opacity(0.12),
        dark: Color.accentColor.opacity(0.25)
    )
    static let separator = Color(
        light: Color(red: 0.88, green: 0.88, blue: 0.9),
        dark: Color(red: 0.25, green: 0.25, blue: 0.27)
    )

    // MARK: - Status Badge Colors
    static let statusAdded = Color(
        light: Color(red: 0.15, green: 0.6, blue: 0.25),
        dark: Color(red: 0.3, green: 0.75, blue: 0.4)
    )
    static let statusDeleted = Color(
        light: Color(red: 0.75, green: 0.2, blue: 0.2),
        dark: Color(red: 0.9, green: 0.4, blue: 0.4)
    )
    static let statusModified = Color(
        light: Color(red: 0.6, green: 0.5, blue: 0.1),
        dark: Color(red: 0.8, green: 0.7, blue: 0.3)
    )
    static let statusRenamed = Color(
        light: Color(red: 0.3, green: 0.4, blue: 0.7),
        dark: Color(red: 0.5, green: 0.6, blue: 0.9)
    )

    // MARK: - Interactive
    static let gutterHoverIcon = Color.accentColor

    // MARK: - Syntax Highlighting
    static let syntaxKeyword = Color(
        light: Color(red: 0.61, green: 0.12, blue: 0.58),
        dark: Color(red: 0.99, green: 0.42, blue: 0.63)
    )
    static let syntaxType = Color(
        light: Color(red: 0.11, green: 0.43, blue: 0.55),
        dark: Color(red: 0.40, green: 0.85, blue: 0.82)
    )
    static let syntaxProperty = Color(
        light: Color(red: 0.20, green: 0.35, blue: 0.65),
        dark: Color(red: 0.50, green: 0.70, blue: 0.95)
    )
    static let syntaxString = Color(
        light: Color(red: 0.76, green: 0.22, blue: 0.14),
        dark: Color(red: 0.99, green: 0.56, blue: 0.37)
    )
    static let syntaxComment = Color(
        light: Color(red: 0.42, green: 0.47, blue: 0.50),
        dark: Color(red: 0.50, green: 0.55, blue: 0.58)
    )
    static let syntaxNumber = Color(
        light: Color(red: 0.64, green: 0.49, blue: 0.10),
        dark: Color(red: 0.85, green: 0.75, blue: 0.30)
    )
}
