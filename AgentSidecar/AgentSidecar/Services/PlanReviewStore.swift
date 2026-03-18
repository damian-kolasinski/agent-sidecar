import Foundation

actor PlanReviewStore {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    func loadPlan(filePath: String) throws -> String {
        let url = URL(fileURLWithPath: filePath)
        return try String(contentsOf: url, encoding: .utf8)
    }

    func saveReview(_ review: PlanReview, for planFilePath: String) throws {
        let slug = (planFilePath as NSString).lastPathComponent
            .replacingOccurrences(of: ".md", with: "")
        let dir = (planFilePath as NSString).deletingLastPathComponent
        let reviewPath = (dir as NSString).appendingPathComponent("\(slug).review.json")

        let data = try encoder.encode(review)
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        try data.write(to: tempURL, options: .atomic)

        let destURL = URL(fileURLWithPath: reviewPath)
        if FileManager.default.fileExists(atPath: reviewPath) {
            try FileManager.default.removeItem(at: destURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: destURL)
    }
}
