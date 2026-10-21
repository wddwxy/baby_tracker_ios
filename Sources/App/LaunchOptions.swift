import Foundation

/// Parsed launch configuration.
///
/// Values are read from the argument domain of `UserDefaults`, so both command-line
/// style launch arguments and environment variables work:
///
///     -LittleNestMode live
///     -LittleNestDemoDataset F1
///     -LittleNestFixedNow 2026-10-16T01:00:00Z
///     -LittleNestDiagnostics YES
///
///     LITTLENEST_MODE=demo LITTLENEST_DEMO_DATASET=f1
///
/// The UI tests use the argument form; CI and manual runs can use either.
struct LaunchOptions: Equatable {
    var mode: AppMode
    var fixedNow: Date?
    var showsDiagnostics: Bool

    static let modeKey = "LittleNestMode"
    static let demoDatasetKey = "LittleNestDemoDataset"
    static let fixedNowKey = "LittleNestFixedNow"
    static let diagnosticsKey = "LittleNestDiagnostics"

    /// Defaults to live mode: demo data must always be requested explicitly.
    static let `default` = LaunchOptions(mode: .live, fixedNow: nil, showsDiagnostics: false)

    static func parse(defaults: UserDefaults, environment: [String: String]) -> LaunchOptions {
        let rawMode = normalized(value(defaults, environment, modeKey, "LITTLENEST_MODE"))
        let rawDataset = normalized(value(defaults, environment, demoDatasetKey, "LITTLENEST_DEMO_DATASET"))
        let rawNow = value(defaults, environment, fixedNowKey, "LITTLENEST_FIXED_NOW")

        let diagnostics = defaults.bool(forKey: diagnosticsKey)
            || environment["LITTLENEST_DIAGNOSTICS"] == "1"

        let dataset = rawDataset.flatMap(DemoDatasetID.init(rawValue:))

        let mode: AppMode
        switch rawMode {
        case "live":
            mode = .live
        case "demo":
            mode = .demo(dataset ?? .f1)
        case .none:
            // Naming a dataset is enough to select demo mode.
            mode = dataset.map(AppMode.demo) ?? .live
        default:
            // An unknown mode never silently becomes demo data.
            mode = .live
        }

        return LaunchOptions(
            mode: mode,
            fixedNow: rawNow.flatMap(instant(from:)),
            showsDiagnostics: diagnostics
        )
    }

    static var current: LaunchOptions {
        parse(defaults: .standard, environment: ProcessInfo.processInfo.environment)
    }

    /// Parses an ISO 8601 instant such as `2026-10-16T01:00:00Z`.
    static func instant(from raw: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: raw)
    }

    private static func value(
        _ defaults: UserDefaults,
        _ environment: [String: String],
        _ defaultsKey: String,
        _ environmentKey: String
    ) -> String? {
        if let argument = defaults.string(forKey: defaultsKey), !argument.isEmpty {
            return argument
        }
        if let variable = environment[environmentKey], !variable.isEmpty {
            return variable
        }
        return nil
    }

    private static func normalized(_ raw: String?) -> String? {
        raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
