import ProjectDescription

/// A pinned semantic version expressed as plain integers, so this file never needs to parse
/// a string or depend on `PackageDescription.Version` — a type this module (compiled against
/// `ProjectDescription`, not `PackageDescription`) doesn't have access to.
public struct RemotePackageVersion: Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init(_ major: Int, _ minor: Int, _ patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
}

public enum RemotePackageRequirement: Sendable {
    case upToNextMajor(from: RemotePackageVersion)
    case exact(RemotePackageVersion)
}

public struct RemotePackageSpec: Sendable {
    public let url: String
    public let productName: String
    /// Documents the version constraint `Tuist/Package.swift` is expected to declare.
    /// Not read mechanically from there — see the comment in `Tuist/Package.swift` for why —
    /// but keeps the intent next to `productName`/`productType`, which *are* read mechanically
    /// by both `Tuist/Package.swift` (productTypes) and `Project.swift` (`.remote(...)`).
    public let requirement: RemotePackageRequirement
    public let productType: Product

    public init(
        url: String,
        productName: String,
        requirement: RemotePackageRequirement,
        productType: Product = .staticFramework
    ) {
        self.url = url
        self.productName = productName
        self.requirement = requirement
        self.productType = productType
    }
}

/// Catalog of every remote SwiftPM dependency the app links against. This is the type-safe
/// replacement for spreading `"Alamofire"` string literals across manifests: add a case here,
/// reference it via `.remote(.alamofire)` — never a bare product-name string.
public enum RemotePackage: CaseIterable, Sendable {
    case alamofire

    public var spec: RemotePackageSpec {
        switch self {
        case .alamofire:
            return RemotePackageSpec(
                url: "https://github.com/Alamofire/Alamofire.git",
                productName: "Alamofire",
                requirement: .upToNextMajor(from: .init(5, 8, 0))
            )
        }
    }
}
