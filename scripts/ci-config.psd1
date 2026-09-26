@{
    LinuxAptPackages = @(
        'clang'
        'cmake'
        'ninja-build'
        'pkg-config'
        'libgtk-3-dev'
        'libayatana-appindicator3-dev'
    )
    FlutterArgs = @{
        windows = '--release'
        linux   = '--release'
        apk     = '--debug'
        macos   = '--release'
        ios     = '--release --no-codesign'
    }
}
