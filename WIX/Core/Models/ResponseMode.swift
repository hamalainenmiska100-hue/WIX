import Foundation

enum ResponseMode: String, Codable, CaseIterable, Identifiable {
    case instant
    case analyze

    var id: String { rawValue }

    var title: String {
        switch self {
        case .instant:
            return "Instant"
        case .analyze:
            return "Analyze"
        }
    }

    var symbolName: String {
        switch self {
        case .instant:
            return "sparkles"
        case .analyze:
            return "doc.text.magnifyingglass"
        }
    }

    var temperature: Double {
        switch self {
        case .instant:
            return 0.7
        case .analyze:
            return 0.35
        }
    }

    var maxOutputTokens: Int {
        switch self {
        case .instant:
            return 2048
        case .analyze:
            return 3072
        }
    }

    var helperText: String {
        switch self {
        case .instant:
            return "Nopea yleisvastaus"
        case .analyze:
            return "Tarkempi, rakenteinen vastaus"
        }
    }
}
