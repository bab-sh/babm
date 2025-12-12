param(
    [string]$Version,
    [string]$InstallPath
)

$Owner = "bab-sh"
$Repo = "babm"
$BinaryName = "babm"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Get-LatestRelease {
    $apiUrl = "https://api.github.com/repos/$Owner/$Repo/releases/latest"
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -ErrorAction Stop
        return $response.tag_name
    }
    catch {
        Write-Error "Failed to fetch latest release: $_"
        exit 1
    }
}

function Get-Architecture {
    $arch = $env:PROCESSOR_ARCHITECTURE
    switch ($arch) {
        "AMD64" { return "x64" }
        "ARM64" { return "arm64" }
        default {
            Write-Error "Unsupported architecture: $arch"
            exit 1
        }
    }
}

function Verify-Checksum {
    param(
        [string]$FilePath,
        [string]$ChecksumFile
    )

    $fileName = Split-Path $FilePath -Leaf
    $content = Get-Content $ChecksumFile -ErrorAction SilentlyContinue
    if (-not $content) { return $true }

    $checksumLine = $content | Where-Object { $_ -like "*$fileName*" }
    if (-not $checksumLine) { return $true }

    $expectedChecksum = ($checksumLine -split '\s+')[0]
    $fileHash = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash.ToLower()

    if ($fileHash -eq $expectedChecksum.ToLower()) {
        Write-Host "Checksum verified" -ForegroundColor Green
        return $true
    }
    else {
        Write-Error "Checksum verification failed"
        return $false
    }
}

if (-not $Version) {
    Write-Host "Fetching latest version..." -ForegroundColor Cyan
    $Version = Get-LatestRelease
}

Write-Host "Installing $BinaryName $Version" -ForegroundColor Green

$arch = Get-Architecture
$binaryFileName = "$BinaryName-windows-$arch.exe"
$downloadUrl = "https://github.com/$Owner/$Repo/releases/download/$Version/$binaryFileName"
$checksumUrl = "https://github.com/$Owner/$Repo/releases/download/$Version/SHA256SUMS.txt"

if (-not $InstallPath) {
    $InstallPath = "$env:LOCALAPPDATA\$BinaryName\bin"
}

$tempDir = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    $downloadPath = Join-Path $tempDir $binaryFileName
    Write-Host "Downloading $binaryFileName..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -UseBasicParsing -ErrorAction Stop

    $checksumPath = Join-Path $tempDir "SHA256SUMS.txt"
    try {
        Invoke-WebRequest -Uri $checksumUrl -OutFile $checksumPath -UseBasicParsing -ErrorAction Stop
        if (-not (Verify-Checksum -FilePath $downloadPath -ChecksumFile $checksumPath)) {
            exit 1
        }
    }
    catch {
        Write-Warning "Could not verify checksum"
    }

    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    }

    $destPath = Join-Path $InstallPath "$BinaryName.exe"
    Copy-Item -Path $downloadPath -Destination $destPath -Force
    Write-Host "Installed to: $destPath" -ForegroundColor Green

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$InstallPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$InstallPath", "User")
        $env:Path = "$env:Path;$InstallPath"
        Write-Host "Added $InstallPath to PATH" -ForegroundColor Green
        Write-Host "Restart your terminal for PATH changes to take effect" -ForegroundColor Yellow
    }

    Write-Host "`n$BinaryName installed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Installation failed: $_"
    exit 1
}
finally {
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
