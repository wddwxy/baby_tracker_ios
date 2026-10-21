import SwiftUI

/// History tab.
///
/// Step 01 renders demo entries grouped by day. The real `/api/entries` list with cursor
/// pagination, filters and the read-only detail view is step 05.
struct HistoryView: View {
    let environment: AppEnvironment

    var body: some View {
        Group {
            if let dataset = environment.demoDataset {
                DemoHistoryContent(dataset: dataset)
            } else {
                ContentUnavailableView {
                    Label("尚未连接 Home Assistant", systemImage: "list.bullet.rectangle")
                } description: {
                    Text("记录列表来自 Home Assistant 里的 Little Nest 数据，需要先完成步骤 03 的连接流程。")
                } actions: {
                    NavigationLink("打开连接设置") {
                        ConnectionSetupView(connection: environment.connection)
                    }
                }
                .accessibilityIdentifier(AccessibilityID.historyUnconnected)
            }
        }
        .navigationTitle("记录")
        .accessibilityIdentifier(AccessibilityID.historyRoot)
    }
}

private struct DemoHistoryContent: View {
    let dataset: DemoDataset

    var body: some View {
        List {
            ForEach(EntryGrouping.byDay(dataset.recentEntries, timeZone: dataset.timeZone)) { group in
                Section {
                    ForEach(group.entries) { entry in
                        EntryRow(
                            entry: entry,
                            now: dataset.capturedAt,
                            timeZone: dataset.timeZone,
                            identifier: AccessibilityID.historyEntryRow(entry.id)
                        )
                    }
                } header: {
                    Text(group.day)
                }
            }

            Section {
                Text("分页、筛选与只读详情在步骤 05 实现。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
