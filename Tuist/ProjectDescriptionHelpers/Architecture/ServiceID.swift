/// Every cross-cutting service of the app — infrastructural/coordinating modules (navigation,
/// analytics, auth…) that use the Api/Impl split instead of the Presentation/Domain/Data
/// layering: `Router` is the first one, wiring features together for navigation.
public enum ServiceID: String, CaseIterable, Sendable {
    case Router
}

extension ServiceID {
    func targetName(for layer: ServiceLayer) -> String {
        "\(rawValue)_\(layer.suffix)"
    }
}
