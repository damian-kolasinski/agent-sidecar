import Foundation

struct PlanReview: Codable, Sendable {
    let status: String
    let comments: [PlanComment]
    let reviewedAt: Date
}
