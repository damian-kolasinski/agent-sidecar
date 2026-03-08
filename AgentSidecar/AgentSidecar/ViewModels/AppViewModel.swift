import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var repoPath: String?
    @Published var scope: DiffScope = .workingTree
    @Published var baseBranch: String = "main"
    @Published var fileDiffs: [FileDiff] = []
    @Published var selectedFilePath: String?
    @Published var reviewBundle: ReviewBundle?
    @Published var scrollToFilePath: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var gitService: GitService?
    private let reviewStore = ReviewStore()

    var selectedFileDiff: FileDiff? {
        fileDiffs.first { $0.displayPath == selectedFilePath }
    }

    func handleDeeplink(url: URL) {
        guard let payload = DeeplinkHandler.parse(url: url) else {
            errorMessage = "Invalid deeplink URL"
            return
        }

        repoPath = payload.repoPath
        if let scope = payload.scope {
            self.scope = scope
        }
        if let base = payload.baseBranch {
            self.baseBranch = base
        }

        Task {
            await refresh()
        }
    }

    func openDirectoryPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a Git repository"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        repoPath = url.path
        Task {
            await refresh()
        }
    }

    func refresh() async {
        guard let repoPath else {
            errorMessage = "No repository selected"
            return
        }

        isLoading = true
        errorMessage = nil

        let service = GitService(repoPath: repoPath)
        self.gitService = service

        do {
            let isValid = try await service.validateRepository()
            guard isValid else {
                errorMessage = "Not a valid Git repository"
                isLoading = false
                return
            }

            if scope == .branch {
                _ = await service.fetchRemoteBranch(baseBranch)
            }

            let rawDiff = try await service.diff(scope: scope, baseBranch: baseBranch)
            fileDiffs = DiffParser.parse(rawDiff)

            // Load existing review bundle
            reviewBundle = try await reviewStore.load(repoPath: repoPath)
            if reviewBundle == nil {
                reviewBundle = ReviewBundle(repoPath: repoPath, scope: scope)
            }

            // Select first file if nothing selected
            if selectedFilePath == nil {
                selectedFilePath = fileDiffs.first?.displayPath
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func changeScope(_ newScope: DiffScope) {
        Task { @MainActor in
            scope = newScope
            selectedFilePath = nil
            await refresh()
        }
    }

    func addComment(filePath: String, lineAnchor: String, body: String) {
        guard var bundle = reviewBundle else { return }

        let comment = ReviewComment(
            filePath: filePath,
            lineAnchor: lineAnchor,
            diffScope: scope,
            body: body
        )
        bundle.comments.append(comment)
        reviewBundle = bundle

        Task {
            try? await reviewStore.save(bundle)
        }
    }

    func toggleResolved(commentID: UUID) {
        guard var bundle = reviewBundle,
              let index = bundle.comments.firstIndex(where: { $0.id == commentID }) else {
            return
        }

        bundle.comments[index].resolved.toggle()
        reviewBundle = bundle

        Task {
            try? await reviewStore.save(bundle)
        }
    }

    func saveReview() {
        guard let bundle = reviewBundle else { return }
        Task {
            do {
                try await reviewStore.save(bundle)
            } catch {
                errorMessage = "Failed to save review: \(error.localizedDescription)"
            }
        }
    }

    func commentsForFile(_ filePath: String) -> [ReviewComment] {
        reviewBundle?.comments.filter { $0.filePath == filePath } ?? []
    }

    func commentsForAnchor(_ filePath: String, anchor: String) -> [ReviewComment] {
        commentsForFile(filePath).filter { $0.lineAnchor == anchor }
    }
}
