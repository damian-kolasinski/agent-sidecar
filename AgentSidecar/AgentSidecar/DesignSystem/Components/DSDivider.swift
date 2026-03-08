import SwiftUI

struct DSDivider: View {
    let orientation: Orientation

    enum Orientation {
        case horizontal
        case vertical
    }

    init(_ orientation: Orientation = .horizontal) {
        self.orientation = orientation
    }

    var body: some View {
        switch orientation {
        case .horizontal:
            Rectangle()
                .fill(DSColor.separator)
                .frame(height: 1)
        case .vertical:
            Rectangle()
                .fill(DSColor.separator)
                .frame(width: 1)
        }
    }
}
