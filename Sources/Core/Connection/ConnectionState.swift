import Foundation

/// Connection lifecycle for one Home Assistant instance.
///
/// Step 01 defines the shape and the user-facing copy only. The transitions that actually
/// talk to Home Assistant arrive in step 03 (`validatingAddress` through `connected`).
enum ConnectionState: Equatable, Sendable {
    /// No address has been entered yet.
    case notConfigured
    /// The address is being checked before any network call.
    case validatingAddress
    /// HA OAuth is in progress (step 03).
    case authenticating
    /// An Ingress session is being created (step 03).
    case creatingSession
    /// The baby profile is being read (step 04).
    case loadingProfile
    /// A session exists and the identity was verified.
    case connected(userName: String)
    /// Something needs the user's attention.
    case failed(ConnectionProblem)
}

extension ConnectionState {
    /// Progress label shown while the connection is being established.
    ///
    /// The plan requires distinct progress text rather than an indefinite spinner
    /// (step 03: "正在登录 / 正在连接 Baby Tracker / 正在读取资料").
    var progressDescription: String? {
        switch self {
        case .notConfigured, .connected, .failed:
            return nil
        case .validatingAddress:
            return "正在检查地址"
        case .authenticating:
            return "正在登录 Home Assistant"
        case .creatingSession:
            return "正在连接 Baby Tracker"
        case .loadingProfile:
            return "正在读取资料"
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var problem: ConnectionProblem? {
        if case let .failed(problem) = self { return problem }
        return nil
    }
}
