import Foundation

/// The fixed synthetic datasets of the prototype plan (section 2.4).
///
/// Every instant is an offset from one fixed capture instant, so the same dataset always
/// renders the same relative times (plan test 01-05: "数据和时间可重复").
///
/// `Tests/Fixtures/F0.json` and `F1.json` are the same data in the wire shape of
/// `DemoDataset`. A unit test decodes them and checks the shared invariants, so the
/// checked-in fixtures stay usable for the step 02 contract work.
enum DemoFixtures {
    /// 2026-10-16T01:00:00Z — a Friday morning in Asia/Shanghai.
    static let captureEpoch: TimeInterval = 1_792_112_400

    static let timeZoneIdentifier = "Asia/Shanghai"

    /// F0 and F1 share the same capture instant, so demo time is the same in both.
    static func captureInstant(for id: DemoDatasetID) -> Date {
        Date(timeIntervalSince1970: captureEpoch)
    }

    static func dataset(for id: DemoDatasetID) -> DemoDataset {
        switch id {
        case .f0: return empty
        case .f1: return seeded
        }
    }

    /// F0: empty baby profile, no records.
    static let empty = DemoDataset(
        id: .f0,
        capturedAt: Date(timeIntervalSince1970: captureEpoch),
        timeZoneIdentifier: timeZoneIdentifier,
        profile: nil,
        settings: DemoSettings(volumeUnit: .millilitre, caregiverName: "演示照护者"),
        recentEntries: []
    )

    /// F1: one fixed record per activity family, newest first.
    static let seeded = DemoDataset(
        id: .f1,
        capturedAt: Date(timeIntervalSince1970: captureEpoch),
        timeZoneIdentifier: timeZoneIdentifier,
        profile: DemoProfile(
            name: "演示宝宝",
            dateOfBirth: Date(timeIntervalSince1970: 1_776_646_800)
        ),
        settings: DemoSettings(volumeUnit: .millilitre, caregiverName: "演示照护者"),
        recentEntries: [
            DemoEntry(
                id: "f1-diaper-1",
                kind: .diaper,
                occurredAt: offset(minutes: 35),
                title: "尿布 · 湿",
                detail: "未记录颜色与质地"
            ),
            DemoEntry(
                id: "f1-bottle-1",
                kind: .bottle,
                occurredAt: offset(minutes: 125),
                title: "奶瓶 · 配方奶 120 ml",
                detail: "来源：配方奶"
            ),
            DemoEntry(
                id: "f1-breastfeeding-1",
                kind: .breastfeeding,
                occurredAt: offset(minutes: 250),
                title: "母乳 · 左侧 12 分钟",
                detail: "左 12 分钟 / 右 0 分钟"
            ),
            DemoEntry(
                id: "f1-sleep-1",
                kind: .sleep,
                occurredAt: offset(minutes: 420),
                title: "睡眠 · 1 小时 20 分钟",
                detail: "夜睡"
            ),
            DemoEntry(
                id: "f1-pump-1",
                kind: .pump,
                occurredAt: offset(minutes: 540),
                title: "吸奶 · 总量 160 ml",
                detail: "左 90 ml / 右 70 ml"
            ),
            DemoEntry(
                id: "f1-solids-1",
                kind: .solids,
                occurredAt: offset(minutes: 660),
                title: "辅食 · 米糊",
                detail: "餐次：早餐"
            ),
            DemoEntry(
                id: "f1-growth-1",
                kind: .growth,
                occurredAt: offset(minutes: 4_320),
                title: "成长 · 体重 6.42 kg",
                detail: "身长 62.0 cm"
            ),
            DemoEntry(
                id: "f1-health-1",
                kind: .health,
                occurredAt: offset(minutes: 8_640),
                title: "健康 · 疫苗接种",
                detail: "记录在案"
            ),
        ]
    )

    private static func offset(minutes: Int) -> Date {
        Date(timeIntervalSince1970: captureEpoch - Double(minutes) * 60)
    }
}
