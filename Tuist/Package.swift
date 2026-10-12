// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription
    import ProjectDescriptionHelpers

    /// Overrides Tuist's default `.staticFramework` product type per package, sourced from
    /// the same `RemotePackage` catalog `Project.swift` reads for `.remote(...)`.
    ///
    /// This block only exists for Tuist's own manifest loader, which compiles this file with
    /// the `TUIST` condition set. It can safely import `ProjectDescriptionHelpers`.
    let packageSettings = PackageSettings(
        productTypes: Dictionary(
            uniqueKeysWithValues: RemotePackage.allCases.map { ($0.spec.productName, $0.spec.productType) }
        )
    )
#endif

// `tuist install` resolves this `dependencies:` array with the real Swift Package Manager,
// which never defines `TUIST` — so, unlike the block above, it cannot import
// `ProjectDescriptionHelpers`. The url/version below must therefore be kept in sync by hand
// with `RemotePackage.swift`; see that file's `requirement` field for the value that belongs
// here. This is a structural limit of Tuist's external-dependency mechanism, not of this DSL.
let package = Package(
    name: "ExternalDependencies",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
    ]
)
