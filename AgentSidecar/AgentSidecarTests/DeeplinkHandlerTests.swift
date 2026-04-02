import Testing
import Foundation
@testable import AgentSidecar

@Suite("DeeplinkHandler Tests")
struct DeeplinkHandlerTests {

    @Test("Parse valid diff deeplink URL")
    func parseValidDiffURL() {
        let url = URL(string: "agentsidecar://open?repo=/Users/test/project&scope=workingTree&bundle=.agent-review/pending.json")!

        guard case .some(.openDiff(let payload)) = DeeplinkHandler.parse(url: url) else {
            Issue.record("Expected diff deeplink payload")
            return
        }

        #expect(payload.repoPath == "/Users/test/project")
        #expect(payload.scope == .workingTree)
        #expect(payload.bundlePath == ".agent-review/pending.json")
    }

    @Test("Parse URL with branch scope and base")
    func parseBranchScope() {
        let url = URL(string: "agentsidecar://open?repo=/path&scope=branch&base=develop")!

        guard case .some(.openDiff(let payload)) = DeeplinkHandler.parse(url: url) else {
            Issue.record("Expected diff deeplink payload")
            return
        }

        #expect(payload.scope == .branch)
        #expect(payload.baseBranch == "develop")
    }

    @Test("Parse plan review deeplink URL")
    func parsePlanReviewURL() {
        let url = URL(string: "agentsidecar://plan?file=/Users/test/.claude/plans/feature.md")!

        guard case .some(.openPlan(let filePath)) = DeeplinkHandler.parse(url: url) else {
            Issue.record("Expected plan deeplink payload")
            return
        }

        #expect(filePath == "/Users/test/.claude/plans/feature.md")
    }

    @Test("Parse local file review deeplink URL")
    func parseFileReviewURL() {
        let url = URL(string: "agentsidecar://file?file=/tmp/analysis.md&review=/tmp/analysis.review.json&title=Analysis")!

        guard case .some(.openFileReview(let payload)) = DeeplinkHandler.parse(url: url) else {
            Issue.record("Expected file review deeplink payload")
            return
        }

        #expect(payload.filePath == "/tmp/analysis.md")
        #expect(payload.reviewPath == "/tmp/analysis.review.json")
        #expect(payload.title == "Analysis")
    }

    @Test("Reject missing required parameters")
    func rejectMissingRequiredParameters() {
        let diffURL = URL(string: "agentsidecar://open?scope=staged")!
        let planURL = URL(string: "agentsidecar://plan")!
        let fileReviewURL = URL(string: "agentsidecar://file?review=/tmp/out.json")!

        #expect(DeeplinkHandler.parse(url: diffURL) == nil)
        #expect(DeeplinkHandler.parse(url: planURL) == nil)
        #expect(DeeplinkHandler.parse(url: fileReviewURL) == nil)
    }

    @Test("Reject invalid scheme")
    func rejectInvalidScheme() {
        let url = URL(string: "https://open?repo=/path")!
        #expect(DeeplinkHandler.parse(url: url) == nil)
    }

    @Test("Reject invalid host")
    func rejectInvalidHost() {
        let url = URL(string: "agentsidecar://review?repo=/path")!
        #expect(DeeplinkHandler.parse(url: url) == nil)
    }

    @Test("Build diff URL with all parameters")
    func buildDiffURL() {
        let url = DeeplinkHandler.buildURL(
            repoPath: "/Users/test/project",
            scope: .workingTree,
            baseBranch: "main",
            bundlePath: ".agent-review/pending.json"
        )

        #expect(url != nil)
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        #expect(components?.scheme == "agentsidecar")
        #expect(components?.host == "open")

        let queryItems = components?.queryItems ?? []
        #expect(queryItems.contains { $0.name == "repo" && $0.value == "/Users/test/project" })
        #expect(queryItems.contains { $0.name == "scope" && $0.value == "workingTree" })
        #expect(queryItems.contains { $0.name == "base" && $0.value == "main" })
        #expect(queryItems.contains { $0.name == "bundle" && $0.value == ".agent-review/pending.json" })
    }

    @Test("Build local file review URL")
    func buildFileReviewURL() {
        let url = DeeplinkHandler.buildFileReviewURL(
            filePath: "/tmp/analysis.md",
            reviewPath: "/tmp/analysis.review.json",
            title: "Analysis Review"
        )

        #expect(url != nil)
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        #expect(components?.scheme == "agentsidecar")
        #expect(components?.host == "file")

        let queryItems = components?.queryItems ?? []
        #expect(queryItems.contains { $0.name == "file" && $0.value == "/tmp/analysis.md" })
        #expect(queryItems.contains { $0.name == "review" && $0.value == "/tmp/analysis.review.json" })
        #expect(queryItems.contains { $0.name == "title" && $0.value == "Analysis Review" })
    }

    @Test("Round-trip file review URL")
    func roundTripFileReviewURL() {
        let url = DeeplinkHandler.buildFileReviewURL(
            filePath: "/Users/test/my analysis.md",
            reviewPath: "/Users/test/my analysis.review.json"
        )!

        guard case .some(.openFileReview(let payload)) = DeeplinkHandler.parse(url: url) else {
            Issue.record("Expected file review deeplink payload")
            return
        }

        #expect(payload.filePath == "/Users/test/my analysis.md")
        #expect(payload.reviewPath == "/Users/test/my analysis.review.json")
        #expect(payload.title == nil)
    }
}
