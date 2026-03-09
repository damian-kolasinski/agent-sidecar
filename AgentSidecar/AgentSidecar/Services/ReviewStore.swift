import Foundation

actor ReviewStore {
    private static let directoryName = ".agent-review"
    private static let fileName = "pending.json"

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func bundlePath(for repoPath: String) -> String {
        (repoPath as NSString).appendingPathComponent("\(Self.directoryName)/\(Self.fileName)")
    }

    func modificationDate(repoPath: String) -> Date? {
        let path = bundlePath(for: repoPath)
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let date = attrs[.modificationDate] as? Date else {
            return nil
        }
        return date
    }

    func load(repoPath: String) async throws -> ReviewBundle? {
        let path = bundlePath(for: repoPath)
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            return nil
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(ReviewBundle.self, from: data)
    }

    func save(_ bundle: ReviewBundle) async throws {
        let dirPath = (bundle.repoPath as NSString).appendingPathComponent(Self.directoryName)
        let filePath = (dirPath as NSString).appendingPathComponent(Self.fileName)

        // Create directory if needed
        try FileManager.default.createDirectory(
            atPath: dirPath,
            withIntermediateDirectories: true
        )

        // Atomic write
        let data = try encoder.encode(bundle)
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        try data.write(to: tempURL, options: .atomic)

        let destURL = URL(fileURLWithPath: filePath)
        if FileManager.default.fileExists(atPath: filePath) {
            try FileManager.default.removeItem(at: destURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: destURL)
    }
}
