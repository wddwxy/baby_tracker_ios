import Foundation
import Observation

/// Owns the connection address and lifecycle.
///
/// Step 01 deliberately performs **no** network call. `connect()` validates the address
/// locally and then reports `notAvailableInThisBuild`, which keeps the shell honest: a
/// demo launch can never look connected, and the UI tests have something deterministic
/// to assert (plan test 01-05).
///
/// Step 03 replaces the body of `connect()` with the real chain:
/// HA OAuth -> HA WebSocket auth -> `supervisor/api` Ingress session -> identity check.
@MainActor
@Observable
final class ConnectionController {
    private(set) var state: ConnectionState = .notConfigured

    /// The Home Assistant address as typed by the user.
    ///
    /// Editing the address always returns the form to a clean, retryable state so a
    /// stale failure card never describes the new address.
    var address: String = "" {
        didSet {
            guard address != oldValue else { return }
            if state != .notConfigured { state = .notConfigured }
        }
    }

    /// Validates the current address without touching the network.
    func validateAddress() -> ConnectionProblem? {
        AddressValidator.problem(with: address)
    }

    /// Starts the connection flow.
    ///
    /// Step 01 stops at the first honest barrier instead of pretending to succeed.
    func connect() {
        if let problem = AddressValidator.problem(with: address) {
            state = .failed(problem)
            return
        }
        state = .failed(.notAvailableInThisBuild)
    }

    /// Clears the local connection state.
    ///
    /// Step 03 extends this to Keychain tokens, the Ingress cookie and cached user data.
    func signOut() {
        address = ""
        state = .notConfigured
    }
}
