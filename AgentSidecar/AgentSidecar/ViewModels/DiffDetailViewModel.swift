import SwiftUI

@MainActor
final class DiffDetailViewModel: ObservableObject {
    @Published var composerAnchor: String?
    @Published var composerFilePath: String?
    @Published var composerText = ""
    @Published var expandedThreads: Set<String> = []
    @Published var collapsedFiles: Set<String> = []

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
}
