import ProjectDescription

/// Full-access dependency type for composition-root-level targets: a `Service`'s `impl` layer
/// and the app's own `AppTarget`. These are the only two places in the graph allowed to
/// reference a concrete feature layer or another service's layer directly — everywhere else
/// (`Module`, `Feature`) is restricted to `ModuleDependency`, which has no such cases.
public enum CompositionDependency: Sendable {
    case module(LocalModule)
    case remote(RemotePackage)
    case feature(FeatureID, FeatureLayer)
    case service(ServiceID, ServiceLayer)
}

extension CompositionDependency {
    var asTargetDependency: TargetDependency {
        switch self {
        case .module(let module):
            return .target(name: module.targetName)
        case .remote(let package):
            return .external(name: package.spec.productName)
        case .feature(let id, let layer):
            return .target(name: id.targetName(for: layer))
        case .service(let id, let layer):
            return .target(name: id.targetName(for: layer))
        }
    }

    /// Name of the local target this edge points to, `nil` for remote packages.
    var localTargetName: String? {
        switch self {
        case .module(let target): return target.targetName
        case .remote: return nil
        case .feature(let id, let layer): return id.targetName(for: layer)
        case .service(let id, let layer): return id.targetName(for: layer)
        }
    }
}
