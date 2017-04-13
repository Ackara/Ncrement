powershell -NoProfile .\start-build.ps1 pester -TestName semver -BuildConfiguration "Debug"
powershell -NoProfile .\start-build.ps1 test -BuildConfiguration "Debug"