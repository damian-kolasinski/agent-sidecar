import SwiftUI

struct DetailView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var detailViewModel = DiffDetailViewModel()

    var body: some View {
        Group {
            if appViewModel.repoPath == nil {
                WelcomeView()
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
                VStack(spacing: 0) {
                    diffSummaryBar
                    DSDivider(.horizontal)
                    continuousScrollView
                }
                .environmentObject(detailViewModel)
            }
        }
        .onChange(of: appViewModel.persistedReviewedFiles) { _, newFiles in
            detailViewModel.reviewedFiles = newFiles
            detailViewModel.collapsedFiles.formUnion(newFiles)
        }
    }

    private var diffSummaryBar: some View {
        let diffs = appViewModel.fileDiffs
        let totalFiles = diffs.count
        let totalAdditions = diffs.reduce(0) { $0 + $1.additionCount }
        let totalDeletions = diffs.reduce(0) { $0 + $1.deletionCount }
        let reviewedCount = detailViewModel.reviewedFiles.count

        return HStack(spacing: DSSpacing.md) {
            HStack(spacing: DSSpacing.xs) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text("\(totalFiles) files changed")
                    .font(DSFont.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: DSSpacing.sm) {
                Text("+\(totalAdditions)")
                    .font(DSFont.caption)
                    .foregroundStyle(DSColor.statusAdded)
                Text("-\(totalDeletions)")
                    .font(DSFont.caption)
                    .foregroundStyle(DSColor.statusDeleted)
            }

            Spacer()

            HStack(spacing: DSSpacing.xs) {
                Image(systemName: reviewedCount == totalFiles && totalFiles > 0
                      ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 11))
                    .foregroundStyle(reviewedCount == totalFiles && totalFiles > 0
                                    ? DSColor.statusAdded : .secondary)
                Text("\(reviewedCount)/\(totalFiles) files viewed")
                    .font(DSFont.caption)
                    .foregroundStyle(.secondary)
            }

            diffChangesIndicator(additions: totalAdditions, deletions: totalDeletions)
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
        .background(DSColor.sidebarBackground)
    }

    private func diffChangesIndicator(additions: Int, deletions: Int) -> some View {
        let total = additions + deletions
        let blockCount = 5
        let addBlocks = total > 0 ? max(0, Int(round(Double(additions) / Double(total) * Double(blockCount)))) : 0

        return HStack(spacing: 1) {
            ForEach(0..<blockCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i < addBlocks ? DSColor.statusAdded : DSColor.statusDeleted)
                    .frame(width: 8, height: 8)
            }
        }
        .opacity(total > 0 ? 1 : 0.3)
    }

    private var continuousScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
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
