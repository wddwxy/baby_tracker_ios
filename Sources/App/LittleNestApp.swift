import SwiftUI

/// App entry point for the Little Nest native prototype.
///
/// Step 01 builds the shell only: a four-tab root view, a fixed synthetic dataset for
/// demo mode and an honest "not connected yet" connection skeleton. Auth, API, sync and
/// Live Activity layers arrive in steps 02-12.
@main
struct LittleNestApp: App {
    @State private var environment = AppEnvironment.launch()

    var body: some Scene {
        WindowGroup {
            AppRootView(environment: environment)
        }
    }
}
