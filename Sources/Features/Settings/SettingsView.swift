import SwiftUI

/// Settings tab.
///
/// Step 01 shows the current mode, the connection entry point and build information.
/// The full settings groups (baby profile, units, reminders, lock screen, data
/// management) are step 20.
struct SettingsView: View {
    let environment: AppEnvironment

    var body: some View {
        Form {
            Section {
                LabeledContent("模式", value: environment.mode.displayName)
                    .accessibilityIdentifier(AccessibilityID.settingsModeRow)

                if let dataset = environment.demoDataset {
                    LabeledContent("数据集", value: dataset.id.displayName)
                    LabeledContent(
                        "固定时间",
                        value: "\(FixedStampFormatter.label(dataset.capturedAt, timeZone: dataset.timeZone))（\(dataset.timeZoneIdentifier)）"
                    )
                    Text("演示模式不会连接 Home Assistant，也不会写入任何记录。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("真实数据模式。步骤 01 尚未实现连接，因此不会显示任何记录。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("当前模式")
            }

            Section {
                LabeledContent(
                    "地址",
                    value: environment.connection.address.isEmpty ? "未填写" : environment.connection.address
                )
                NavigationLink("连接 Home Assistant") {
                    ConnectionSetupView(connection: environment.connection)
                }
                .accessibilityIdentifier(AccessibilityID.settingsOpenConnection)

                Button("退出并清除本地状态", role: .destructive) {
                    environment.connection.signOut()
                }
            } header: {
                Text("连接")
            }

            if environment.showsDiagnostics {
                Section {
                    NavigationLink("诊断信息") {
                        DiagnosticsView(environment: environment)
                    }
                    .accessibilityIdentifier(AccessibilityID.settingsOpenDiagnostics)
                } header: {
                    Text("开发诊断")
                }
            }

            Section {
                LabeledContent("App 版本", value: AppInfo.versionDescription)
                LabeledContent("最低系统版本", value: AppInfo.minimumOSVersion)
            } header: {
                Text("关于")
            }
        }
        .navigationTitle("设置")
        .accessibilityIdentifier(AccessibilityID.settingsRoot)
    }
}
