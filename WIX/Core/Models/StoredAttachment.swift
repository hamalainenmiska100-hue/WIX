import Foundation

struct StoredAttachment: Identifiable, Codable, Hashable {
    enum Kind: String, Codable {
        case image
        case document
    }

    let id: UUID
    let fileName: String
    let mimeType: String
    let localPath: String
    let kind: Kind
    let fileSizeBytes: Int64
    let createdAt: Date

    init(
        id: UUID = UUID(),
        fileName: String,
        mimeType: String,
        localPath: String,
        kind: Kind,
        fileSizeBytes: Int64,
        createdAt: Date = .now
    ) {
        self.id = id
        self.fileName = fileName
        self.mimeType = mimeType
        self.localPath = localPath
        self.kind = kind
        self.fileSizeBytes = fileSizeBytes
        self.createdAt = createdAt
    }

    var fileURL: URL {
        URL(fileURLWithPath: localPath)
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
    }
}
