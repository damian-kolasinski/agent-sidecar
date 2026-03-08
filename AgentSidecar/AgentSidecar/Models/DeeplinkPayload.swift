import Foundation

struct DeeplinkPayload: Sendable {
    let repoPath: String
    let scope: DiffScope?
    let baseBranch: String?
    let bundlePath: String?
}
