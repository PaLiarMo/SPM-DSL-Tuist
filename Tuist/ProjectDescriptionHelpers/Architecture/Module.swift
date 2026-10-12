import ProjectDescription

/// Declares one production module and, by default, its test target — the single place a
/// base module's dependencies and test coverage are described. Nothing about `Core` or
/// `Networking` needs to be repeated anywhere else in the manifests.
public struct Module: Sendable {
    public let id: LocalModule
    public let dependencies: [ModuleDependency]
    public let tests: Bool
    public let resources: ResourceFileElements?

    public init(
        _ id: LocalModule,
        dependencies: [ModuleDependency] = [],
        tests: Bool = true,
        resources: ResourceFileElements? = nil
    ) {
        self.id = id
        self.dependencies = dependencies
        self.tests = tests
        self.resources = resources
    }
}
