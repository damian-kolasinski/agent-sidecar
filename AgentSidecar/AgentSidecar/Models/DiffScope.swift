import Foundation

enum DiffScope: String, Codable, CaseIterable, Identifiable, Sendable {
    case workingTree
    case staged
    case branch

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .workingTree: "Working Tree"
        case .staged: "Staged"
        case .branch: "Branch"
        }
    }

    func gitArguments(baseBranch: String = "main") -> [String] {
        switch self {
        case .workingTree:
            return ["diff"]
        case .staged:
            return ["diff", "--staged"]
        case .branch:
            return ["diff", "origin/\(baseBranch)...HEAD"]
        }
    }

    func gitFileArguments(baseBranch: String = "main") -> [String] {
        switch self {
        case .workingTree:
            return ["diff", "--name-status"]
        case .staged:
            return ["diff", "--staged", "--name-status"]
        case .branch:
            return ["diff", "origin/\(baseBranch)...HEAD", "--name-status"]
        }
    }
}
