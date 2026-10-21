import SwiftUI

/// The pinned "演示数据" banner.
///
/// It states the dataset and the frozen capture time, so a demo launch can never be
/// mistaken for a live Home Assistant connection (plan step 01 and test 01-05).
/// The stamp uses a locale-independent format so UI tests can assert on it.
struct DemoModeBanner: View {
    let dataset: DemoDataset

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: "testtube.2")
                Text("演示数据")
                    .font(.subheadline.weight(.semibold))
            }
            Text("\(dataset.id.displayName) · 固定时间 \(FixedStampFormatter.label(dataset.capturedAt, timeZone: dataset.timeZone))（\(dataset.timeZoneIdentifier)）")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier(AccessibilityID.demoBannerStamp)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.yellow.opacity(0.22))
    }
}
