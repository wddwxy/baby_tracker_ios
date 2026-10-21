import Foundation

/// Injection point for synthetic data.
///
/// Keeping this behind a protocol means the demo datasets can be swapped or removed in a
/// test without touching the app assembly (plan step 01: "提供测试运行配置和合成数据注入入口").
protocol DemoDataProviding: Sendable {
    func dataset(_ id: DemoDatasetID) -> DemoDataset
}

/// Default provider: the fixed datasets in `DemoFixtures`.
struct DemoDataProvider: DemoDataProviding {
    func dataset(_ id: DemoDatasetID) -> DemoDataset {
        DemoFixtures.dataset(for: id)
    }
}
