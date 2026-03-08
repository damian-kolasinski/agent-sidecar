import Foundation

enum FileStatus: String, Codable, Sendable {
    case modified = "M"
    case added = "A"
    case deleted = "D"
    case renamed = "R"
    case binary = "B"

    var displayLabel: String {
        switch self {
        case .modified: "M"
        case .added: "A"
        case .deleted: "D"
        case .renamed: "R"
        case .binary: "B"
        }
    }
}

enum DiffLineType: String, Codable, Sendable {
    case context
    case addition
    case deletion
}

struct DiffLine: Identifiable, Sendable {
    let id: String
    let type: DiffLineType
    let content: String
    let oldLineNumber: Int?
    let newLineNumber: Int?
    let noNewlineAtEnd: Bool

    var anchor: String {
        let old = oldLineNumber.map(String.init) ?? "_"
        let new = newLineNumber.map(String.init) ?? "_"
        return "\(old):\(new)"
    }
}

struct DiffHunk: Identifiable, Sendable {
    let id: String
    let header: String
    let oldStart: Int
    let oldCount: Int
    let newStart: Int
    let newCount: Int
    let lines: [DiffLine]
}

struct FileDiff: Identifiable, Sendable {
    let id: String
    let oldPath: String
    let newPath: String
    let status: FileStatus
    let isBinary: Bool
    let hunks: [DiffHunk]

    var displayPath: String {
        if status == .renamed && oldPath != newPath {
            return "\(oldPath) → \(newPath)"
        }
        return newPath.isEmpty ? oldPath : newPath
    }

    var additionCount: Int {
        hunks.flatMap(\.lines).filter { $0.type == .addition }.count
    }

    var deletionCount: Int {
        hunks.flatMap(\.lines).filter { $0.type == .deletion }.count
    }
}
