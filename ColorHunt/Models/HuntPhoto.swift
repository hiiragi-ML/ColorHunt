import Foundation
import SwiftData

@Model
final class HuntPhoto{
    @Attribute(.unique) var id: UUID
    var colorID: String
    var fileName: String
    var createdAt: Date
    
    init(
        colorID: String,
        fileName: String,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.colorID = colorID
        self.fileName = fileName
        self.createdAt = createdAt
    }
}
