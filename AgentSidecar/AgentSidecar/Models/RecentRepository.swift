import Foundation

struct RecentRepository: Codable, Identifiable, Sendable {
    var id: String { path }
    let path: String
    let lastOpenedAt: Date

    var displayName: String {
        (path as NSString).lastPathComponent
    }

    var abbreviatedPath: String {
        (path as NSString).abbreviatingWithTildeInPath
    }
}
