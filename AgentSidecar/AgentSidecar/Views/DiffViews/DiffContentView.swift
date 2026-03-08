import SwiftUI

struct DiffContentView: View {
    let fileDiff: FileDiff
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var detailViewModel: DiffDetailViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                FileDiffSectionView(fileDiff: fileDiff)
            }
        }
        .background(DSColor.contextBackground)
    }
}
