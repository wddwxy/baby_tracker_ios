import SwiftUI

/// One row in the home and history lists.
///
/// Provisional: step 02 defines the real `EntryRow` against the API DTOs. This version
/// renders a demo entry with a relative time, a clock time and a semantic icon, and it
/// exposes an accessibility identifier so UI tests can count and locate rows without
/// depending on localized copy.
struct EntryRow: View {
    let entry: DemoEntry
    let now: Date
    let timeZone: TimeZone
    let identifier: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.kind.symbolName)
                .frame(width: 26)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                Text(entry.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(ElapsedFormatter.shortLabel(from: entry.occurredAt, to: now))
                Text(FixedStampFormatter.clockLabel(entry.occurredAt, timeZone: timeZone))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}
