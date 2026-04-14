import SwiftUI

struct GapExpansion {
    var fromTop: Int = 0
    var fromBottom: Int = 0
}

@MainActor
final class DiffDetailViewModel: ObservableObject {
    @Published var composerAnchor: String?
    @Published var composerFilePath: String?
    @Published var composerText = ""
    @Published var expandedThreads: Set<String> = []
    @Published var collapsedFiles: Set<String> = []
    @Published var reviewedFiles: Set<String> = []
    @Published var gapExpansions: [String: GapExpansion] = [:]

    var isComposerOpen: Bool {
        composerAnchor != nil
    }

    func openComposer(filePath: String, anchor: String) {
        composerFilePath = filePath
        composerAnchor = anchor
        composerText = ""
    }

    func closeComposer() {
        composerAnchor = nil
        composerFilePath = nil
        composerText = ""
    }

    func toggleFileCollapsed(_ filePath: String) {
        if collapsedFiles.contains(filePath) {
            collapsedFiles.remove(filePath)
        } else {
            collapsedFiles.insert(filePath)
        }
    }

    func isFileCollapsed(_ filePath: String) -> Bool {
        collapsedFiles.contains(filePath)
    }

    func toggleFileReviewed(_ filePath: String) {
        if reviewedFiles.contains(filePath) {
            reviewedFiles.remove(filePath)
        } else {
            reviewedFiles.insert(filePath)
            collapsedFiles.insert(filePath)
        }
    }

    func isFileReviewed(_ filePath: String) -> Bool {
        reviewedFiles.contains(filePath)
    }

    func toggleThread(_ anchor: String) {
        if expandedThreads.contains(anchor) {
            expandedThreads.remove(anchor)
        } else {
            expandedThreads.insert(anchor)
        }
    }

    func isThreadExpanded(_ anchor: String) -> Bool {
        expandedThreads.contains(anchor)
    }

    // MARK: - Gap Expansion

    func expansion(for gapID: String) -> GapExpansion {
        gapExpansions[gapID] ?? GapExpansion()
    }

    func expandGapDown(_ gapID: String, totalLines: Int) {
        var exp = gapExpansions[gapID] ?? GapExpansion()
        let remaining = max(0, totalLines - exp.fromTop - exp.fromBottom)
        exp.fromTop += min(20, remaining)
        gapExpansions[gapID] = exp
    }

    func expandGapUp(_ gapID: String, totalLines: Int) {
        var exp = gapExpansions[gapID] ?? GapExpansion()
        let remaining = max(0, totalLines - exp.fromTop - exp.fromBottom)
        exp.fromBottom += min(20, remaining)
        gapExpansions[gapID] = exp
    }
}
