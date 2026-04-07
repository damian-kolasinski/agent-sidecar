import Testing
import Foundation
@testable import AgentSidecar

@Suite("AppViewModel Tests")
@MainActor
struct AppViewModelTests {

    private func tempRepoPath() -> String {
        let path = NSTemporaryDirectory() + "agent-sidecar-app-view-model-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }

    private func cleanup(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }

    @Test("Delete removes human-authored comments")
    func deleteHumanComment() {
        let repoPath = tempRepoPath()
        defer { cleanup(repoPath) }

        let viewModel = AppViewModel()
        let humanComment = ReviewComment(
            filePath: "Sources/main.swift",
            lineAnchor: "_:10",
            diffScope: .workingTree,
            body: "Remove this"
        )
        viewModel.reviewBundle = ReviewBundle(
            repoPath: repoPath,
            scope: .workingTree,
            comments: [humanComment]
        )

        viewModel.deleteComment(commentID: humanComment.id)

        #expect(viewModel.reviewBundle?.comments.isEmpty == true)
    }

    @Test("Delete does not remove agent-authored comments")
    func deleteAgentCommentIsIgnored() {
        let repoPath = tempRepoPath()
        defer { cleanup(repoPath) }

        let viewModel = AppViewModel()
        let agentComment = ReviewComment(
            filePath: "Sources/main.swift",
            lineAnchor: "_:10",
            diffScope: .workingTree,
            body: "Keep this",
            author: "claude"
        )
        viewModel.reviewBundle = ReviewBundle(
            repoPath: repoPath,
            scope: .workingTree,
            comments: [agentComment]
        )

        viewModel.deleteComment(commentID: agentComment.id)

        #expect(viewModel.reviewBundle?.comments.count == 1)
        #expect(viewModel.reviewBundle?.comments.first?.id == agentComment.id)
    }
}
