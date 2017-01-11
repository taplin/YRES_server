import PackageDescription

let package = Package(
    name: "YRES_server",
    targets: [],
    dependencies: [
        .Package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", majorVersion:2),
        .Package(url: "https://github.com/PerfectlySoft/Perfect-Mustache.git", majorVersion:2),
        .Package(url:"https://github.com/PerfectlySoft/Perfect-MySQL.git", versions: Version(0,0,0)..<Version(2,2,0)),
        .Package(url:"https://github.com/PerfectlySoft/Perfect-SQLite.git", versions: Version(0,0,0)..<Version(2,2,0)),
        .Package(url: "https://github.com/stormpath/Turnstile-Perfect.git", majorVersion:0, minor: 2)
    ]
)
