import Foundation
import ProjectDescription

/// Shared generation settings every target is stamped with. Centralized so "what iOS version
/// do we support" or "how do we compute a bundle id" is answered in exactly one place.
///
/// Deployment target is 17.0, not 16.0: the ported `Resources` module uses `UIImage(resource:)`
/// / `ImageResource`, which need iOS 17.
struct ArchitectureConfiguration {
    let organizationName: String?
    let bundleIdPrefix: String
    let destinations: Destinations
    let deploymentTargets: DeploymentTargets
    /// Every local target name in the graph — the universe `ImportGuard` checks imports against.
    let allLocalTargets: [String]

    init(
        organizationName: String?,
        bundleIdPrefix: String,
        allLocalTargets: [String],
        destinations: Destinations = .iOS,
        deploymentTargets: DeploymentTargets = .iOS("17.0")
    ) {
        self.organizationName = organizationName
        self.bundleIdPrefix = bundleIdPrefix
        self.destinations = destinations
        self.deploymentTargets = deploymentTargets
        self.allLocalTargets = allLocalTargets
    }
}

/// The Info.plist the app target needs on top of Tuist's auto-generated default: a UIKit
/// scene manifest routing to `SceneDelegate` (ported as-is from the original AppDelegate/
/// SceneDelegate lifecycle), and a plain `UILaunchScreen` instead of porting the original's
/// storyboard file — same functional result (a blank launch screen), one fewer resource to
/// wire through the DSL.
private let appInfoPlist: InfoPlist = .extendingDefault(with: [
    "UILaunchScreen": .dictionary([:]),
    "UIApplicationSceneManifest": .dictionary([
        "UIApplicationSupportsMultipleScenes": .boolean(false),
        "UISceneConfigurations": .dictionary([
            "UIWindowSceneSessionRoleApplication": .array([
                .dictionary([
                    "UISceneConfigurationName": .string("Default Configuration"),
                    "UISceneDelegateClassName": .string("$(PRODUCT_MODULE_NAME).SceneDelegate"),
                ]),
            ]),
        ]),
    ]),
])

/// Turns `Module` / `Feature` / `Service` / `AppTarget` values into real
/// `ProjectDescription.Target`s.
///
/// This is the *only* file in the whole DSL that ever writes `.target(name: "...")` with a
/// raw string. Every other file — including `Project.swift` — goes through `LocalModule`,
/// `Feature`, `Service` or one of the dependency types instead.
enum TargetFactory {
    static func makeTargets(for module: Module, configuration: ArchitectureConfiguration) -> [Target] {
        let name = module.id.targetName
        var targets = [
            makeTarget(
                name: name,
                path: "Sources/\(name)",
                product: .staticFramework,
                dependencies: module.dependencies.map(\.asTargetDependency),
                allowedLocalImports: module.dependencies.compactMap(\.localTargetName),
                resources: module.resources,
                configuration: configuration
            ),
        ]
        if module.tests {
            targets.append(
                makeTestTarget(
                    name: "\(name)Tests",
                    path: "Tests/\(name)Tests",
                    productionTargetName: name,
                    configuration: configuration
                )
            )
        }
        return targets
    }

    static func makeTargets(for feature: Feature, configuration: ArchitectureConfiguration) -> [Target] {
        feature.layers.flatMap { layer -> [Target] in
            let name = feature.targetName(for: layer)
            let internalDependencies = layer.internalDependencies.map {
                TargetDependency.target(name: feature.targetName(for: $0))
            }
            let declaredDependencies = layer.baseDependencies + (feature.additionalDependencies[layer] ?? [])
            let externalDependencies = declaredDependencies.map(\.asTargetDependency)
            let allowedLocalImports = layer.internalDependencies.map { feature.targetName(for: $0) }
                + declaredDependencies.compactMap(\.localTargetName)

            var targets = [
                makeTarget(
                    name: name,
                    path: "Sources/Features/\(feature.id.rawValue)/\(layer.suffix)",
                    product: .staticFramework,
                    dependencies: internalDependencies + externalDependencies,
                    allowedLocalImports: allowedLocalImports,
                    resources: nil,
                    configuration: configuration
                ),
            ]
            if feature.tests {
                targets.append(
                    makeTestTarget(
                        name: "\(name)Tests",
                        path: "Tests/Features/\(feature.id.rawValue)/\(layer.suffix)Tests",
                        productionTargetName: name,
                        configuration: configuration
                    )
                )
            }
            return targets
        }
    }

