import SwiftUI

/// Root of the app.
///
/// The demo banner is pinned above the tab shell so a synthetic launch is always
/// labelled, on every screen (plan step 01: "Demo 模式顶部固定标识").
struct AppRootView: View {
    let environment: AppEnvironment

    var body: some View {
        VStack(spacing: 0) {
            if let dataset = environment.demoDataset {
                DemoModeBanner(dataset: dataset)
                Divider()
            }
            RootTabView(environment: environment)
        }
    }
}

#Preview("Live") {
    AppRootView(environment: AppEnvironment(
        mode: .live,
        timeSource: SystemTimeSource(),
        connection: ConnectionController(),
        showsDiagnostics: true
    ))
}

#Preview("Demo F1") {
    AppRootView(environment: AppEnvironment(
        mode: .demo(.f1),
        timeSource: FixedTimeSource(instant: DemoFixtures.captureInstant(for: .f1)),
        connection: ConnectionController(),
        showsDiagnostics: true
    ))
}
