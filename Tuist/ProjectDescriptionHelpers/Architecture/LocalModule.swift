import ProjectDescription

/// Every base (non-feature) module of the app. Adding a case here is the only place a new
/// base module's *identity* is declared — its target name is derived, never typed by hand.
public enum LocalModule: String, CaseIterable, Sendable {
    case Core
    case UI
    case DI
    case Resources
    case Networking

    var targetName: String { rawValue }
}
