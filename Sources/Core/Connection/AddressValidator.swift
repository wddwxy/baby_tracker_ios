import Foundation

/// Pure address validation.
///
/// Kept separate from the controller so it can be unit tested offline, with no Home
/// Assistant instance and no credentials (plan test 01-04).
enum AddressValidator {
    /// Returns the problem with `rawAddress`, or `nil` when it is usable.
    ///
    /// Only `http` and `https` are accepted. Credentials embedded in the address are
    /// rejected: the OAuth flow owns authentication, and the address must never carry
    /// secrets into logs or recovery files (plan step 03).
    static func problem(with rawAddress: String) -> ConnectionProblem? {
        let trimmed = rawAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .emptyAddress }

        guard let components = URLComponents(string: trimmed) else { return .malformedAddress }

        let scheme = components.scheme?.lowercased()
        guard scheme == "http" || scheme == "https" else { return .malformedAddress }

        guard let host = components.host, !host.isEmpty else { return .malformedAddress }

        guard components.user == nil, components.password == nil else { return .malformedAddress }

        return nil
    }
}
