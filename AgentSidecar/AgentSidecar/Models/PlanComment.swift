import Foundation

struct PlanComment: Codable, Identifiable, Sendable {
    let id: UUID
    let line: String
    let comment: String

    init(line: String, comment: String) {
        self.id = UUID()
        self.line = line
        self.comment = comment
    }

    enum CodingKeys: String, CodingKey {
        case line, comment
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.line = try container.decode(String.self, forKey: .line)
        self.comment = try container.decode(String.self, forKey: .comment)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(line, forKey: .line)
        try container.encode(comment, forKey: .comment)
    }
}
