import SwiftUI

struct PlanReviewView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = PlanReviewViewModel()

    let filePath: String

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading plan...")
                Spacer()
            } else if let error = viewModel.errorMessage {
                Spacer()
                ErrorBannerView(
                    message: error,
                    onRetry: { viewModel.loadPlan() }
                )
                Spacer()
            } else if viewModel.isSubmitted {
                Spacer()
                VStack(spacing: DSSpacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("Review submitted")
                        .font(DSFont.heading)
                }
                Spacer()
            } else {
                planContent
                DSDivider()
                bottomBar
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    appViewModel.currentMode = .diffReview
                } label: {
                    HStack(spacing: DSSpacing.xs) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.plain)
            }
            ToolbarItem(placement: .principal) {
                Text(viewModel.planFileName)
                    .font(DSFont.heading)
            }
            ToolbarItem(placement: .primaryAction) {
                DSButton("Approve") {
                    viewModel.approve()
                }
            }
        }
        .onAppear {
            viewModel.planFilePath = filePath
            viewModel.loadPlan()
        }
        .onChange(of: filePath) { _, newPath in
            viewModel.planFilePath = newPath
            viewModel.loadPlan()
        }
    }

    private var planContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                let lines = viewModel.planContent.components(separatedBy: "\n")
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    PlanLineView(
                        line: line,
                        lineIndex: index,
                        commentsForLine: viewModel.comments.filter { $0.line == line },
                        onAddComment: { comment in
                            viewModel.addComment(line: line, comment: comment)
                        },
                        onRemoveComment: { id in
                            viewModel.removeComment(id: id)
                        }
                    )
                }
            }
            .padding(.vertical, DSSpacing.sm)
        }
    }

    private var bottomBar: some View {
        HStack {
            if !viewModel.comments.isEmpty {
                Text("\(viewModel.comments.count) comment\(viewModel.comments.count == 1 ? "" : "s")")
                    .font(DSFont.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            DSButton("Request Changes", variant: .secondary) {
                viewModel.requestChanges()
            }
            .disabled(viewModel.comments.isEmpty)
        }
        .padding(.horizontal, DSSpacing.lg)
        .padding(.vertical, DSSpacing.md)
    }
}
