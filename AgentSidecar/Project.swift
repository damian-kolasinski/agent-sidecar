import ProjectDescription

let project = Project(
    name: "AgentSidecar",
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0",
        ]
    ),
    targets: [
        .target(
            name: "AgentSidecar",
            destinations: .macOS,
            product: .app,
            bundleId: "com.agentsidecar.app",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "AgentSidecar",
                "NSMainNibFile": "",
                "NSPrincipalClass": "NSApplication",
                "CFBundleURLTypes": .array([
                    .dictionary([
                        "CFBundleURLName": .string("com.agentsidecar.deeplink"),
                        "CFBundleURLSchemes": .array([.string("agentsidecar")]),
                    ]),
                ]),
            ]),
            sources: ["AgentSidecar/**"],
            resources: [
                .glob(pattern: "AgentSidecar/Resources/**", excluding: ["AgentSidecar/Resources/Info.plist"]),
            ],
            settings: .settings(
                base: [
                    "PRODUCT_NAME": "AgentSidecar",
                    "SWIFT_STRICT_CONCURRENCY": "complete",
                    "ENABLE_APP_SANDBOX": "false",
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                ]
            )
        ),
        .target(
            name: "AgentSidecarTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.agentsidecar.tests",
            deploymentTargets: .macOS("15.0"),
            sources: ["AgentSidecarTests/**"],
            dependencies: [
                .target(name: "AgentSidecar"),
            ]
        ),
    ]
)
