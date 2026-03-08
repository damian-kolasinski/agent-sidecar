import SwiftUI

struct DetailView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var detailViewModel = DiffDetailViewModel()

    var body: some View {
        Group {
            if appViewModel.repoPath == nil {
                EmptyStateView(
                    title: "No Repository",
                    message: "Open a Git repository to view diffs.",
                    actionTitle: "Open Repository"
                ) {
                    appViewModel.openDirectoryPicker()
                }
            } else if appViewModel.isLoading {
                ProgressView("Loading diffs…")
            } else if let errorMessage = appViewModel.errorMessage {
                ErrorBannerView(message: errorMessage) {
                    Task { await appViewModel.refresh() }
                }
            } else if appViewModel.fileDiffs.isEmpty {
                EmptyStateView(
                    title: "No Changes",
                    message: "The working tree is clean.",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                continuousScrollView
                    .environmentObject(detailViewModel)
            }
        }
    }

    private var continuousScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(appViewModel.fileDiffs) { fileDiff in
                        FileDiffSectionView(fileDiff: fileDiff)
                            .id(fileDiff.displayPath)

                        DSDivider(.horizontal)
                    }
                }
            }
            .background(DSColor.contextBackground)
            .onChange(of: appViewModel.scrollToFilePath) { _, target in
                guard let target else { return }
                withAnimation {
                    proxy.scrollTo(target, anchor: .top)
                }
                appViewModel.scrollToFilePath = nil
            }
        }
    }
}
