import Foundation

struct DeeplinkPayload: Equatable, Sendable {
    let repoPath: String
    let scope: DiffScope?
    let baseBranch: String?
    let bundlePath: String?
}

struct FileReviewPayload: Equatable, Sendable {
    let filePath: String
    let reviewPath: String?
    let title: String?
}
