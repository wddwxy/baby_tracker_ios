import Foundation

/// Provisional preview models for demo mode.
///
/// These types exist to render the step 01 shell with repeatable data. They are **not**
/// the API DTOs of step 02: nothing here is sent to, or derived from, the Home Assistant
/// service, and step 02 replaces the transport layer without reshaping these fixtures.

/// Volume unit used when formatting quantities.
///
/// Only the display unit lives here. Stored values keep the server's canonical unit
/// (plan step 07: "只在展示层做单位转换").
enum VolumeUnit: String, Codable, CaseIterable, Sendable {
    case millilitre
    case fluidOunce

    var displayName: String {
        switch self {
        case .millilitre: return "毫升"
        case .fluidOunce: return "液量盎司"
        }
    }
}

/// Baby profile as shown on the home screen.
struct DemoProfile: Codable, Equatable, Sendable {
    var name: String
    var dateOfBirth: Date
}

/// Family settings that affect display.
struct DemoSettings: Codable, Equatable, Sendable {
    var volumeUnit: VolumeUnit
    var caregiverName: String
}

/// Activity families used by the demo list and row icons.
///
/// Icons are provisional placeholders; the semantic icon set is settled with each
/// record editor in steps 07 and 15-17.
enum DemoEntryKind: String, Codable, CaseIterable, Sendable {
    case bottle
    case breastfeeding
    case diaper
    case sleep
    case pump
    case solids
    case growth
    case health

    var displayName: String {
        switch self {
        case .bottle: return "奶瓶"
        case .breastfeeding: return "哺乳"
        case .diaper: return "尿布"
        case .sleep: return "睡眠"
        case .pump: return "吸奶"
        case .solids: return "辅食"
        case .growth: return "成长"
        case .health: return "健康"
        }
    }

    var symbolName: String {
        switch self {
        case .bottle: return "cup.and.saucer.fill"
        case .breastfeeding: return "heart.circle.fill"
        case .diaper: return "leaf.fill"
        case .sleep: return "moon.zzz.fill"
        case .pump: return "drop.fill"
        case .solids: return "fork.knife"
        case .growth: return "chart.line.uptrend.xyaxis"
        case .health: return "cross.case.fill"
        }
    }
}

/// One synthetic entry in a demo dataset.
struct DemoEntry: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var kind: DemoEntryKind
    var occurredAt: Date
    var title: String
    var detail: String
}

/// A complete synthetic dataset for one demo launch.
struct DemoDataset: Codable, Equatable, Sendable {
    var id: DemoDatasetID
    /// The fixed "now" for this dataset.
    var capturedAt: Date
    var timeZoneIdentifier: String
    var profile: DemoProfile?
    var settings: DemoSettings
    var recentEntries: [DemoEntry]
}

extension DemoDataset {
    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .gmt
    }
}
