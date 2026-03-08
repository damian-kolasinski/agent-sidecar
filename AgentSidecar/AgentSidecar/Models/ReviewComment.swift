import Foundation

struct ReviewComment: Codable, Identifiable, Sendable {
    let id: UUID
    let filePath: String
    let lineAnchor: String
    let diffScope: DiffScope
    let body: String
    let author: String
    let createdAt: Date
    var resolved: Bool

    init(
        id: UUID = UUID(),
        filePath: String,
        lineAnchor: String,
        diffScope: DiffScope,
        body: String,
        author: String = "human",
        createdAt: Date = Date(),
        resolved: Bool = false
    ) {
        self.id = id
        self.filePath = filePath
        self.lineAnchor = lineAnchor
        self.diffScope = diffScope
        self.body = body
        self.author = author
        self.createdAt = createdAt
        self.resolved = resolved
    }
}
