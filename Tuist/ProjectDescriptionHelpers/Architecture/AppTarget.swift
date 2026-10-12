/// The composition root. Uses `CompositionDependency` — the same broad access a `Service`'s
/// `impl` layer gets — since the app target is where everything is finally wired together
/// (e.g. depending on `Router_Impl` and `Router_Api` directly).
public struct AppTarget: Sendable {
    public let dependencies: [CompositionDependency]

    public init(dependencies: [CompositionDependency]) {
        self.dependencies = dependencies
    }
}
