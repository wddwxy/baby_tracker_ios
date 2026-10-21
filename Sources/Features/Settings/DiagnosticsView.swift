import SwiftUI

/// Development diagnostics.
///
/// Real-device signing failures stay a developer concern and never enter the normal user
/// flow (plan step 01). This screen therefore shows only build and launch facts, and
/// never tokens, cookies or Ingress session URLs.
///
/// It is reachable only when the `-LittleNestDiagnostics YES` launch option is set.
struct DiagnosticsView: View {
    let environment: AppEnvironment

    var body: some View {
        Form {
            Section {
                LabeledContent("版本", value: AppInfo.versionDescription)
                LabeledContent("Bundle ID", value: AppInfo.bundleIdentifier)
                LabeledContent("最低系统版本", value: AppInfo.minimumOSVersion)
            } header: {
                Text("App")
            }

            Section {
                LabeledContent("模式", value: environment.mode.displayName)
                LabeledContent("时间源", value: environment.timeSource.kindDescription)
                LabeledContent(
                    "当前时间",
                    value: environment.timeSource.now.formatted(date: .abbreviated, time: .standard)
                )
            } header: {
                Text("启动")
            }

            Section {
                LabeledContent("系统", value: AppInfo.operatingSystemDescription)
                LabeledContent("设备", value: AppInfo.deviceModel)
            } header: {
                Text("设备")
            }

            Section {
                Text("真机签名失败属于开发诊断，不进入正式用户流程。此页面不显示 token、cookie 或 Ingress 会话地址。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("诊断")
        .accessibilityIdentifier(AccessibilityID.diagnosticsRoot)
    }
}
