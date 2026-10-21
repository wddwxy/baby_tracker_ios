import Foundation
import UIKit

/// Build and device information for the settings and diagnostics screens.
///
/// Nothing here is secret. Tokens, cookies and Ingress session URLs must never be shown
/// or logged (plan step 03: "UI 不显示 Ingress session URL、token 或 cookie").
enum AppInfo {
    static var version: String { bundleString("CFBundleShortVersionString") ?? "0.0.0" }
    static var build: String { bundleString("CFBundleVersion") ?? "0" }
    static var versionDescription: String { "\(version) (\(build))" }

    static var bundleIdentifier: String { Bundle.main.bundleIdentifier ?? "unknown" }

    /// The deployment target baked into the built product.
    static var minimumOSVersion: String { bundleString("MinimumOSVersion") ?? "unknown" }

    static var operatingSystemDescription: String {
        "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    }

    static var deviceModel: String { UIDevice.current.model }

    private static func bundleString(_ key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}
