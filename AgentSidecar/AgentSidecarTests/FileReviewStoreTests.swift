import Testing
import Foundation
@testable import AgentSidecar

@Suite("FileReviewStore Tests")
struct FileReviewStoreTests {

    private func tempDirectory() -> String {
        let path = NSTemporaryDirectory() + "agent-sidecar-file-review-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }

    private func cleanup(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }

    @Test("Default review path is derived from the source file")
    func defaultReviewPath() async {
        let store = FileReviewStore()
        let reviewPath = await store.reviewPath(for: "/tmp/analysis.md")
        #expect(reviewPath == "/tmp/analysis.review.json")
    }

    @Test("Override review path is preserved")
    func overrideReviewPath() async {
        let store = FileReviewStore()
        let reviewPath = await store.reviewPath(
            for: "/tmp/analysis.md",
            overridePath: "/tmp/reviews/analysis-feedback.json"
        )
        #expect(reviewPath == "/tmp/reviews/analysis-feedback.json")
    }

    @Test("Save review creates readable JSON")
    func saveReview() async throws {
        let tempDir = tempDirectory()
        defer { cleanup(tempDir) }

        let filePath = (tempDir as NSString).appendingPathComponent("analysis.md")
        let reviewPath = (tempDir as NSString).appendingPathComponent("analysis.review.json")
        try "## Summary\nDraft".write(toFile: filePath, atomically: true, encoding: .utf8)

        let store = FileReviewStore()
        let review = FileReview(
            filePath: filePath,
            status: .changesRequested,
            commands: [
                FileReviewCommand(
                    lineNumber: 2,
                    line: "Draft",
                    command: "Replace this with a tighter executive summary."
                ),
            ]
        )

        try await store.saveReview(review, filePath: filePath, reviewPath: reviewPath)

        let data = try Data(contentsOf: URL(fileURLWithPath: reviewPath))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let commands = json?["commands"] as? [[String: Any]]

        #expect(json?["version"] as? Int == 1)
        #expect(json?["filePath"] as? String == filePath)
        #expect(json?["status"] as? String == "changes_requested")
        #expect(commands?.count == 1)
        #expect(commands?.first?["lineNumber"] as? Int == 2)
        #expect(commands?.first?["command"] as? String == "Replace this with a tighter executive summary.")
    }

    @Test("Load file returns file contents")
    func loadFile() async throws {
        let tempDir = tempDirectory()
        defer { cleanup(tempDir) }

        let filePath = (tempDir as NSString).appendingPathComponent("analysis.md")
        try "# Notes\nLine two".write(toFile: filePath, atomically: true, encoding: .utf8)

        let store = FileReviewStore()
        let content = try await store.loadFile(filePath: filePath)

        #expect(content == "# Notes\nLine two")
    }
}
