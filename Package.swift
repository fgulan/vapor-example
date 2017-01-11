import PackageDescription

let package = Package(
    name: "Plnnr",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1),
        .Package(url: "https://github.com/SwiftyBeaver/SwiftyBeaver-Vapor.git", majorVersion: 1),
        .Package(url: "https://github.com/vapor/sqlite.git", majorVersion: 1),
        .Package(url: "https://github.com/vapor/fluent.git", majorVersion: 1),
        .Package(url: "https://github.com/vapor/sqlite-driver.git", majorVersion: 1)
    ],
    exclude: [
        "Config",
        "Database",
        "Localization",
        "Public",
        "Resources",
        "Tests",
    ]
)