    static func makeTargets(for service: Service, configuration: ArchitectureConfiguration) -> [Target] {
        ServiceLayer.allCases.flatMap { layer -> [Target] in
            let name = service.targetName(for: layer)
            let internalDependencies = layer.internalDependencies.map {
                TargetDependency.target(name: service.targetName(for: $0))
            }
            let declaredDependencies = layer.baseDependencies + (service.additionalDependencies[layer] ?? [])
            let externalDependencies = declaredDependencies.map(\.asTargetDependency)
            let allowedLocalImports = layer.internalDependencies.map { service.targetName(for: $0) }
                + declaredDependencies.compactMap(\.localTargetName)

            var targets = [
                makeTarget(
                    name: name,
                    path: "Sources/Features/\(service.id.rawValue)/\(layer.suffix)",
                    product: .staticFramework,
                    dependencies: internalDependencies + externalDependencies,
                    allowedLocalImports: allowedLocalImports,
                    resources: nil,
                    configuration: configuration
                ),
            ]
            if service.tests {
                targets.append(
                    makeTestTarget(
                        name: "\(name)Tests",
                        path: "Tests/Features/\(service.id.rawValue)/\(layer.suffix)Tests",
                        productionTargetName: name,
                        configuration: configuration
                    )
                )
            }
            return targets
        }
    }

    static func makeAppTarget(_ app: AppTarget, configuration: ArchitectureConfiguration) -> Target {
        makeTarget(
            name: "App",
            path: "Sources/App",
            product: .app,
            dependencies: app.dependencies.map(\.asTargetDependency),
            allowedLocalImports: app.dependencies.compactMap(\.localTargetName),
            resources: nil,
            infoPlist: appInfoPlist,
            configuration: configuration
        )
    }

    private static func makeTarget(
        name: String,
        path: String,
        product: Product,
        dependencies: [TargetDependency],
        allowedLocalImports: [String],
        resources: ResourceFileElements?,
        infoPlist: InfoPlist = .default,
        configuration: ArchitectureConfiguration
    ) -> Target {
        .target(
            name: name,
            destinations: configuration.destinations,
            product: product,
            bundleId: bundleID(for: name, configuration: configuration),
            deploymentTargets: configuration.deploymentTargets,
            infoPlist: infoPlist,
            sources: ["\(path)/**"],
            resources: resources,
            scripts: [
                ImportGuard.script(
                    targetName: name,
                    sourcesPath: path,
                    allowedLocalImports: allowedLocalImports,
                    allLocalTargets: configuration.allLocalTargets
                ),
            ],
            dependencies: dependencies
        )
    }

    private static func makeTestTarget(
        name: String,
        path: String,
        productionTargetName: String,
        configuration: ArchitectureConfiguration
    ) -> Target {
        .target(
            name: name,
            destinations: configuration.destinations,
            product: .unitTests,
            bundleId: bundleID(for: name, configuration: configuration),
            deploymentTargets: configuration.deploymentTargets,
            infoPlist: .default,
            sources: ["\(path)/**"],
            dependencies: [.target(name: productionTargetName)]
        )
    }

    /// A bundle id may not contain `_` (only alphanumerics, `-` and `.`), but the Xcode
    /// *target* name is what determines the Swift module name — and the ported code imports
    /// modules like `MainScreen_Domain` and `Router_Api` verbatim. So the target keeps its
    /// underscore; only the bundle id, a separate and purely cosmetic identifier, is sanitized.
    private static func bundleID(for name: String, configuration: ArchitectureConfiguration) -> String {
        "\(configuration.bundleIdPrefix).\(name.replacingOccurrences(of: "_", with: "-"))"
    }
}
