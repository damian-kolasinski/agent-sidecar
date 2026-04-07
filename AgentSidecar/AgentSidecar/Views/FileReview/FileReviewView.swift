import SwiftUI

struct FileReviewView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = FileReviewViewModel()

    let payload: FileReviewPayload

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading file...")
                Spacer()
            } else if let error = viewModel.errorMessage {
                Spacer()
                ErrorBannerView(
                    message: error,
                    onRetry: { viewModel.loadFile() }
                )
                Spacer()
            } else if viewModel.isSubmitted {
                submissionState
            } else {
                fileContent
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
                Text(viewModel.fileName)
                    .font(DSFont.heading)
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    viewModel.loadFile()
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                DSButton("Approve") {
                    viewModel.approve()
                }
            }
        }
        .onAppear {
            viewModel.configure(with: payload)
        }
        .onChange(of: payload) { _, newPayload in
            viewModel.configure(with: newPayload)
        }
    }

    private var fileContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                let lines = viewModel.fileContent.components(separatedBy: "\n")
                let blocks = markdownBlocks(for: lines)

                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    switch block {
                    case .line(let lineBlock):
                        FileReviewLineView(
                            line: lineBlock.line,
                            lineNumber: lineBlock.lineNumber,
                            isMarkdown: viewModel.isMarkdownFile,
                            commandsForLine: viewModel.commands.filter { $0.lineNumber == lineBlock.lineNumber },
                            onAddCommand: { command in
                                viewModel.addCommand(
                                    lineNumber: lineBlock.lineNumber,
                                    line: lineBlock.line,
                                    command: command
                                )
                            },
                            onRemoveCommand: { id in
                                viewModel.removeCommand(id: id)
                            }
                        )
                    case .table(let table):
                        FileReviewMarkdownTableView(
                            table: table,
                            commands: viewModel.commands,
                            onAddCommand: { lineNumber, line, command in
                                viewModel.addCommand(
                                    lineNumber: lineNumber,
                                    line: line,
                                    command: command
                                )
                            },
                            onRemoveCommand: { id in
                                viewModel.removeCommand(id: id)
                            }
                        )
                    }
                }
            }
            .padding(.vertical, DSSpacing.sm)
        }
    }

    private func markdownBlocks(for lines: [String]) -> [MarkdownBlock] {
        if viewModel.isMarkdownFile {
            return MarkdownTableParser.blocks(from: lines)
        }

        return lines.enumerated().map { index, line in
            .line(MarkdownLineBlock(lineIndex: index, line: line))
        }
    }

    private var bottomBar: some View {
        HStack(alignment: .center, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text("\(viewModel.commands.count) command\(viewModel.commands.count == 1 ? "" : "s")")
                    .font(DSFont.caption)
                    .foregroundStyle(.secondary)
                if let reviewPath = viewModel.resolvedReviewPath {
                    Text(reviewPath)
                        .font(DSFont.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .lineLimit(1)
                }
            }

            Spacer()

            DSButton("Request Changes", variant: .secondary) {
                viewModel.requestChanges()
            }
            .disabled(viewModel.commands.isEmpty)
        }
        .padding(.horizontal, DSSpacing.lg)
        .padding(.vertical, DSSpacing.md)
    }

    private var submissionState: some View {
        VStack(spacing: DSSpacing.md) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text(submissionTitle)
                .font(DSFont.heading)
            if let reviewPath = viewModel.resolvedReviewPath {
                Text(reviewPath)
                    .font(DSFont.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var submissionTitle: String {
        switch viewModel.submittedStatus {
        case .approved:
            return "File approved"
        case .changesRequested:
            return "Review submitted"
        case nil:
            return "Review submitted"
        }
    }
}
