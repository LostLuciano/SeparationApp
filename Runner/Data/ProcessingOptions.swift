import Foundation

public struct StemProcessingOptions: Codable, Hashable, Sendable {
    public let templateName: String
    public let selectedStems: [String]

    public init(templateName: String, selectedStems: [String]) {
        self.templateName = templateName
        self.selectedStems = selectedStems
    }

    public static let allStems = StemProcessingOptions(
        templateName: "Full Band",
        selectedStems: ["vocals", "drums", "bass", "guitar", "piano", "other"]
    )

    public static let voice = StemProcessingOptions(
        templateName: "Suara",
        selectedStems: ["vocals", "other"]
    )

    public static let classic = StemProcessingOptions(
        templateName: "Klasik",
        selectedStems: ["vocals", "bass", "drums", "other"]
    )

    public static let guitar = StemProcessingOptions(
        templateName: "Gitar",
        selectedStems: ["vocals", "guitar", "bass", "drums", "other"]
    )

    public static let piano = StemProcessingOptions(
        templateName: "Piano",
        selectedStems: ["vocals", "piano", "bass", "drums", "other"]
    )

    public static let splits = StemProcessingOptions(
        templateName: "Splits",
        selectedStems: ["vocals", "drums", "bass", "guitar", "piano", "other"]
    )

    public static let templates: [StemProcessingOptions] = [
        .voice,
        .classic,
        .guitar,
        .piano,
        .splits,
        .allStems,
        StemProcessingOptions(
            templateName: "Vocal + Rhythm",
            selectedStems: ["vocals", "bass", "drums", "guitar"]
        ),
        StemProcessingOptions(
            templateName: "Guitar Practice",
            selectedStems: ["vocals", "bass", "drums", "piano", "other"]
        ),
        StemProcessingOptions(
            templateName: "Guitar Only",
            selectedStems: ["guitar"]
        ),
        StemProcessingOptions(
            templateName: "Vocals Only",
            selectedStems: ["vocals"]
        ),
        StemProcessingOptions(
            templateName: "Piano / Keys",
            selectedStems: ["piano"]
        ),
        StemProcessingOptions(
            templateName: "Rhythm Section",
            selectedStems: ["drums", "bass"]
        )
    ]

    public var displaySummary: String {
        selectedStems.map { stem in
            stem == "piano" ? "keys" : stem
        }
        .joined(separator: ", ")
        .capitalized
    }
}

public enum AudioExportQuality: String, CaseIterable, Codable, Hashable, Sendable {
    case draft = "Draft"
    case standard = "Standard"
    case high = "High Quality"
    case lossless = "Lossless"

    public var fileExtension: String {
        switch self {
        case .lossless:
            return "wav"
        default:
            return "m4a"
        }
    }

    public var bitRatePerChannel: Int {
        switch self {
        case .draft:
            return 64_000
        case .standard:
            return 96_000
        case .high:
            return 160_000
        case .lossless:
            return 0
        }
    }
}
