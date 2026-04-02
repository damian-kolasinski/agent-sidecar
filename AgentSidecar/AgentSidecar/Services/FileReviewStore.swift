import Foundation

actor FileReviewStore {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    func loadFile(filePath: String) throws -> String {
        let url = URL(fileURLWithPath: filePath)
        return try String(contentsOf: url, encoding: .utf8)
    }

    func reviewPath(for filePath: String, overridePath: String? = nil) -> String {
        if let overridePath, !overridePath.isEmpty {
            return overridePath
        }

        let url = URL(fileURLWithPath: filePath)
        let directoryURL = url.deletingLastPathComponent()
        let baseName = url.deletingPathExtension().lastPathComponent
        let reviewFileName = "\(baseName).review.json"
        return directoryURL.appendingPathComponent(reviewFileName).path
    }

    func saveReview(_ review: FileReview, filePath: String, reviewPath overridePath: String? = nil) throws {
        let reviewPath = reviewPath(for: filePath, overridePath: overridePath)
        let dirPath = (reviewPath as NSString).deletingLastPathComponent

        try FileManager.default.createDirectory(
            atPath: dirPath,
            withIntermediateDirectories: true
        )

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
