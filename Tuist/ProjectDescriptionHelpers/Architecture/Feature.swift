/// Declares a vertically-sliced feature. By default it creates all three layers
/// (`presentation`, `domain`, `data`), wired according to the rules centralized in
/// `FeatureLayer` — nobody repeats "Presentation depends on Domain" per feature.
///
/// `additionalDependencies` is the only per-feature escape hatch (e.g. a screen that also
/// needs `DI`), and it is still typed as `[ModuleDependency]` — a `LocalModule` or a
/// `RemotePackage` — so a feature still cannot depend on another feature directly.
public struct Feature: Sendable {
    public let id: FeatureID
    public let layers: [FeatureLayer]
    public let tests: Bool
    public let additionalDependencies: [FeatureLayer: [ModuleDependency]]

    public init(
        _ id: FeatureID,
        layers: [FeatureLayer] = FeatureLayer.allCases,
        tests: Bool = true,
        additionalDependencies: [FeatureLayer: [ModuleDependency]] = [:]
    ) {
        self.id = id
        self.layers = layers
        self.tests = tests
        self.additionalDependencies = additionalDependencies
    }

    func targetName(for layer: FeatureLayer) -> String {
        id.targetName(for: layer)
    }
}
