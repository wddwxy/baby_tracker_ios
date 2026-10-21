import SwiftUI

/// Trends tab placeholder.
///
/// The plan forbids showing invented charts, so step 01 states the real status instead
/// (step 13: "趋势未实现时不展示虚构图表"). Growth and trend rendering is step 18.
struct TrendsPlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Label("趋势尚未实现", systemImage: "chart.line.uptrend.xyaxis")
        } description: {
            Text("趋势页在步骤 18 接入服务端的统计结果。这里不会显示虚构图表或估算数值。")
        }
        .navigationTitle("趋势")
        .accessibilityIdentifier(AccessibilityID.trendsRoot)
    }
}
