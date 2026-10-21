import SwiftUI

/// The four top-level destinations from the plan's UI baseline (section 2.3):
/// 首页、记录、趋势、设置.
///
/// The centre "＋" stays a toolbar action, not a tab. It is not added yet: step 07
/// introduces the record-type picker, and the plan forbids buttons that are visible
/// but do nothing.
struct RootTabView: View {
    let environment: AppEnvironment

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(environment: environment)
            }
            .tabItem { Label("首页", systemImage: "house") }

            NavigationStack {
                HistoryView(environment: environment)
            }
            .tabItem { Label("记录", systemImage: "list.bullet") }

            NavigationStack {
                TrendsPlaceholderView()
            }
            .tabItem { Label("趋势", systemImage: "chart.line.uptrend.xyaxis") }

            NavigationStack {
                SettingsView(environment: environment)
            }
            .tabItem { Label("设置", systemImage: "gearshape") }
        }
    }
}
