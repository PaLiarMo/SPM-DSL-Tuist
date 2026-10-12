/// Every feature of the app. Adding a case here (plus one `Feature(...)` line in
/// `Project.swift`) is the entire cost of a new feature — see the "adding a feature" scenario
/// in the migration write-up.
public enum FeatureID: String, CaseIterable, Sendable {
    case MainScreen
    case DetailScreen
}

extension FeatureID {
    func targetName(for layer: FeatureLayer) -> String {
        "\(rawValue)_\(layer.suffix)"
    }
}
