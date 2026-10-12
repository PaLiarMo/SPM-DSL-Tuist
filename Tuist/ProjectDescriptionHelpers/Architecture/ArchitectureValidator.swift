/// One architectural violation found while resolving the dependency graph declared in
/// `Project.swift`.
struct ArchitectureViolation: CustomStringConvertible {
    let from: String
    let to: String
    let rule: String
    var description: String { "\(from) → \(to)  (\(rule))" }
}

/// Runs at manifest-evaluation time — i.e. during `tuist generate` / `tuist edit`, before any
/// `.xcodeproj` exists. `Architecture.project(...)` aborts generation via `fatalError` when
/// this returns violations, so a forbidden edge can never reach a checked-in Xcode project.
///
/// Most of the rules from the original spec (no Feature → Feature, no Core → Feature, no
/// Feature → Service.Impl) don't need a validator at all: `ModuleDependency` simply has no
/// case that could express them — see the comment on that type. What's left here are the
/// edges the type system *can't* rule out on its own, because `additionalDependencies`/
/// `Module.dependencies` are open lists.
enum ArchitectureValidator {
    static func validate(modules: [Module], features: [Feature], services: [Service]) -> [ArchitectureViolation] {
        var violations: [ArchitectureViolation] = []
        violations += validateCoreHasNoLocalDependencies(modules: modules)
        violations += validateDomainAndDataStayOutOfUI(features: features)
        violations += CycleDetector.findCycles(modules: modules, features: features, services: services)
            .map { ArchitectureViolation(from: $0.from, to: $0.to, rule: "цикл в графе зависимостей") }
        return violations
    }

    /// Core must be a pure leaf: if it could depend on another local module, "the module
    /// everything else can safely depend on" would stop being true.
    private static func validateCoreHasNoLocalDependencies(modules: [Module]) -> [ArchitectureViolation] {
        modules
            .filter { $0.id == .Core }
            .flatMap { module in
                module.dependencies.compactMap { dependency -> ArchitectureViolation? in
                    guard case .module(let target) = dependency else { return nil }
                    return ArchitectureViolation(
                        from: LocalModule.Core.targetName,
                        to: target.targetName,
                        rule: "Core не может зависеть от других локальных модулей"
                    )
                }
            }
    }

    /// Only Presentation may touch UI/Resources — Domain and Data must stay UI-agnostic so
    /// they can be reused behind any UI layer (or none, e.g. a widget/extension target).
    private static func validateDomainAndDataStayOutOfUI(features: [Feature]) -> [ArchitectureViolation] {
        let forbidden: Set<LocalModule> = [.UI, .Resources]
        return features.flatMap { feature -> [ArchitectureViolation] in
            [FeatureLayer.domain, .data].flatMap { layer -> [ArchitectureViolation] in
                (feature.additionalDependencies[layer] ?? []).compactMap { dependency in
                    guard case .module(let module) = dependency, forbidden.contains(module) else { return nil }
                    return ArchitectureViolation(
                        from: feature.targetName(for: layer),
                        to: module.targetName,
                        rule: "\(layer.rawValue.prefix(1).uppercased() + String(layer.rawValue.dropFirst())) не может зависеть от UI-слоя"
                    )
                }
            }
        }
    }
}

/// Depth-first cycle detection over the full local-module dependency graph: base modules,
/// every feature layer, and every service layer, internal and external edges alike.
enum CycleDetector {
    struct Edge { let from: String; let to: String }

    static func findCycles(modules: [Module], features: [Feature], services: [Service]) -> [Edge] {
        var adjacency: [String: [String]] = [:]

        for module in modules {
            adjacency[module.id.targetName, default: []] += module.dependencies.compactMap(\.localTargetName)
        }

        for feature in features {
            for layer in feature.layers {
                let name = feature.targetName(for: layer)
                let internalEdges = layer.internalDependencies.map { feature.targetName(for: $0) }
                let externalEdges = (layer.baseDependencies + (feature.additionalDependencies[layer] ?? []))
                    .compactMap(\.localTargetName)
                adjacency[name, default: []] += internalEdges + externalEdges
            }
        }

        for service in services {
            for layer in ServiceLayer.allCases {
                let name = service.targetName(for: layer)
                let internalEdges = layer.internalDependencies.map { service.targetName(for: $0) }
                let externalEdges = (layer.baseDependencies + (service.additionalDependencies[layer] ?? []))
                    .compactMap(\.localTargetName)
                adjacency[name, default: []] += internalEdges + externalEdges
            }
        }

        var visited: Set<String> = []
        var stack: Set<String> = []
        var cycles: [Edge] = []

        func visit(_ node: String) {
            guard !visited.contains(node) else { return }
            visited.insert(node)
            stack.insert(node)
            for next in adjacency[node] ?? [] {
                if stack.contains(next) {
                    cycles.append(Edge(from: node, to: next))
                } else {
                    visit(next)
                }
            }
            stack.remove(node)
        }

        for node in adjacency.keys { visit(node) }
        return cycles
    }
}
