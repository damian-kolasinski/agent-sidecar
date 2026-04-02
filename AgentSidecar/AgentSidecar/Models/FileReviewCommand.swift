import Foundation

struct FileReviewCommand: Codable, Identifiable, Sendable {
    let id: UUID
    let lineNumber: Int
    let line: String
    let command: String

    init(lineNumber: Int, line: String, command: String) {
        self.id = UUID()
        self.lineNumber = lineNumber
        self.line = line
        self.command = command
    }

    enum CodingKeys: String, CodingKey {
        case lineNumber, line, command
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.lineNumber = try container.decode(Int.self, forKey: .lineNumber)
        self.line = try container.decode(String.self, forKey: .line)
        self.command = try container.decode(String.self, forKey: .command)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lineNumber, forKey: .lineNumber)
        try container.encode(line, forKey: .line)
        try container.encode(command, forKey: .command)
    }
}
