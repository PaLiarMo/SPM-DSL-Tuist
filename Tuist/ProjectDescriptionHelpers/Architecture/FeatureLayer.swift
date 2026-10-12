import ProjectDescription

/// The layered feature architecture, and the single source of truth for its graph:
///
///     Presentation → Domain
///     Domain       → Data     (direct direction, matching the ported MainScreen/DetailScreen
///                               code: Domain imports the concrete repository from Data —
///                               not the inverted "Data implements Domain's protocol"
///                               direction some Clean Architecture variants use)
///     Domain       → Core
///     Data         → Core, Networking
///     Presentation → Core, UI, Resources
///
/// No feature re-declares these edges; `TargetFactory` reads them from here for every
/// feature, so "Presentation depends on Domain" exists exactly once in the whole project.
public enum FeatureLayer: String, CaseIterable, Sendable {
    case presentation
    case domain
    case data

    var suffix: String {
        switch self {
        case .presentation: return "Presentation"
        case .domain: return "Domain"
        case .data: return "Data"
        }
    }

    /// Local modules every target in this layer depends on, regardless of which feature it
    /// belongs to.
    var baseDependencies: [ModuleDependency] {
        switch self {
        case .presentation: return [.module(.UI), .module(.Resources), .module(.Core)]
        case .domain: return [.module(.Core)]
        case .data: return [.module(.Core), .module(.Networking)]
        }
    }

    /// Dependencies on other layers of the *same* feature.
    var internalDependencies: [FeatureLayer] {
        switch self {
        case .presentation: return [.domain]
        case .domain: return [.data]
        case .data: return []
        }
    }
}
