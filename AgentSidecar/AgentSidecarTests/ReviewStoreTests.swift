import Testing
import Foundation
@testable import AgentSidecar

@Suite("ReviewStore Tests")
struct ReviewStoreTests {

    private func tempRepoPath() -> String {
        let path = NSTemporaryDirectory() + "agent-sidecar-test-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }

    private func cleanup(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }

    @Test("Save and load review bundle")
    func saveAndLoad() async throws {
        let repoPath = tempRepoPath()
        defer { cleanup(repoPath) }

        let store = ReviewStore()
        let comment = ReviewComment(
            filePath: "Sources/main.swift",
            lineAnchor: "_:15",
            diffScope: .workingTree,
            body: "Add a guard clause here."
        )
        let bundle = ReviewBundle(
            repoPath: repoPath,
            scope: .workingTree,
            comments: [comment]
        )

        try await store.save(bundle)
        let loaded = try await store.load(repoPath: repoPath)

        #expect(loaded != nil)
        #expect(loaded?.version == 1)
        #expect(loaded?.repoPath == repoPath)
        #expect(loaded?.scope == .workingTree)
        #expect(loaded?.comments.count == 1)
        #expect(loaded?.comments[0].body == "Add a guard clause here.")
        #expect(loaded?.comments[0].lineAnchor == "_:15")
        #expect(loaded?.comments[0].author == "human")
        #expect(loaded?.comments[0].resolved == false)
    }

    @Test("Load returns nil for missing file")
    func loadMissing() async throws {
        let repoPath = tempRepoPath()
        defer { cleanup(repoPath) }

        let store = ReviewStore()
        let loaded = try await store.load(repoPath: repoPath)
        #expect(loaded == nil)
    }

    @Test("Save creates .agent-review directory")
    func savesCreatesDirectory() async throws {
        let repoPath = tempRepoPath()
        defer { cleanup(repoPath) }

        let store = ReviewStore()
        let bundle = ReviewBundle(repoPath: repoPath, scope: .staged)
        try await store.save(bundle)

        let dirPath = (repoPath as NSString).appendingPathComponent(".agent-review")
        var isDir: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: dirPath, isDirectory: &isDir))
        #expect(isDir.boolValue)
    }

    @Test("Bundle path is correct")
    func bundlePath() async {
        let store = ReviewStore()
        let path = await store.bundlePath(for: "/Users/test/project")
        #expect(path == "/Users/test/project/.agent-review/pending.json")
    }

    @Test("Multiple comments round-trip")
    func multipleComments() async throws {
        let repoPath = tempRepoPath()
        defer { cleanup(repoPath) }

        let store = ReviewStore()
        let comments = [
            ReviewComment(filePath: "file1.swift", lineAnchor: "1:1", diffScope: .workingTree, body: "First"),
            ReviewComment(filePath: "file1.swift", lineAnchor: "2:_", diffScope: .workingTree, body: "Second"),
            ReviewComment(filePath: "file2.swift", lineAnchor: "_:5", diffScope: .staged, body: "Third", author: "claude"),
        ]
        let bundle = ReviewBundle(repoPath: repoPath, scope: .workingTree, comments: comments)

        try await store.save(bundle)
        let loaded = try await store.load(repoPath: repoPath)

        #expect(loaded?.comments.count == 3)
        #expect(loaded?.comments[2].author == "claude")
    }

    @Test("JSON output is valid and readable")
    func jsonOutput() async throws {
        let repoPath = tempRepoPath()
        defer { cleanup(repoPath) }

        let store = ReviewStore()
        let bundle = ReviewBundle(repoPath: repoPath, scope: .workingTree, comments: [
            ReviewComment(filePath: "test.swift", lineAnchor: "_:1", diffScope: .workingTree, body: "Test comment"),
        ])
        try await store.save(bundle)

        let filePath = await store.bundlePath(for: repoPath)
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["version"] as? Int == 1)
        #expect(json?["repoPath"] as? String == repoPath)
        #expect((json?["comments"] as? [[String: Any]])?.count == 1)
    }
}
