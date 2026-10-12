import ProjectDescription

public enum ArchitectureComponent {
    case module(Module)
    case feature(Feature)
    case service(Service)
}

@resultBuilder
public enum ArchitectureBuilder {
    public static func buildBlock(_ components: [ArchitectureComponent]...) -> [ArchitectureComponent] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ module: Module) -> [ArchitectureComponent] { [.module(module)] }
    public static func buildExpression(_ feature: Feature) -> [ArchitectureComponent] { [.feature(feature)] }
    public static func buildExpression(_ service: Service) -> [ArchitectureComponent] { [.service(service)] }

    public static func buildOptional(_ component: [ArchitectureComponent]?) -> [ArchitectureComponent] {
        component ?? []
    }

    public static func buildEither(first component: [ArchitectureComponent]) -> [ArchitectureComponent] {
        component
    }

    public static func buildEither(second component: [ArchitectureComponent]) -> [ArchitectureComponent] {
        component
    }
}

/// The root of the DSL. Collects every `Module`, `Feature` and `Service` declared in
/// `Project.swift`, validates the resulting graph, and only then lowers it to
/// `ProjectDescription.Target`s.
///
/// `ProjectDescription` never leaks past `project(...)`: `Project.swift` only ever touches
/// `Architecture`, `Module`, `Feature`, `Service`, `AppTarget`, `LocalModule` and
/// `RemotePackage` — every other type in this file (`Target`, `TargetDependency`, `Project`
/// itself) is an infrastructure detail this DSL exists to hide.
public struct Architecture {
    public let modules: [Module]
    public let features: [Feature]
    public let services: [Service]

    public init(@ArchitectureBuilder _ content: () -> [ArchitectureComponent]) {
        let components = content()
        modules = components.compactMap {
            if case .module(let module) = $0 { return module }
            return nil
        }
        features = components.compactMap {
            if case .feature(let feature) = $0 { return feature }
            return nil
        }
        services = components.compactMap {
            if case .service(let service) = $0 { return service }
            return nil
        }
    }

    /// Validates the architecture and lowers it to a `Project`. A violation aborts generation
    /// with `fatalError` — see `ArchitectureValidator` for exactly what gets checked and why.
    public func project(
        name: String,
        organizationName: String? = nil,
        bundleIdPrefix: String,
        app: AppTarget? = nil
    ) -> Project {
        let violations = ArchitectureValidator.validate(modules: modules, features: features, services: services)
        guard violations.isEmpty else {
            let report = violations.map { "  • \($0)" }.joined(separator: "\n")
            fatalError("""

            ❌ Архитектурная валидация не пройдена — генерация проекта остановлена.
            \(report)

            """)
        }

        let configuration = ArchitectureConfiguration(
            organizationName: organizationName,
            bundleIdPrefix: bundleIdPrefix,
            allLocalTargets: modules.map(\.id.targetName)
                + features.flatMap { feature in feature.layers.map { feature.targetName(for: $0) } }
                + services.flatMap { service in ServiceLayer.allCases.map { service.targetName(for: $0) } }
        )

        var targets = modules.flatMap { TargetFactory.makeTargets(for: $0, configuration: configuration) }
        targets += features.flatMap { TargetFactory.makeTargets(for: $0, configuration: configuration) }
        targets += services.flatMap { TargetFactory.makeTargets(for: $0, configuration: configuration) }
        if let app {
            targets.append(TargetFactory.makeAppTarget(app, configuration: configuration))
        }

        return Project(
            name: name,
            organizationName: organizationName,
            targets: targets
        )
    }
}
