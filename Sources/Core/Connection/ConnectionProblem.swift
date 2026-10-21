import Foundation

/// User-facing connection failures.
///
/// The categories are kept apart on purpose (plan section 2.2 and step 03): an
/// unreachable address, a stopped service, a missing login and an incompatible version
/// must not all read as "wrong password", and a proxy returning HTML must not be decoded
/// as a successful DTO.
enum ConnectionProblem: Equatable, Sendable {
    /// The address field is empty.
    case emptyAddress
    /// The address is not a usable http(s) URL.
    case malformedAddress
    /// The address is valid, but the connection flow is not part of this build yet.
    case notAvailableInThisBuild
    /// The host could not be reached (step 03).
    case unreachable
    /// The host answered but the Little Nest app is not running (step 03).
    case serviceNotStarted
    /// The user needs to sign in again (step 03).
    case loginRequired
    /// The instance is reachable but its interface version is not supported (step 02).
    case incompatibleVersion

    var title: String {
        switch self {
        case .emptyAddress: return "请输入 Home Assistant 地址"
        case .malformedAddress: return "地址无法识别"
        case .notAvailableInThisBuild: return "连接功能尚未实现"
        case .unreachable: return "无法连接到该地址"
        case .serviceNotStarted: return "Baby Tracker 未运行"
        case .loginRequired: return "需要重新登录"
        case .incompatibleVersion: return "版本不兼容"
        }
    }

    var message: String {
        switch self {
        case .emptyAddress:
            return "地址形如 http://homeassistant.local:8123。"
        case .malformedAddress:
            return "请填写完整的 http 或 https 地址，且不要在地址里包含用户名和密码。"
        case .notAvailableInThisBuild:
            return "本原型版本只包含界面骨架，HA 登录与 Ingress 会话将在步骤 03 实现。"
        case .unreachable:
            return "请确认手机与 Home Assistant 在同一网络，并检查地址是否正确。"
        case .serviceNotStarted:
            return "Home Assistant 可以访问，但 Little Nest 应用没有启动。"
        case .loginRequired:
            return "登录状态已失效，请重新连接 Home Assistant。"
        case .incompatibleVersion:
            return "该实例的接口版本暂不支持，请先更新 Little Nest 应用。"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notAvailableInThisBuild:
            return "可以先使用演示模式查看固定数据，演示模式不会连接 Home Assistant。"
        case .malformedAddress, .emptyAddress:
            return nil
        case .unreachable, .serviceNotStarted, .loginRequired, .incompatibleVersion:
            return "步骤 03 会在这里给出可重试的恢复路径。"
        }
    }
}
