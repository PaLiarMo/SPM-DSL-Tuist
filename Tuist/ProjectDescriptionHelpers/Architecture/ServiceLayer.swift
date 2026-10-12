/// The Api/Impl split, and the single source of truth for its graph:
///
///     Impl → Api, Core
///
/// `Api` carries only protocols/contracts (zero dependencies by default — anything a feature
/// is allowed to depend on, see `ModuleDependency.serviceAPI`). `Impl` is a composition root:
/// it is the one place allowed to wire concrete feature screens together (see
/// `CompositionDependency`), and only the app target or another composition root may depend
/// on it.
public enum ServiceLayer: String, CaseIterable, Sendable {
    case api
    case impl

    var suffix: String {
        switch self {
        case .api: return "Api"
        case .impl: return "Impl"
        }
    }

    var baseDependencies: [CompositionDependency] {
        switch self {
        case .api: return []
        case .impl: return [.module(.Core)]
        }
    }

    var internalDependencies: [ServiceLayer] {
        switch self {
        case .api: return []
        case .impl: return [.api]
        }
    }
}
