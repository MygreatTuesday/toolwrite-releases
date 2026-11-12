# Toolwrite installer for Windows.
#
#   irm https://raw.githubusercontent.com/MygreatTuesday/toolwrite-releases/main/install.ps1 | iex
#
# Downloads the newest Toolwrite release for Windows (x86-64), checks its
# SHA-256 checksum, installs toolwrite.exe into your user folder (no
# administrator rights needed), adds that folder to your PATH, and puts the
# Toolwrite tree icon on the Desktop and in the Start menu. The icon opens
# Toolwrite in the "Toolwrite projects" folder of your home folder, ready
# for a request in your own words.
#
# Settings (environment variables, all optional):
#   TOOLWRITE_VERSION   a release tag such as v0.1.0 (default: the newest)
#   TOOLWRITE_REPO      the GitHub repository with the releases
#   TOOLWRITE_INSTALL   the folder to install into
#   TOOLWRITE_BASE_URL  where the release files are (default: the release's
#                       GitHub download folder); for testing a release
#   TOOLWRITE_NO_MODIFY_PATH=1   leave PATH as it is
#   TOOLWRITE_NO_SHORTCUT=1      no Desktop or Start menu icon
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
        $icon = Join-Path $temp "$name\toolwrite.ico"
        if (Test-Path $icon) {
            Copy-Item $icon (Join-Path $installDir 'toolwrite.ico') -Force
        }
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

    # The Toolwrite tree icon, on the Desktop and in the Start menu: it opens
    # Toolwrite in "Toolwrite projects", ready for a request in plain words.
    $shortcuts = @()
    if ($env:TOOLWRITE_NO_SHORTCUT -ne '1') {
        try {
            $projects = Join-Path $HOME 'Toolwrite projects'
            New-Item -ItemType Directory -Force $projects | Out-Null
            $exe = Join-Path $installDir 'toolwrite.exe'
            $iconFile = Join-Path $installDir 'toolwrite.ico'
            $shell = New-Object -ComObject WScript.Shell
            foreach ($place in @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))) {
                if (-not $place) { continue }
                $link = $shell.CreateShortcut((Join-Path $place 'Toolwrite.lnk'))
                $link.TargetPath = $exe
                $link.Arguments = '--window'
                $link.WorkingDirectory = $projects
                $link.Description = 'Toolwrite: describe it, and it builds it'
                $link.IconLocation = if (Test-Path $iconFile) { "$iconFile,0" } else { "$exe,0" }
                $link.Save()
                $shortcuts += $place
            }
        } catch {
            Write-Host "  (could not add the Toolwrite icon: $($_.Exception.Message))" -ForegroundColor Yellow
        }
    }

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
    if ($shortcuts.Count -gt 0) {
        Write-Host 'Next: double-click the Toolwrite tree on your Desktop (or find Toolwrite'
        Write-Host 'in the Start menu) and type what you want, in your own words:'
        Write-Host '  Build me a webpage for my bakery'
        Write-Host 'The first time, it helps you sign in to Toolwrite Cloud.'
        Write-Host ""
        Write-Host 'In a terminal, start with the word toolwrite instead:'
        Write-Host '  toolwrite Build me a webpage for my bakery'
    } else {
        Write-Host 'Next, in a new PowerShell window:'
        Write-Host '  toolwrite login                              sign in to Toolwrite Cloud (once)'
        Write-Host '  toolwrite Build me a webpage for my bakery'
        Write-Host ""
        Write-Host 'Start with the word toolwrite, then say what you want; or type toolwrite on'
        Write-Host 'its own to open the Toolwrite shell, and just describe it.'
    }
}
