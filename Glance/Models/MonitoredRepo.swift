import Foundation

struct MonitoredRepo: Identifiable, Codable, Equatable {
    var id: String { "\(owner)/\(name)" }
    let owner: String
    let name: String

    var fullName: String { "\(owner)/\(name)" }
}
