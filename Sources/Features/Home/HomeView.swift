import SwiftUI

/// Home tab.
///
/// Step 01 renders the shell: demo data when a demo dataset is active, and an honest
/// "not connected" state otherwise. The bounded `/api/bootstrap` + `/api/running` home
/// screen, including the running-session card, is step 04.
struct HomeView: View {
    let environment: AppEnvironment

    var body: some View {
        Group {
            if let dataset = environment.demoDataset {
                DemoHomeContent(dataset: dataset, timeSource: environment.timeSource)
            } else {
                UnconnectedHomeView(connection: environment.connection)
            }
        }
        .navigationTitle("首页")
        .accessibilityIdentifier(AccessibilityID.homeRoot)
    }
}

private struct DemoHomeContent: View {
    let dataset: DemoDataset
    let timeSource: TimeSource

    var body: some View {
        List {
            Section {
                if let profile = dataset.profile {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.name)
                            .font(.title3.weight(.semibold))
                        Text("出生 \(FixedStampFormatter.label(profile.dateOfBirth, timeZone: dataset.timeZone)) · 已 \(ElapsedFormatter.dayCountLabel(from: profile.dateOfBirth, to: timeSource.now))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityIdentifier(AccessibilityID.homeProfileCard)
                } else {
                    Text("这个数据集没有宝宝资料。")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier(AccessibilityID.homeEmptyProfile)
                }
            } header: {
                Text("宝宝")
            }

            Section {
                if dataset.recentEntries.isEmpty {
                    Text("这个数据集没有记录。")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier(AccessibilityID.homeEmptyEntries)
                } else {
                    ForEach(dataset.recentEntries) { entry in
                        EntryRow(
                            entry: entry,
                            now: timeSource.now,
                            timeZone: dataset.timeZone,
                            identifier: AccessibilityID.homeEntryRow(entry.id)
                        )
                    }
                }
            } header: {
                Text("最近记录")
            }

            Section {
                Text("运行中记录、快速记录与完整首页在步骤 04 实现。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct UnconnectedHomeView: View {
    let connection: ConnectionController

    var body: some View {
        ContentUnavailableView {
            Label("尚未连接 Home Assistant", systemImage: "bolt.horizontal.circle")
        } description: {
            Text("步骤 01 只包含界面骨架。读取真实记录需要先完成步骤 03 的连接流程，这里不会显示虚构数据。")
        } actions: {
            NavigationLink("打开连接设置") {
                ConnectionSetupView(connection: connection)
            }
            .accessibilityIdentifier(AccessibilityID.homeOpenConnection)
        }
        .accessibilityIdentifier(AccessibilityID.homeUnconnected)
    }
}
