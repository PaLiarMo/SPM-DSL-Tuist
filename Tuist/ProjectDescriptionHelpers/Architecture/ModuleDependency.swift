import ProjectDescription

/// Type-safe replacement for magic-string target/product dependencies.
///
/// Deliberately has no `.feature` case: a `Module` or a `Feature` layer can only depend on a
/// `LocalModule`, a `RemotePackage`, or a service's public `Api` — never directly on another
/// feature, and never on a service's `Impl`. That makes "Feature A → Feature B", "Core →
/// Feature" and "Feature → Service.Impl" unrepresentable by construction, not just something
/// a linter has to catch after the fact. Composition roots (a service's `Impl`, the app
/// target) use the broader `CompositionDependency` instead.
public enum ModuleDependency: Sendable {
    case module(LocalModule)
    case remote(RemotePackage)
    case serviceAPI(ServiceID)
}

extension ModuleDependency {
    var asTargetDependency: TargetDependency {
        switch self {
        case .module(let module):
            return .target(name: module.targetName)
        case .remote(let package):
            return .external(name: package.spec.productName)
        case .serviceAPI(let service):
            return .target(name: service.targetName(for: .api))
        }
    }

    /// Name of the local target this edge points to, `nil` for remote packages.
    var localTargetName: String? {
        switch self {
        case .module(let target): return target.targetName
        case .remote: return nil
        case .serviceAPI(let service): return service.targetName(for: .api)
        }
    }
}
