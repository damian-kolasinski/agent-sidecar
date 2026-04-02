import Foundation

enum FileReviewStatus: String, Codable, Sendable {
    case approved
    case changesRequested = "changes_requested"
}

struct FileReview: Codable, Sendable {
    let version: Int
    let filePath: String
    let status: FileReviewStatus
    let commands: [FileReviewCommand]
    let reviewedAt: Date

    init(
        version: Int = 1,
        filePath: String,
        status: FileReviewStatus,
        commands: [FileReviewCommand],
        reviewedAt: Date = Date()
    ) {
        self.version = version
        self.filePath = filePath
        self.status = status
        self.commands = commands
        self.reviewedAt = reviewedAt
    }
}
