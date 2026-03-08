import Foundation

struct ReviewBundle: Codable, Sendable {
    let version: Int
    let repoPath: String
    let scope: DiffScope
    let baseBranch: String?
    let createdAt: Date
    var comments: [ReviewComment]

    init(
        version: Int = 1,
        repoPath: String,
        scope: DiffScope,
        baseBranch: String? = nil,
        createdAt: Date = Date(),
        comments: [ReviewComment] = []
    ) {
        self.version = version
        self.repoPath = repoPath
        self.scope = scope
        self.baseBranch = baseBranch
        self.createdAt = createdAt
        self.comments = comments
    }
}
