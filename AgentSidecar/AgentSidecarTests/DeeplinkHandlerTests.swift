import Testing
import Foundation
@testable import AgentSidecar

@Suite("DeeplinkHandler Tests")
struct DeeplinkHandlerTests {

    @Test("Parse valid deeplink URL")
    func parseValidURL() {
        let url = URL(string: "agentsidecar://open?repo=/Users/test/project&scope=workingTree&bundle=.agent-review/pending.json")!
        let payload = DeeplinkHandler.parse(url: url)

        #expect(payload != nil)
        #expect(payload?.repoPath == "/Users/test/project")
        #expect(payload?.scope == .workingTree)
        #expect(payload?.bundlePath == ".agent-review/pending.json")
    }

    @Test("Parse URL with staged scope")
    func parseStagedScope() {
        let url = URL(string: "agentsidecar://open?repo=/path/to/repo&scope=staged")!
        let payload = DeeplinkHandler.parse(url: url)

        #expect(payload?.scope == .staged)
    }

    @Test("Parse URL with branch scope and base")
    func parseBranchScope() {
        let url = URL(string: "agentsidecar://open?repo=/path&scope=branch&base=develop")!
        let payload = DeeplinkHandler.parse(url: url)

        #expect(payload?.scope == .branch)
        #expect(payload?.baseBranch == "develop")
    }

    @Test("Parse URL with only repo path")
    func parseMinimalURL() {
        let url = URL(string: "agentsidecar://open?repo=/path/to/repo")!
        let payload = DeeplinkHandler.parse(url: url)

        #expect(payload != nil)
        #expect(payload?.repoPath == "/path/to/repo")
        #expect(payload?.scope == nil)
        #expect(payload?.baseBranch == nil)
        #expect(payload?.bundlePath == nil)
    }

    @Test("Reject invalid scheme")
    func rejectInvalidScheme() {
        let url = URL(string: "https://open?repo=/path")!
        let payload = DeeplinkHandler.parse(url: url)
        #expect(payload == nil)
    }

    @Test("Reject invalid host")
    func rejectInvalidHost() {
        let url = URL(string: "agentsidecar://review?repo=/path")!
        let payload = DeeplinkHandler.parse(url: url)
        #expect(payload == nil)
    }

    @Test("Reject missing repo parameter")
    func rejectMissingRepo() {
        let url = URL(string: "agentsidecar://open?scope=staged")!
        let payload = DeeplinkHandler.parse(url: url)
        #expect(payload == nil)
    }

    @Test("Build URL with all parameters")
    func buildFullURL() {
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

    @Test("Build URL without optional parameters")
    func buildMinimalURL() {
        let url = DeeplinkHandler.buildURL(repoPath: "/path")
        #expect(url != nil)

        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        #expect(queryItems.count == 2) // repo + scope
        #expect(!queryItems.contains { $0.name == "base" })
        #expect(!queryItems.contains { $0.name == "bundle" })
    }

    @Test("Round-trip: build then parse")
    func roundTrip() {
        let url = DeeplinkHandler.buildURL(
            repoPath: "/Users/test/my project",
            scope: .staged,
            bundlePath: ".agent-review/pending.json"
        )!
        let payload = DeeplinkHandler.parse(url: url)

        #expect(payload?.repoPath == "/Users/test/my project")
        #expect(payload?.scope == .staged)
        #expect(payload?.bundlePath == ".agent-review/pending.json")
    }
}
