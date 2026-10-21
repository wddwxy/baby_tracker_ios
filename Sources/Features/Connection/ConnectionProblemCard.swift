import SwiftUI

/// The connection failure card.
///
/// Categories are shown separately so an unreachable host, a stopped service, a missing
/// login and an incompatible version do not all read as one generic error (plan step 03).
struct ConnectionProblemCard: View {
    let problem: ConnectionProblem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(problem.title, systemImage: "exclamationmark.triangle")
                .font(.headline)
            Text(problem.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let suggestion = problem.recoverySuggestion {
                Text(suggestion)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
