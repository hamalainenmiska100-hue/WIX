import Foundation
import UniformTypeIdentifiers

struct MimeType {
    static func from(fileURL: URL) -> String {
        if let type = UTType(filenameExtension: fileURL.pathExtension.lowercased()),
           let preferred = type.preferredMIMEType {
            return preferred
        }
        return "application/octet-stream"
    }

    static func attachmentKind(for mimeType: String) -> StoredAttachment.Kind {
        mimeType.hasPrefix("image/") ? .image : .document
    }
}
