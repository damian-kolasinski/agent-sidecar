import Foundation

struct ViewedFilesData: Codable {
    var version: Int = 1
    /// scope rawValue -> (displayPath -> diffContentHash)
    var scopes: [String: [String: String]]

    init() {
        version = 1
        scopes = [:]
    }
}

actor ViewedFilesStore {
    private static let directoryName = ".agent-review"
    private static let fileName = "viewed.json"

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private let decoder = JSONDecoder()

    private func filePath(for repoPath: String) -> String {
        (repoPath as NSString).appendingPathComponent("\(Self.directoryName)/\(Self.fileName)")
    }

    func load(repoPath: String) -> ViewedFilesData {
        let path = filePath(for: repoPath)
        guard FileManager.default.fileExists(atPath: path),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let decoded = try? decoder.decode(ViewedFilesData.self, from: data) else {
            return ViewedFilesData()
        }
        return decoded
    }

    func save(_ data: ViewedFilesData, repoPath: String) throws {
        let dirPath = (repoPath as NSString).appendingPathComponent(Self.directoryName)
        let path = (dirPath as NSString).appendingPathComponent(Self.fileName)

        try FileManager.default.createDirectory(
            atPath: dirPath,
            withIntermediateDirectories: true
        )
        ReviewStore.ensureGitignore(in: dirPath)

        let encoded = try encoder.encode(data)
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        try encoded.write(to: tempURL, options: .atomic)

        let destURL = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: path) {
            try FileManager.default.removeItem(at: destURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: destURL)
    }
}
