// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "url_launcher_macos", path: "../.packages/url_launcher_macos-3.2.5"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.6"),
        .package(name: "app_links", path: "../.packages/app_links-7.1.1"),
        .package(name: "record_macos", path: "../.packages/record_macos-1.2.2"),
        .package(name: "file_selector_macos", path: "../.packages/file_selector_macos-0.9.5"),
        .package(name: "firebase_ai", path: "../.packages/firebase_ai-3.12.2"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-4.10.0"),
        .package(name: "firebase_auth", path: "../.packages/firebase_auth-6.5.2"),
        .package(name: "firebase_app_check", path: "../.packages/firebase_app_check-0.4.4+2"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "url-launcher-macos", package: "url_launcher_macos"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "app-links", package: "app_links"),
                .product(name: "record-macos", package: "record_macos"),
                .product(name: "file-selector-macos", package: "file_selector_macos"),
                .product(name: "firebase-ai", package: "firebase_ai"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "firebase-auth", package: "firebase_auth"),
                .product(name: "firebase-app-check", package: "firebase_app_check"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
