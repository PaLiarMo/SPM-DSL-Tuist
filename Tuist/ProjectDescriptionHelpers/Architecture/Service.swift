/// Declares a cross-cutting Api/Impl service — always exactly two targets (`Api`, `Impl`),
/// wired according to `ServiceLayer`. `additionalDependencies` is where `Impl` gets its real
/// job: composing concrete feature screens together (e.g. `Router_Impl` depending on
/// `MainScreen_Presentation`) via `CompositionDependency`.
public struct Service: Sendable {
    public let id: ServiceID
    public let tests: Bool
    public let additionalDependencies: [ServiceLayer: [CompositionDependency]]

    public init(
        _ id: ServiceID,
        tests: Bool = true,
        additionalDependencies: [ServiceLayer: [CompositionDependency]] = [:]
    ) {
        self.id = id
        self.tests = tests
        self.additionalDependencies = additionalDependencies
    }

    func targetName(for layer: ServiceLayer) -> String {
        id.targetName(for: layer)
    }
}
