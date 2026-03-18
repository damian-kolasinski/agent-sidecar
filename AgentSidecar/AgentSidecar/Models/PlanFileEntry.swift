import Foundation

struct PlanFileEntry: Identifiable {
    var id: String { path }
    let path: String
    let title: String
    let modifiedAt: Date

    var fileName: String {
        (path as NSString).lastPathComponent
    }

    /// Human-readable slug derived from the filename (e.g. "vast-forging-tarjan")
    var slug: String {
        (fileName as NSString).deletingPathExtension
    }
}
