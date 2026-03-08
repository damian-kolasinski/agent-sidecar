import SwiftUI

struct DSBadge: View {
    let status: FileStatus

    var body: some View {
        Text(status.displayLabel)
            .font(DSFont.badgeLabel)
            .foregroundStyle(color)
            .frame(width: DSSpacing.badgeSize, height: DSSpacing.badgeSize)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var color: Color {
        switch status {
        case .added: DSColor.statusAdded
        case .deleted: DSColor.statusDeleted
        case .modified: DSColor.statusModified
        case .renamed: DSColor.statusRenamed
        case .binary: DSColor.statusModified
        }
    }
}
