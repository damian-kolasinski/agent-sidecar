import SwiftUI

enum AppMode: Equatable {
    case diffReview
    case planReview(filePath: String)
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published var currentMode: AppMode = .diffReview
    @Published var repoPath: String?
    @Published var scope: DiffScope = .workingTree
    @Published var baseBranch: String = "main"
    @Published var fileDiffs: [FileDiff] = []
    @Published var selectedFilePath: String?
    @Published var reviewBundle: ReviewBundle?
    @Published var scrollToFilePath: String?
    @Published var recentRepositories: [RecentRepository] = []
    @Published var planFiles: [PlanFileEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var gitService: GitService?
    private let reviewStore = ReviewStore()
    private let recentStore = RecentRepositoriesStore()
    private var fileWatcherTask: Task<Void, Never>?
    private var lastKnownModDate: Date?
    private var savesInFlight = 0

    deinit {
        fileWatcherTask?.cancel()
    }

    var selectedFileDiff: FileDiff? {
        fileDiffs.first { $0.displayPath == selectedFilePath }
    }

    private func debugLog(_ msg: String) {
        let line = "[\(Date())] \(msg)\n"
        let path = "/tmp/agentsidecar-debug.log"
        if let handle = FileHandle(forWritingAtPath: path) {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            handle.closeFile()
        } else {
            FileManager.default.createFile(atPath: path, contents: Data(line.utf8))
        }
    }

    func handleDeeplink(url: URL) {
        debugLog("handleDeeplink called with url: \(url)")
        debugLog("scheme=\(url.scheme ?? "nil") host=\(url.host ?? "nil")")

        guard let action = DeeplinkHandler.parse(url: url) else {
            debugLog("parse returned nil — invalid deeplink")
            errorMessage = "Invalid deeplink URL"
            return
        }

        debugLog("parsed action: \(action)")

        switch action {
        case .openDiff(let payload):
            currentMode = .diffReview
            repoPath = payload.repoPath
            if let scope = payload.scope {
                self.scope = scope
            }
            if let base = payload.baseBranch {
                self.baseBranch = base
            }
            Task {
                await recordRecentRepo(payload.repoPath)
                await refresh()
            }

        case .openPlan(let filePath):
            currentMode = .planReview(filePath: filePath)
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
            await recordRecentRepo(url.path)
            await refresh()
        }
    }

    func refresh() async {
        guard let repoPath else {
            errorMessage = "No repository selected"
            return
        }

        stopWatching()
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
            lastKnownModDate = await reviewStore.modificationDate(repoPath: repoPath)
            updateWatcher()

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
        updateWatcher()

        savesInFlight += 1
        Task {
            try? await reviewStore.save(bundle)
            lastKnownModDate = await reviewStore.modificationDate(repoPath: bundle.repoPath)
            savesInFlight -= 1
        }
    }

    func toggleResolved(commentID: UUID) {
        guard var bundle = reviewBundle,
              let index = bundle.comments.firstIndex(where: { $0.id == commentID }) else {
            return
        }

        bundle.comments[index].resolved.toggle()
        reviewBundle = bundle
        updateWatcher()

        savesInFlight += 1
        Task {
            try? await reviewStore.save(bundle)
            lastKnownModDate = await reviewStore.modificationDate(repoPath: bundle.repoPath)
            savesInFlight -= 1
        }
    }

    func saveReview() {
        guard let bundle = reviewBundle else { return }
        savesInFlight += 1
        Task {
            do {
                try await reviewStore.save(bundle)
                lastKnownModDate = await reviewStore.modificationDate(repoPath: bundle.repoPath)
            } catch {
                errorMessage = "Failed to save review: \(error.localizedDescription)"
            }
            savesInFlight -= 1
        }
    }

    func commentsForFile(_ filePath: String) -> [ReviewComment] {
        reviewBundle?.comments.filter { $0.filePath == filePath } ?? []
    }

    func commentsForAnchor(_ filePath: String, anchor: String) -> [ReviewComment] {
        commentsForFile(filePath).filter { $0.lineAnchor == anchor }
    }

    // MARK: - File Watcher

    private var hasUnresolvedComments: Bool {
        reviewBundle?.comments.contains { !$0.resolved } ?? false
    }

    private func updateWatcher() {
        if hasUnresolvedComments {
            startWatchingIfNeeded()
        } else {
            stopWatching()
        }
    }

    private func startWatchingIfNeeded() {
        guard fileWatcherTask == nil else { return }
        fileWatcherTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { break }
                await self?.checkForExternalChanges()
            }
        }
    }

    private func stopWatching() {
        fileWatcherTask?.cancel()
        fileWatcherTask = nil
    }

    private func checkForExternalChanges() async {
        guard let repoPath, savesInFlight == 0 else { return }
        let modDate = await reviewStore.modificationDate(repoPath: repoPath)
        guard let modDate, modDate != lastKnownModDate else { return }
        lastKnownModDate = modDate

        do {
            if let bundle = try await reviewStore.load(repoPath: repoPath) {
                reviewBundle = bundle
                updateWatcher()
            }
        } catch {
            // Silently ignore reload errors — file may be mid-write
        }
    }

    // MARK: - Plan Files

    func loadPlanFiles() {
        let fm = FileManager.default
        let plansDir = (NSHomeDirectory() as NSString).appendingPathComponent(".claude/plans")
        guard let files = try? fm.contentsOfDirectory(atPath: plansDir) else {
            planFiles = []
            return
        }

        let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)

        planFiles = files
            .filter { $0.hasSuffix(".md") }
            .compactMap { fileName -> PlanFileEntry? in
                let fullPath = (plansDir as NSString).appendingPathComponent(fileName)
                guard let attrs = try? fm.attributesOfItem(atPath: fullPath),
                      let modDate = attrs[.modificationDate] as? Date else {
                    return nil
                }
                let title = Self.firstHeading(atPath: fullPath) ?? fileName
                return PlanFileEntry(path: fullPath, title: title, modifiedAt: modDate)
            }
            .filter { $0.modifiedAt > oneWeekAgo }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }

    private static func firstHeading(atPath path: String) -> String? {
        guard let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }
        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") {
                return String(trimmed.dropFirst(2))
            }
        }
        return nil
    }

    // MARK: - Recent Repositories

    func loadRecents() async {
        let all = await recentStore.load()
        recentRepositories = all.filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    func selectRecentRepo(_ repo: RecentRepository) {
        repoPath = repo.path
        selectedFilePath = nil
        Task {
            await recordRecentRepo(repo.path)
            await refresh()
        }
    }

    func removeRecentRepo(_ repo: RecentRepository) {
        Task {
            await recentStore.remove(path: repo.path)
            await loadRecents()
        }
    }

    func clearRecents() {
        Task {
            await recentStore.clearAll()
            recentRepositories = []
        }
    }

    private func recordRecentRepo(_ path: String) async {
        await recentStore.addOrUpdate(path: path)
        await loadRecents()
    }
}
