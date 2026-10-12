import ProjectDescription
import ProjectDescriptionHelpers

let architecture = Architecture {
    Module(.Core)
    Module(.UI, dependencies: [.module(.Core)])
    Module(.DI, dependencies: [.module(.Core)])
    Module(.Resources, resources: ["Sources/Resources/Resources.xcassets/**"])

    Module(.Networking, dependencies: [
        .module(.Core),
        .remote(.alamofire),
    ])

    Service(
        .Router,
        tests: false,
        additionalDependencies: [
            .impl: [
                .module(.DI),
                .feature(.MainScreen, .presentation),
                .feature(.DetailScreen, .presentation),
            ],
        ]
    )

    Feature(
        .MainScreen,
        additionalDependencies: [.presentation: [.module(.DI), .serviceAPI(.Router)]]
    )

    Feature(
        .DetailScreen,
        additionalDependencies: [.presentation: [.module(.DI), .serviceAPI(.Router)]]
    )
}

let project = architecture.project(
    name: "App",
    organizationName: "dev.tuist",
    bundleIdPrefix: "dev.tuist.app",
    app: AppTarget(dependencies: [
        .service(.Router, .impl),
        .service(.Router, .api),
    ])
)
