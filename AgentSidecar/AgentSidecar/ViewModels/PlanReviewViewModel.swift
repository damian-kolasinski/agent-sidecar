import SwiftUI

@MainActor
final class PlanReviewViewModel: ObservableObject {
    @Published var planFilePath: String?
    @Published var planContent: String = ""
    @Published var comments: [PlanComment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSubmitted = false

    private let store = PlanReviewStore()

    var planFileName: String {
        guard let path = planFilePath else { return "Plan" }
        return (path as NSString).lastPathComponent
    }

    func loadPlan() {
        guard let filePath = planFilePath else {
            errorMessage = "No plan file specified"
            return
        }

        isLoading = true
        errorMessage = nil
        isSubmitted = false
        comments = []

        Task {
            do {
                planContent = try await store.loadPlan(filePath: filePath)
            } catch {
                errorMessage = "Failed to load plan: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    func addComment(line: String, comment: String) {
        comments.append(PlanComment(line: line, comment: comment))
    }

    func removeComment(at index: Int) {
        guard comments.indices.contains(index) else { return }
        comments.remove(at: index)
    }

    func removeComment(id: UUID) {
        comments.removeAll { $0.id == id }
    }

    func approve() {
        guard let filePath = planFilePath else { return }

        let review = PlanReview(
            status: "approved",
            comments: [],
            reviewedAt: Date()
        )

        Task {
            do {
                try await store.saveReview(review, for: filePath)
                isSubmitted = true
            } catch {
                errorMessage = "Failed to save review: \(error.localizedDescription)"
            }
        }
    }

    func requestChanges() {
        guard let filePath = planFilePath, !comments.isEmpty else { return }

        let review = PlanReview(
            status: "changes_requested",
            comments: comments,
            reviewedAt: Date()
        )

        Task {
            do {
                try await store.saveReview(review, for: filePath)
                isSubmitted = true
            } catch {
                errorMessage = "Failed to save review: \(error.localizedDescription)"
            }
        }
    }
}
