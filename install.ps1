# Toolwrite installer for Windows.
#
#   irm https://raw.githubusercontent.com/MygreatTuesday/toolwrite-releases/main/install.ps1 | iex
#
# Downloads the newest Toolwrite release for Windows (x86-64), checks its
# SHA-256 checksum, installs toolwrite.exe into your user folder (no
# administrator rights needed), and adds that folder to your PATH.
#
# Settings (environment variables, all optional):
#   TOOLWRITE_VERSION   a release tag such as v0.1.0 (default: the newest)
#   TOOLWRITE_REPO      the GitHub repository with the releases
#   TOOLWRITE_INSTALL   the folder to install into
#   TOOLWRITE_BASE_URL  where the release files are (default: the release's
#                       GitHub download folder); for testing a release
#   TOOLWRITE_NO_MODIFY_PATH=1   leave PATH as it is
#
# Keep this file plain ASCII: Windows PowerShell 5.1 misreads other
# characters in a script saved without a byte-order mark.

& {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'  # the progress bar slows downloads down a lot
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $repo = if ($env:TOOLWRITE_REPO) { $env:TOOLWRITE_REPO } else { 'MygreatTuesday/toolwrite-releases' }
    $installDir = if ($env:TOOLWRITE_INSTALL) { $env:TOOLWRITE_INSTALL } else { Join-Path $env:LOCALAPPDATA 'Programs\toolwrite\bin' }
    $target = 'x86_64-pc-windows-msvc'

    function Fail([string]$Message) {
        Write-Host ""
        Write-Host "Toolwrite was not installed: $Message" -ForegroundColor Red
        throw $Message
    }

    if (-not [Environment]::Is64BitOperatingSystem) {
        Fail 'Toolwrite needs 64-bit Windows.'
    }

    Write-Host 'Installing Toolwrite ...'
    if ($env:TOOLWRITE_VERSION) {
        $tag = $env:TOOLWRITE_VERSION
    } else {
        try {
            # Not /releases/latest: GitHub leaves pre-releases (betas) out of it.
            $releases = @(Invoke-RestMethod -UseBasicParsing "https://api.github.com/repos/$repo/releases?per_page=1")
            $tag = $releases[0].tag_name
        } catch {
            Fail "could not find the newest release at github.com/$repo (check the internet connection)."
        }
        if (-not $tag) {
            Fail "github.com/$repo has no release yet."
        }
    }

    $name = "toolwrite-$tag-$target"
    $base = if ($env:TOOLWRITE_BASE_URL) { $env:TOOLWRITE_BASE_URL.TrimEnd('/') } else { "https://github.com/$repo/releases/download/$tag" }
    $temp = Join-Path ([IO.Path]::GetTempPath()) ("toolwrite-install-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force $temp | Out-Null
    try {
        $zip = Join-Path $temp "$name.zip"
        Write-Host "  downloading $name.zip"
        try {
            Invoke-WebRequest -UseBasicParsing "$base/$name.zip" -OutFile $zip
            # Saved and read as text: servers (GitHub too) send .sha256 as a
            # binary file, which Invoke-WebRequest would return as bytes.
            Invoke-WebRequest -UseBasicParsing "$base/$name.zip.sha256" -OutFile "$zip.sha256"
        } catch {
            Fail "could not download $name.zip from $base."
        }
        $expected = ((Get-Content -Raw "$zip.sha256") -split '\s+')[0].Trim().ToLowerInvariant()

        $actual = (Get-FileHash -Algorithm SHA256 $zip).Hash.ToLowerInvariant()
        if ($actual -ne $expected) {
            Fail "the download is damaged or was changed (checksum $actual, expected $expected)."
        }
        Write-Host '  checksum verified'

        Expand-Archive $zip -DestinationPath $temp -Force
        New-Item -ItemType Directory -Force $installDir | Out-Null
        Copy-Item (Join-Path $temp "$name\toolwrite.exe") (Join-Path $installDir 'toolwrite.exe') -Force
    } finally {
        Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
    }

    # Add the folder to the user's PATH once, for new terminals and this one.
    if ($env:TOOLWRITE_NO_MODIFY_PATH -ne '1') {
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        $entries = @($userPath -split ';' | Where-Object { $_ })
        if ($entries -notcontains $installDir) {
            [Environment]::SetEnvironmentVariable('Path', (($entries + $installDir) -join ';'), 'User')
        }
    }
    if (($env:Path -split ';') -notcontains $installDir) {
        $env:Path = "$env:Path;$installDir"
    }

    $version = & (Join-Path $installDir 'toolwrite.exe') --version

    Write-Host ""
    Write-Host '  _____ ___   ___  _     __        ______  ___ _____ _____ ' -ForegroundColor Green
    Write-Host ' |_   _/ _ \ / _ \| |    \ \      / /  _ \|_ _|_   _| ____|' -ForegroundColor Green
    Write-Host '   | || | | | | | | |     \ \ /\ / /| |_) || |  | | |  _|  ' -ForegroundColor Green
    Write-Host '   | || |_| | |_| | |___   \ V  V / |  _ < | |  | | | |___ ' -ForegroundColor Green
    Write-Host '   |_| \___/ \___/|_____|   \_/\_/  |_| \_\___| |_| |_____|' -ForegroundColor Green
    Write-Host ""
    Write-Host '        /\        Describe it. Toolwrite plans it and builds it,' -ForegroundColor DarkGreen
    Write-Host '       /  \       and checks every file before you get it.' -ForegroundColor DarkGreen
    Write-Host '      /\  /\' -ForegroundColor DarkGreen
    Write-Host '     /  \/  \' -ForegroundColor DarkGreen
    Write-Host '        ||' -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "Installed $version to $installDir"
    Write-Host ""
    Write-Host 'Next, in a new PowerShell window:'
    Write-Host '  toolwrite login                              sign in to Toolwrite Cloud (once)'
    Write-Host '  toolwrite "Create a landing page for a bakery"'
    Write-Host ""
    Write-Host 'Always start with the word toolwrite, then say what you want.'
    Write-Host 'Or type toolwrite on its own to open the Toolwrite shell, and just describe it.'
    Write-Host 'Projects go into the folder you are in, or into "Toolwrite projects" in your home folder.'
}
