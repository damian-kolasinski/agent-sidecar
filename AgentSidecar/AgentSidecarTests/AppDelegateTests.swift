import Testing
import Foundation
@testable import AgentSidecar

@Suite("AppDelegate Tests")
struct AppDelegateTests {

    @Test("Buffers deeplink until handler is attached")
    func buffersIncomingURL() {
        let appDelegate = AppDelegate()
        let url = URL(string: "agentsidecar://file?file=/tmp/analysis.md")!
        var received: URL?

        appDelegate.handleIncomingURL(url)
        #expect(received == nil)

        appDelegate.onOpenURL = { incomingURL in
            received = incomingURL
        }

        #expect(received == url)
    }

    @Test("Delivers deeplink immediately when handler is attached")
    func deliversImmediately() {
        let appDelegate = AppDelegate()
        let url = URL(string: "agentsidecar://plan?file=/tmp/plan.md")!
        var received: URL?

        appDelegate.onOpenURL = { incomingURL in
            received = incomingURL
        }

        appDelegate.handleIncomingURL(url)
        #expect(received == url)
    }
}
