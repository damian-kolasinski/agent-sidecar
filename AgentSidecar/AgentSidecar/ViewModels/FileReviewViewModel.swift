import SwiftUI

@MainActor
final class FileReviewViewModel: ObservableObject {
    @Published var filePath: String?
    @Published var reviewPath: String?
    @Published var title: String?
    @Published var resolvedReviewPath: String?
    @Published var fileContent: String = ""
    @Published var commands: [FileReviewCommand] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSubmitted = false
    @Published var submittedStatus: FileReviewStatus?

    private let store = FileReviewStore()

    var fileName: String {
        if let title, !title.isEmpty {
            return title
        }
        guard let filePath else { return "File Review" }
        return (filePath as NSString).lastPathComponent
    }

    var isMarkdownFile: Bool {
        guard let filePath else { return false }
        let fileExtension = URL(fileURLWithPath: filePath).pathExtension.lowercased()
        return ["md", "markdown"].contains(fileExtension)
    }

    func configure(with payload: FileReviewPayload) {
        filePath = payload.filePath
        reviewPath = payload.reviewPath
        title = payload.title
        loadFile()
    }

    func loadFile() {
        guard let filePath else {
            errorMessage = "No file specified"
            return
        }

        isLoading = true
        errorMessage = nil
        isSubmitted = false
        submittedStatus = nil
        commands = []
        fileContent = ""

        Task {
            do {
                resolvedReviewPath = await store.reviewPath(for: filePath, overridePath: reviewPath)
                fileContent = try await store.loadFile(filePath: filePath)
            } catch {
                errorMessage = "Failed to load file: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    func addCommand(lineNumber: Int, line: String, command: String) {
        commands.append(
            FileReviewCommand(
                lineNumber: lineNumber,
                line: line,
                command: command
            )
        )
    }

    func removeCommand(id: UUID) {
        commands.removeAll { $0.id == id }
    }

    func approve() {
        submit(status: .approved, commands: [])
    }

    func requestChanges() {
        guard !commands.isEmpty else { return }
        submit(status: .changesRequested, commands: commands)
    }

    private func submit(status: FileReviewStatus, commands: [FileReviewCommand]) {
        guard let filePath else { return }

        let review = FileReview(
            filePath: filePath,
            status: status,
            commands: commands
        )

        Task {
            do {
                try await store.saveReview(review, filePath: filePath, reviewPath: reviewPath)
                resolvedReviewPath = await store.reviewPath(for: filePath, overridePath: reviewPath)
                submittedStatus = status
                isSubmitted = true
            } catch {
                errorMessage = "Failed to save review: \(error.localizedDescription)"
            }
        }
    }
}
