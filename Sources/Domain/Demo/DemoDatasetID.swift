import Foundation

/// Fixed synthetic datasets from the prototype plan (section 2.4).
///
/// Step 01 ships F0 and F1 only:
///
/// - F0: empty baby profile, no records at all.
/// - F1: one fixed record per activity family, at fixed instants.
///
/// F2 (a running breastfeeding session) arrives with steps 04/08, and F3-F6 arrive with
/// the steps that consume them. See `Tests/Fixtures/README.md`.
enum DemoDatasetID: String, Codable, CaseIterable, Equatable, Sendable {
    case f0
    case f1

    var displayName: String {
        switch self {
        case .f0: return "F0 空数据"
        case .f1: return "F1 固定记录"
        }
    }
}
