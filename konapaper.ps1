# =================================================================
# KONAPAPER - Wallpaper Rotator for Windows
# Fetches wallpapers from Moebooru-based sites like Konachan.net
# Supports: tags, pools, artist, score filters, size limits, preload cache, cleanup
# =================================================================

#Requires -Version 5.1

# --- Constants & Defaults ---
$script:BASE_URL = "https://konachan.net"
$script:POST_ENDPOINT = "/post.json"

# Default Parameters
$script:TAGS = ""
$script:LIMIT = 50
$script:PAGE = 1
$script:RATING = "s"
$script:ORDER = "random"
$script:MAX_FILE_SIZE = "2MB"
$script:MIN_FILE_SIZE = ""
$script:MIN_WIDTH = 0
$script:MAX_WIDTH = 0
$script:MIN_HEIGHT = 0
$script:MAX_HEIGHT = 0
$script:ASPECT_RATIO = ""
$script:MIN_SCORE = ""
$script:ARTIST = ""
$script:POOL_ID = ""
$script:PRELOAD_COUNT = 3
$script:PREFERRED_FORMAT = "jpg"
$script:ANIMATED_ONLY = $false
$script:DRY_RUN = $false
$script:CLEAN_MODE = $false
$script:FORCE_CLEAN = $false
$script:DISCOVER_TAGS = $false
$script:DISCOVER_ARTISTS = $false
$script:LIST_POOLS = $false
$script:SEARCH_POOLS = ""
$script:EXPORT_TAGS = $false
$script:RANDOM_TAGS_COUNT = 0
$script:FAV_MODE = $false
$script:LIST_FAVS = $false
$script:FROM_FAVS = $false

# Logging
$script:ENABLE_LOGGING = $false
$script:LOG_FILE = ""
$script:LOG_LEVEL = "detailed"
$script:LOG_ROTATION = $true

# Cache
$script:MAX_PRELOAD_CACHE = 10
$script:DISCOVER_LIMIT = 20
$script:EXPORTED_TAGS_FILE = ""

# Favorites
$script:FAVORITES_DIR = ""

# --- Paths ---
$script:CACHE_DIR = Join-Path $env:LOCALAPPDATA "konapaper"
$script:PRELOAD_DIR = ""

# --- Helper Functions ---

function ConvertTo-Bytes {
    param([string]$SizeStr)
    $SizeStr = $SizeStr.ToUpper()
    if ($SizeStr -match '^([0-9]+(\.[0-9]+)?)$') {
        return [long]$Matches[1]
    }
    elseif ($SizeStr -match '^([0-9]+(\.[0-9]+)?)KB$') {
        return [long]([double]$Matches[1] * 1024)
    }
    elseif ($SizeStr -match '^([0-9]+(\.[0-9]+)?)MB$') {
        return [long]([double]$Matches[1] * 1024 * 1024)
    }
    elseif ($SizeStr -match '^([0-9]+(\.[0-9]+)?)GB$') {
        return [long]([double]$Matches[1] * 1024 * 1024 * 1024)
    }
    else {
        Write-Error "Error: invalid size format '$SizeStr' (use e.g. 500KB or 2MB)"
        exit 1
    }
}

function ConvertTo-HumanReadableSize {
    param([long]$Bytes)
    if ($Bytes -lt 1024) {
        return "${Bytes}B"
    }
    elseif ($Bytes -lt 1048576) {
        return "{0:N1}KB" -f ($Bytes / 1024)
    }
    else {
        return "{0:N2}MB" -f ($Bytes / 1048576)
    }
}

function Parse-AspectRatio {
    param([string]$Ratio)
    switch ($Ratio) {
        "16:9" { return 1.78 }
        "21:9" { return 2.37 }
        "4:3" { return 1.33 }
        "1:1" { return 1.00 }
        "3:2" { return 1.50 }
        "5:4" { return 1.25 }
        "32:9" { return 3.56 }
        default {
            if ($Ratio -match '^([0-9]+):([0-9]+)$') {
                return [math]::Round([double]$Matches[1] / [double]$Matches[2], 2)
            }
            else {
                Write-Error "Error: invalid aspect ratio '$Ratio' (use format like '16:9')"
                exit 1
            }
        }
    }
}

function Parse-PageArgument {
    param([string]$Arg)
    if ($Arg -eq "random" -or $Arg -eq "rand") {
        return (Get-Random -Minimum 1 -Maximum 1001)
    }
    if ($Arg -match '^(random:)?([0-9]+)-([0-9]+)$') {
        $min = [int]$Matches[2]
        $max = [int]$Matches[3]
        if ($min -ge $max) {
            Write-Error "Error: Invalid range '$Arg' (min must be less than max)"
            return $null
        }
        return (Get-Random -Minimum $min -Maximum ($max + 1))
    }
    if ($Arg -match '^[0-9]+$') {
        return [int]$Arg
    }
    Write-Error "Error: Invalid page format '$Arg'. Use number, 'random', or 'MIN-MAX'"
    return $null
}

function Get-ExtensionFromUrl {
    param([string]$Url)
    if ([string]::IsNullOrWhiteSpace($Url)) { return "jpg" }
    $ext = ($Url -split '\.')[-1]
    # Remove URL parameters if present
    $ext = ($ext -split '\?')[0]
    switch -Regex ($ext) {
        '^jpe?g$' { return "jpg" }
        '^png$' { return "png" }
        '^gif$' { return "gif" }
        '^webm$' { return "webm" }
        default { return "jpg" }
    }
}

function Get-FormatFilter {
    param([string]$PreferredFormat)
    if ($PreferredFormat -eq "gif" -or $PreferredFormat -eq "webm") {
        return "animated"
    }
    return ""
}

function Log-Write {
    param([string]$Level, [string]$Message)
    if (-not $script:ENABLE_LOGGING) { return }

    $shouldLog = switch ($script:LOG_LEVEL) {
        "basic" { $Level -ne "DEBUG" -and $Level -ne "TRACE" }
        "detailed" { $Level -ne "TRACE" }
        "verbose" { $true }
        default { $true }
    }

    if ($shouldLog) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "[$timestamp] [$Level] $Message" | Add-Content -Path $script:LOG_FILE -Force
    }
}

function Log-Init {
    if (-not $script:ENABLE_LOGGING) { return }

    $logDir = Split-Path $script:LOG_FILE -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    if ($script:LOG_ROTATION -and (Test-Path $script:LOG_FILE)) {
        $logSize = (Get-Item $script:LOG_FILE).Length
        $maxSize = 10485760  # 10MB
        if ($logSize -gt $maxSize) {
            for ($i = 4; $i -ge 1; $i--) {
                $oldFile = "${script:LOG_FILE}.$i"
                $newFile = "${script:LOG_FILE}.$($i + 1)"
                if (Test-Path $oldFile) {
                    Move-Item $oldFile $newFile -Force
                }
            }
            Move-Item $script:LOG_FILE "${script:LOG_FILE}.1" -Force
        }
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    @"

=== KONAPAPER EXECUTION SESSION ===
Timestamp: $timestamp
Script: $($MyInvocation.ScriptName)
Working Directory: $(Get-Location)
User: $env:USERNAME
PID: $PID
==================================
"@ | Add-Content -Path $script:LOG_FILE -Force
}

function Log-Error {
    param([string]$Message)
    Log-Write -Level "ERROR" -Message $Message
}

function Log-Success {
    param([string]$Message)
    Log-Write -Level "INFO" -Message $Message
}

# --- Config Loading ---
function Load-Config {
    $configPaths = @(
        (Join-Path $env:APPDATA "konapaper\konapaper.psd1"),
        (Join-Path $PSScriptRoot "konapaper.psd1"),
        (Join-Path (Get-Location) "konapaper.psd1")
    )

    $configFile = $null
    foreach ($path in $configPaths) {
        if (Test-Path $path) {
            $configFile = $path
            break
        }
    }

    if ($configFile) {
        try {
            $config = Import-PowerShellDataFile -Path $configFile
            if ($config.ContainsKey("TAGS")) { $script:TAGS = $config["TAGS"] }
            if ($config.ContainsKey("LIMIT")) { $script:LIMIT = $config["LIMIT"] }
            if ($config.ContainsKey("RATING")) { $script:RATING = $config["RATING"] }
            if ($config.ContainsKey("ORDER")) { $script:ORDER = $config["ORDER"] }
            if ($config.ContainsKey("PAGE")) { $script:PAGE = $config["PAGE"] }
            if ($config.ContainsKey("MAX_FILE_SIZE")) { $script:MAX_FILE_SIZE = $config["MAX_FILE_SIZE"] }
            if ($config.ContainsKey("MIN_FILE_SIZE")) { $script:MIN_FILE_SIZE = $config["MIN_FILE_SIZE"] }
            if ($config.ContainsKey("MIN_WIDTH")) { $script:MIN_WIDTH = $config["MIN_WIDTH"] }
            if ($config.ContainsKey("MAX_WIDTH")) { $script:MAX_WIDTH = $config["MAX_WIDTH"] }
            if ($config.ContainsKey("MIN_HEIGHT")) { $script:MIN_HEIGHT = $config["MIN_HEIGHT"] }
            if ($config.ContainsKey("MAX_HEIGHT")) { $script:MAX_HEIGHT = $config["MAX_HEIGHT"] }
            if ($config.ContainsKey("ASPECT_RATIO")) { $script:ASPECT_RATIO = $config["ASPECT_RATIO"] }
            if ($config.ContainsKey("MIN_SCORE")) { $script:MIN_SCORE = $config["MIN_SCORE"] }
            if ($config.ContainsKey("ARTIST")) { $script:ARTIST = $config["ARTIST"] }
            if ($config.ContainsKey("POOL_ID")) { $script:POOL_ID = $config["POOL_ID"] }
            if ($config.ContainsKey("PRELOAD_COUNT")) { $script:PRELOAD_COUNT = $config["PRELOAD_COUNT"] }
            if ($config.ContainsKey("PREFERRED_FORMAT")) { $script:PREFERRED_FORMAT = $config["PREFERRED_FORMAT"] }
            if ($config.ContainsKey("ANIMATED_ONLY")) { $script:ANIMATED_ONLY = $config["ANIMATED_ONLY"] }
            if ($config.ContainsKey("MAX_PRELOAD_CACHE")) { $script:MAX_PRELOAD_CACHE = $config["MAX_PRELOAD_CACHE"] }
            if ($config.ContainsKey("DISCOVER_LIMIT")) { $script:DISCOVER_LIMIT = $config["DISCOVER_LIMIT"] }
            if ($config.ContainsKey("FAVORITES_DIR")) { $script:FAVORITES_DIR = $config["FAVORITES_DIR"] }
            if ($config.ContainsKey("ENABLE_LOGGING")) { $script:ENABLE_LOGGING = $config["ENABLE_LOGGING"] }
            if ($config.ContainsKey("LOG_FILE")) { $script:LOG_FILE = $config["LOG_FILE"] }
            if ($config.ContainsKey("LOG_LEVEL")) { $script:LOG_LEVEL = $config["LOG_LEVEL"] }
            if ($config.ContainsKey("LOG_ROTATION")) { $script:LOG_ROTATION = $config["LOG_ROTATION"] }
            if ($config.ContainsKey("EXPORTED_TAGS_FILE")) { $script:EXPORTED_TAGS_FILE = $config["EXPORTED_TAGS_FILE"] }
            if ($config.ContainsKey("RANDOM_TAGS_LIST")) { $script:RANDOM_TAGS_LIST = @($config["RANDOM_TAGS_LIST"]) }
        }
        catch {
            Write-Warning "Failed to load config file: $_"
        }
    }

    if ([string]::IsNullOrEmpty($script:EXPORTED_TAGS_FILE)) {
        $configDir = Join-Path $env:APPDATA "konapaper"
        $script:EXPORTED_TAGS_FILE = Join-Path $configDir "discovered_tags.txt"
    }
    if ([string]::IsNullOrEmpty($script:FAVORITES_DIR)) {
        $script:FAVORITES_DIR = Join-Path ([Environment]::GetFolderPath("MyPictures")) "Wallpapers"
    }
    if ([string]::IsNullOrEmpty($script:LOG_FILE)) {
        $configDir = Join-Path $env:APPDATA "konapaper"
        $script:LOG_FILE = Join-Path $configDir "konapaper.log"
    }

    if (Test-Path $script:EXPORTED_TAGS_FILE) {
        $script:RANDOM_TAGS_LIST = @(Get-Content $script:EXPORTED_TAGS_FILE | Where-Object { $_ -ne "" })
    }

    if (-not $script:RANDOM_TAGS_LIST) {
        $script:RANDOM_TAGS_LIST = @("landscape", "scenic", "sky", "clouds", "water", "original", "touhou", "building")
    }
}

# --- Process Random Tags ---
function Process-RandomTags {
    if ($script:RANDOM_TAGS_LIST.Count -gt 0 -and $script:RANDOM_TAGS_COUNT -gt 0) {
        $selectedTags = $script:RANDOM_TAGS_LIST | Get-Random -Count $script:RANDOM_TAGS_COUNT
        $tagStr = $selectedTags -join " "
        if (-not [string]::IsNullOrEmpty($script:TAGS)) {
            $script:TAGS = "$script:TAGS $tagStr"
        }
        else {
            $script:TAGS = $tagStr
        }
    }
}

# --- Download & Filter ---
function Download-Wallpaper {
    param([string]$OutFile)

    $effectiveTags = if ($script:ANIMATED_ONLY) { "animated" } else { $script:TAGS }
    $formatFilter = Get-FormatFilter -PreferredFormat $script:PREFERRED_FORMAT
    if ($formatFilter -and $effectiveTags -notmatch $formatFilter) {
        if (-not [string]::IsNullOrEmpty($effectiveTags)) {
            $effectiveTags = "${effectiveTags}+${formatFilter}"
        }
        else {
            $effectiveTags = $formatFilter
        }
    }

    $encodedTags = $effectiveTags -replace ' ', '+'

    if (-not [string]::IsNullOrEmpty($script:POOL_ID)) {
        $apiUrl = "${script:BASE_URL}/pool/show.json?id=${script:POOL_ID}"
    }
    else {
        $apiUrl = "${script:BASE_URL}${script:POST_ENDPOINT}?limit=${script:LIMIT}&page=${script:PAGE}&tags=${encodedTags}+rating:${script:RATING}+order:${script:ORDER}"
        if (-not [string]::IsNullOrEmpty($script:MIN_SCORE)) {
            $apiUrl += "+score:>=$($script:MIN_SCORE)"
        }
        if (-not [string]::IsNullOrEmpty($script:ARTIST)) {
            $apiUrl += "+user:$($script:ARTIST)"
        }
    }

    Write-Host "-> Querying API: $apiUrl"
    Log-Write -Level "INFO" -Message "API call: $apiUrl"

    try {
        $posts = Invoke-RestMethod -Uri $apiUrl -Method Get
    }
    catch {
        Write-Host "Error: failed to reach ${script:BASE_URL}"
        Log-Error "API request failed: ${script:BASE_URL}"
        return $null
    }

    if ($posts -isnot [System.Array]) {
        if ($posts.posts) { $posts = @($posts.posts) } else { $posts = @($posts) }
    }

    $maxBytes = ConvertTo-Bytes -SizeStr $script:MAX_FILE_SIZE
    $minBytes = if ($script:MIN_FILE_SIZE) { ConvertTo-Bytes -SizeStr $script:MIN_FILE_SIZE } else { 0 }

    $filtered = $posts | Where-Object {
        $fileSize = $_.file_size
        $width = $_.width
        $height = $_.height
        if ($null -eq $fileSize -or $null -eq $width -or $null -eq $height) { return $false }
        if ($maxBytes -gt 0 -and $fileSize -gt $maxBytes) { return $false }
        if ($minBytes -gt 0 -and $fileSize -lt $minBytes) { return $false }
        if ($script:MIN_WIDTH -gt 0 -and $width -lt $script:MIN_WIDTH) { return $false }
        if ($script:MAX_WIDTH -gt 0 -and $width -gt $script:MAX_WIDTH) { return $false }
        if ($script:MIN_HEIGHT -gt 0 -and $height -lt $script:MIN_HEIGHT) { return $false }
        if ($script:MAX_HEIGHT -gt 0 -and $height -gt $script:MAX_HEIGHT) { return $false }
        if ($script:ASPECT_RATIO_FLOAT -gt 0) {
            $actualRatio = $width / $height
            $tolerance = 0.02
            if ($actualRatio -lt ($script:ASPECT_RATIO_FLOAT - $tolerance) -or $actualRatio -gt ($script:ASPECT_RATIO_FLOAT + $tolerance)) { return $false }
        }
        return $true
    }

    if ($script:DRY_RUN) {
        Write-Host "---- Available Posts ----"
        Write-Host "ID`tScore`tAuthor`tWidth`tHeight`tSize`tTags"
        $filtered | ForEach-Object {
            $sizeHuman = ConvertTo-HumanReadableSize -Bytes $_.file_size
            $tagsShort = if ($_.tags) { ($_.tags -join " ")[0..49] -join "" } else { "" }
            Write-Host "$($_.id)`t$($_.score)`t$($_.author)`t$($_.width)`t$($_.height)`t$sizeHuman`t$tagsShort"
        }
        return "DRY_RUN"
    }

    if ($filtered.Count -eq 0) {
        Write-Host "No suitable image found with the current filters."
        return $null
    }

    $selected = $filtered | Get-Random
    $imageUrl = $selected.file_url

    if ([string]::IsNullOrEmpty($imageUrl)) {
        Write-Host "No suitable image found."
        return $null
    }

    Write-Host "-> Downloading: $imageUrl"
    Log-Write -Level "INFO" -Message "Downloading image: $imageUrl"

    $ext = Get-ExtensionFromUrl -Url $imageUrl
    $outFileWithExt = "${OutFile}.${ext}"
    $tmpFile = "${outFileWithExt}.tmp"

    try {
        Invoke-WebRequest -Uri $imageUrl -OutFile $tmpFile -UseBasicParsing
    }
    catch {
        Write-Host "Error: download failed."
        Log-Error "Download failed: $imageUrl"
        if (Test-Path $tmpFile) { Remove-Item $tmpFile -Force }
        return $null
    }

    Move-Item $tmpFile $outFileWithExt -Force
    $fileSize = (Get-Item $outFileWithExt).Length
    Write-Host "-> Download complete ($(ConvertTo-HumanReadableSize $fileSize))"
    Log-Success "Image downloaded successfully: $outFileWithExt"
    
    return $imageUrl  # Return the URL so we can extract the extension correctly
}

# --- Wallpaper Setting ---
function Set-WindowsWallpaper {
    param([string]$ImagePath)

    if (-not (Test-Path $ImagePath)) {
        Write-Host "Error: Wallpaper file not found: $ImagePath"
        Log-Error "Wallpaper file not found: $ImagePath"
        return $false
    }

    $absolutePath = (Resolve-Path $ImagePath).Path

    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WallpaperSetter {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

    $result = [WallpaperSetter]::SystemParametersInfo(0x0014, 0, $absolutePath, 0x0001 -bor 0x0002)

    if ($result -ne 0) {
        Write-Host "Wallpaper set: $(Split-Path $absolutePath -Leaf)"
        Log-Success "Wallpaper set: $absolutePath"
        return $true
    }
    else {
        Write-Host "Error: Failed to set wallpaper"
        Log-Error "Failed to set wallpaper via SystemParametersInfo"
        return $false
    }
}

# --- Cache Management ---
function Get-CurrentWallpaper {
    # Search for ANY file starting with 'current.' regardless of extension
    $existing = Get-ChildItem -Path $script:CACHE_DIR -Filter "current.*" -File | Where-Object { $_.Extension -ne ".tmp" } | Select-Object -First 1
    if ($existing) {
        return $existing.FullName
    }
    return $null
}

function Preload-Wallpapers {
    $existing = (Get-ChildItem -Path "$script:PRELOAD_DIR\*" -File -Include "*.jpg", "*.gif", "*.webm", "*.png" -ErrorAction SilentlyContinue).Count
    $availableSlots = $script:MAX_PRELOAD_CACHE - $existing

    if ($availableSlots -le 0) {
        Write-Host "Preload cache full ($existing wallpapers)."
        return
    }

    $toPreload = [Math]::Min($script:PRELOAD_COUNT, $availableSlots)
    Write-Host "Preloading up to $toPreload wallpapers..."

    $jobs = @()
    for ($i = 1; $i -le $toPreload; $i++) {
        $tmpFile = Join-Path $script:PRELOAD_DIR "preload_$((Get-Random).ToString())"
        $job = Start-Job -ScriptBlock {
            param($BaseUrl, $PostEndpoint, $Tags, $Rating, $Order, $Limit, $Page, $MinScore, $Artist, $PoolId, $MaxFileSize, $MinFileSize, $MinWidth, $MaxWidth, $MinHeight, $MaxHeight, $AspectRatioFloat, $PreferredFormat, $AnimatedOnly, $OutFile, $CacheDir)

            $script:BASE_URL = $BaseUrl
            $script:POST_ENDPOINT = $PostEndpoint
            $script:TAGS = $Tags
            $script:RATING = $Rating
            $script:ORDER = $Order
            $script:LIMIT = $Limit
            $script:PAGE = $Page
            $script:MIN_SCORE = $MinScore
            $script:ARTIST = $Artist
            $script:POOL_ID = $PoolId
            $script:MAX_FILE_SIZE = $MaxFileSize
            $script:MIN_FILE_SIZE = $MinFileSize
            $script:MIN_WIDTH = $MinWidth
            $script:MAX_WIDTH = $MaxWidth
            $script:MIN_HEIGHT = $MinHeight
            $script:MAX_HEIGHT = $MaxHeight
            $script:ASPECT_RATIO_FLOAT = $AspectRatioFloat
            $script:PREFERRED_FORMAT = $PreferredFormat
            $script:ANIMATED_ONLY = $AnimatedOnly

            function ConvertTo-Bytes {
                param([string]$SizeStr)
                $SizeStr = $SizeStr.ToUpper()
                if ($SizeStr -match '^([0-9]+(\.[0-9]+)?)$') { return [long]$Matches[1] }
                elseif ($SizeStr -match '^([0-9]+(\.[0-9]+)?)KB$') { return [long]([double]$Matches[1] * 1024) }
                elseif ($SizeStr -match '^([0-9]+(\.[0-9]+)?)MB$') { return [long]([double]$Matches[1] * 1024 * 1024) }
                elseif ($SizeStr -match '^([0-9]+(\.[0-9]+)?)GB$') { return [long]([double]$Matches[1] * 1024 * 1024 * 1024) }
                else { return 0 }
            }
            function Get-ExtensionFromUrl {
                param([string]$Url)
                if ([string]::IsNullOrWhiteSpace($Url)) { return "jpg" }
                $ext = ($Url -split '\.')[-1]
                $ext = ($ext -split '\?')[0]
                switch -Regex ($ext) {
                    '^jpe?g$' { return "jpg" }
                    '^png$' { return "png" }
                    '^gif$' { return "gif" }
                    '^webm$' { return "webm" }
                    default { return "jpg" }
                }
            }

            $effectiveTags = if ($script:ANIMATED_ONLY) { "animated" } else { $script:TAGS }
            $encodedTags = $effectiveTags -replace ' ', '+'

            if (-not [string]::IsNullOrEmpty($script:POOL_ID)) {
                $apiUrl = "${script:BASE_URL}/pool/show.json?id=${script:POOL_ID}"
            }
            else {
                $apiUrl = "${script:BASE_URL}${script:POST_ENDPOINT}?limit=${script:LIMIT}&page=${script:PAGE}&tags=${encodedTags}+rating:${script:RATING}+order:${script:ORDER}"
                if (-not [string]::IsNullOrEmpty($script:MIN_SCORE)) { $apiUrl += "+score:>=$($script:MIN_SCORE)" }
                if (-not [string]::IsNullOrEmpty($script:ARTIST)) { $apiUrl += "+user:$($script:ARTIST)" }
            }

            try {
                $posts = Invoke-RestMethod -Uri $apiUrl -Method Get
            }
            catch { return $false }

            if ($posts -isnot [System.Array]) {
                if ($posts.posts) { $posts = @($posts.posts) } else { $posts = @($posts) }
            }

            $maxBytes = ConvertTo-Bytes -SizeStr $script:MAX_FILE_SIZE
            $minBytes = if ($script:MIN_FILE_SIZE) { ConvertTo-Bytes -SizeStr $script:MIN_FILE_SIZE } else { 0 }

            $filtered = $posts | Where-Object {
                $fileSize = $_.file_size; $width = $_.width; $height = $_.height
                if ($null -eq $fileSize -or $null -eq $width -or $null -eq $height) { return $false }
                if ($maxBytes -gt 0 -and $fileSize -gt $maxBytes) { return $false }
                if ($minBytes -gt 0 -and $fileSize -lt $minBytes) { return $false }
                if ($script:MIN_WIDTH -gt 0 -and $width -lt $script:MIN_WIDTH) { return $false }
                if ($script:MAX_WIDTH -gt 0 -and $width -gt $script:MAX_WIDTH) { return $false }
                if ($script:MIN_HEIGHT -gt 0 -and $height -lt $script:MIN_HEIGHT) { return $false }
                if ($script:MAX_HEIGHT -gt 0 -and $height -gt $script:MAX_HEIGHT) { return $false }
                if ($script:ASPECT_RATIO_FLOAT -gt 0) {
                    $actualRatio = $width / $height; $tolerance = 0.02
                    if ($actualRatio -lt ($script:ASPECT_RATIO_FLOAT - $tolerance) -or $actualRatio -gt ($script:ASPECT_RATIO_FLOAT + $tolerance)) { return $false }
                }
                return $true
            }

            if ($filtered.Count -eq 0) { return $false }
            $selected = $filtered | Get-Random
            $imageUrl = $selected.file_url
            if ([string]::IsNullOrEmpty($imageUrl)) { return $false }

            $ext = Get-ExtensionFromUrl -Url $imageUrl
            $outFileWithExt = "${OutFile}.${ext}"
            $tmpFile = "${outFileWithExt}.tmp"

            try {
                Invoke-WebRequest -Uri $imageUrl -OutFile $tmpFile -UseBasicParsing
                Move-Item $tmpFile $outFileWithExt -Force
                return $true
            }
            catch { return $false }
        } -ArgumentList @(
            $script:BASE_URL, $script:POST_ENDPOINT, $script:TAGS, $script:RATING, $script:ORDER,
            $script:LIMIT, $script:PAGE, $script:MIN_SCORE, $script:ARTIST, $script:POOL_ID,
            $script:MAX_FILE_SIZE, $script:MIN_FILE_SIZE, $script:MIN_WIDTH, $script:MAX_WIDTH,
            $script:MIN_HEIGHT, $script:MAX_HEIGHT, $script:ASPECT_RATIO_FLOAT, $script:PREFERRED_FORMAT,
            $script:ANIMATED_ONLY, $tmpFile, $script:CACHE_DIR
        )
        $jobs += $job
        Start-Sleep -Milliseconds 300
    }

    $jobs | Wait-Job | Out-Null
    $completed = $jobs | Where-Object { $_.State -eq "Completed" -and (Receive-Job $_) -eq $true } | Measure-Object | Select-Object -ExpandProperty Count
    $jobs | Remove-Job -Force

    Write-Host "Preloading finished. Successfully preloaded $completed wallpaper(s)."
}

function Select-NextWallpaper {
    $files = Get-ChildItem -Path "$script:PRELOAD_DIR\*" -File -Include "*.jpg", "*.gif", "*.webm", "*.png" -ErrorAction SilentlyContinue
    if ($files.Count -eq 0) { return $null }

    $next = $files | Get-Random
    $ext = Get-ExtensionFromUrl -Url $next.Name
    
    # Cleanup any existing current files first to avoid duplicates with different extensions
    Get-ChildItem -Path $script:CACHE_DIR -Filter "current.*" -File | Remove-Item -Force

    $currentWallpaper = Join-Path $script:CACHE_DIR "current.$ext"
    Move-Item $next.FullName $currentWallpaper -Force
    return $currentWallpaper
}

function Run-CacheCleanup {
    Write-Host "[WARNING] Cleaning preload cache folders in: $($script:CACHE_DIR)"
    if (-not $script:FORCE_CLEAN) {
        $confirm = Read-Host "Are you sure? This will delete all preloaded wallpapers but keep the current one. (y/N)"
        if ($confirm -ne "y" -and $confirm -ne "Y") {
            Write-Host "Aborted."
            exit 0
        }
    }
    Get-ChildItem -Path $script:CACHE_DIR -Directory -Filter "preload_*" | Remove-Item -Recurse -Force
    Write-Host "[SUCCESS] Preload cache cleaned."
    exit 0
}

# --- Discovery Functions ---
function Discover-Tags {
    param([string]$Pattern = "", [string]$Order = "count", [int]$Limit = $script:DISCOVER_LIMIT)
    $apiUrl = "${script:BASE_URL}/tag.json?order=${Order}&limit=${Limit}"
    if ($Pattern) { $apiUrl += "&name_pattern=${Pattern}" }
    try {
        $tags = Invoke-RestMethod -Uri $apiUrl -Method Get
        $tags | Sort-Object count -Descending | Select-Object -First $Limit | ForEach-Object {
            Write-Host "$($_.name) ($($_.count) posts)"
        }
        if ($script:EXPORT_TAGS) {
            $tagsList = $tags | Select-Object -First $Limit -ExpandProperty name
            $tagsList | Set-Content -Path $script:EXPORTED_TAGS_FILE -Force
            Write-Host "Exported $($tagsList.Count) tags."
        }
    }
    catch { Write-Host "Error: Failed to fetch tags" }
}

function Discover-Artists {
    param([string]$Pattern = "", [int]$Limit = $script:DISCOVER_LIMIT)
    $apiUrl = "${script:BASE_URL}/artist.json?order=name&limit=${Limit}"
    if ($Pattern) { $apiUrl += "&name=${Pattern}" }
    try {
        $artists = Invoke-RestMethod -Uri $apiUrl -Method Get
        $artists | Select-Object -First $Limit -ExpandProperty name
    }
    catch { Write-Host "Error: Failed to fetch artists" }
}

function List-Pools {
    param([string]$Query = "", [int]$Limit = $script:DISCOVER_LIMIT)
    $apiUrl = "${script:BASE_URL}/pool.json?limit=${Limit}"
    if ($Query) { $apiUrl += "&query=${Query}" }
    try {
        $pools = Invoke-RestMethod -Uri $apiUrl -Method Get
        $pools | Select-Object -First $Limit | ForEach-Object {
            Write-Host "$($_.id): $($_.name) ($($_.post_count) posts)"
        }
    }
    catch { Write-Host "Error: Failed to fetch pools" }
}

# --- Favorites Functions ---
function Save-ToFavorites {
    $source = Get-CurrentWallpaper
    if (-not $source -or -not (Test-Path $source)) {
        Write-Host "Error: No current wallpaper found."
        return $false
    }
    if (-not (Test-Path $script:FAVORITES_DIR)) { New-Item -ItemType Directory -Path $script:FAVORITES_DIR -Force | Out-Null }
    $ext = Get-ExtensionFromUrl -Url $source
    $dest = Join-Path $script:FAVORITES_DIR "wallpaper_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').${ext}"
    try {
        Copy-Item $source $dest -Force
        Write-Host "Saved: $dest"
        return $true
    }
    catch { return $false }
}

function List-Favorites {
    if (-not (Test-Path $script:FAVORITES_DIR)) { return }
    $wallpapers = Get-ChildItem -Path $script:FAVORITES_DIR -File -Include "*.jpg", "*.png", "*.gif", "*.webm"
    $wallpapers | ForEach-Object { Write-Host "  $($_.Name)  ($(ConvertTo-HumanReadableSize -Bytes $_.Length))" }
}

function Set-FromFavorites {
    if (-not (Test-Path $script:FAVORITES_DIR)) { return }
    $wallpapers = Get-ChildItem -Path $script:FAVORITES_DIR -File -Include "*.jpg", "*.png", "*.gif", "*.webm"
    if ($wallpapers.Count -eq 0) { return }
    $selected = $wallpapers | Get-Random
    Set-WindowsWallpaper -ImagePath $selected.FullName
}

function Display-Help {
    $helpText = @"
Usage: konapaper.bat [options]
  -t, --tags <tags>          Search tags
  -R, --random-tags <n>      Select random tags from config
  -D, --discover-tags        Show popular tags
  -o, --order <o>            random, score, date
  -l, --limit <n>            Default: 50
  -p, --page <p>             Number, 'random', or 'MIN-MAX'
  -s, --max-file-size <sz>   e.g. 2MB
  --aspect-ratio <r>         e.g. 16:9
  --fav                      Save current to favorites
  --from-favs                Set random from favorites
  -cc, --clean-cache         Clean preload folders
"@
    Write-Host $helpText
}

function Parse-CliArgs {
    $args = $script:UserArgs
    $i = 0
    while ($i -lt $args.Count) {
        $arg = $args[$i]
        switch ($arg) {
            { $_ -in @("-t", "--tags") } { $script:TAGS = $args[++$i] }
            { $_ -in @("-l", "--limit") } { $script:LIMIT = [int]$args[++$i] }
            { $_ -in @("-p", "--page") } {
                $parsedPage = Parse-PageArgument -Arg $args[++$i]
                if ($parsedPage) { $script:PAGE = $parsedPage } else { exit 1 }
            }
            { $_ -in @("-r", "--rating") } { $script:RATING = $args[++$i] }
            { $_ -in @("-o", "--order") } { $script:ORDER = $args[++$i] }
            { $_ -in @("-s", "--max-file-size") } { $script:MAX_FILE_SIZE = $args[++$i] }
            { $_ -in @("-z", "--min-file-size") } { $script:MIN_FILE_SIZE = $args[++$i] }
            "--min-width" { $script:MIN_WIDTH = [int]$args[++$i] }
            "--max-width" { $script:MAX_WIDTH = [int]$args[++$i] }
            "--min-height" { $script:MIN_HEIGHT = [int]$args[++$i] }
            "--max-height" { $script:MAX_HEIGHT = [int]$args[++$i] }
            "--aspect-ratio" { $script:ASPECT_RATIO = $args[++$i] }
            { $_ -in @("-m", "--min-score") } { $script:MIN_SCORE = $args[++$i] }
            { $_ -in @("-a", "--artist") } { $script:ARTIST = $args[++$i] }
            { $_ -in @("-P", "--pool") } { $script:POOL_ID = $args[++$i] }
            { $_ -in @("-f", "--format") } { $script:PREFERRED_FORMAT = $args[++$i] }
            "--dry-run" { $script:DRY_RUN = $true }
            { $_ -in @("-D", "--discover-tags") } { $script:DISCOVER_TAGS = $true }
            { $_ -in @("-A", "--discover-artists") } { $script:DISCOVER_ARTISTS = $true }
            { $_ -in @("-L", "--list-pools") } { $script:LIST_POOLS = $true }
            { $_ -in @("-S", "--search-pools") } { $script:SEARCH_POOLS = $args[++$i]; $script:LIST_POOLS = $true }
            { $_ -in @("-R", "--random-tags") } { $script:RANDOM_TAGS_COUNT = [int]$args[++$i] }
            { $_ -in @("-E", "--export-tags") } { $script:EXPORT_TAGS = $true }
            { $_ -in @("-cc", "--clean-cache") } { $script:CLEAN_MODE = $true }
            { $_ -in @("-cf", "--clean-force") } { $script:CLEAN_MODE = $true; $script:FORCE_CLEAN = $true }
            { $_ -in @("-h", "--help") } { Display-Help; exit 0 }
            "--fav" { $script:FAV_MODE = $true }
            "--list-favs" { $script:LIST_FAVS = $true }
            "--from-favs" { $script:FROM_FAVS = $true }
            "--animated-only" { $script:ANIMATED_ONLY = $true }
            default { Write-Host "Unknown: $arg"; exit 1 }
        }
        $i++
    }
}

# --- Main Execution ---
$script:UserArgs = @($args)
Load-Config
$script:PREFERRED_FORMAT = if ($script:PREFERRED_FORMAT) { $script:PREFERRED_FORMAT } else { "auto" }
Log-Init
Parse-CliArgs
Process-RandomTags

$script:ASPECT_RATIO_FLOAT = if ($script:ASPECT_RATIO) { Parse-AspectRatio -Ratio $script:ASPECT_RATIO } else { 0 }

if (-not (Test-Path $script:CACHE_DIR)) { New-Item -ItemType Directory -Path $script:CACHE_DIR -Force | Out-Null }
$script:PRELOAD_DIR = Join-Path $script:CACHE_DIR "preload_$($script:RATING)"
if (-not (Test-Path $script:PRELOAD_DIR)) { New-Item -ItemType Directory -Path $script:PRELOAD_DIR -Force | Out-Null }

if ($script:CLEAN_MODE) { Run-CacheCleanup }

$mutexName = "Global\konapaper_setter_mutex"
$script:Mutex = New-Object System.Threading.Mutex($false, $mutexName, [ref]$false)
if (-not $script:Mutex.WaitOne(0)) { exit 1 }

try {
    if ($script:FAV_MODE) { Save-ToFavorites; exit 0 }
    if ($script:LIST_FAVS) { List-Favorites; exit 0 }
    if ($script:FROM_FAVS) { Set-FromFavorites; exit 0 }
    if ($script:DISCOVER_TAGS) { Discover-Tags; exit 0 }
    if ($script:DISCOVER_ARTISTS) { Discover-Artists; exit 0 }
    if ($script:LIST_POOLS) { List-Pools -Query $script:SEARCH_POOLS; exit 0 }

    Write-Host "Starting wallpaper selection..."
    $nextWall = Select-NextWallpaper
    
    if ($nextWall) {
        Set-WindowsWallpaper -ImagePath $nextWall
    }
    else {
        Write-Host "No cached wallpapers found; downloading..."
        $tempBase = Join-Path $script:CACHE_DIR "current"
        $downloadUrl = Download-Wallpaper -OutFile $tempBase
        
        if ($downloadUrl -eq "DRY_RUN") { exit 0 }
        
        if ($downloadUrl) {
            $ext = Get-ExtensionFromUrl -Url $downloadUrl
            $finalWallpaper = Join-Path $script:CACHE_DIR "current.${ext}"
            Set-WindowsWallpaper -ImagePath $finalWallpaper
        }
        else {
            Write-Host "Failed to fetch wallpaper."
            exit 1
        }
    }

    Preload-Wallpapers
    Write-Host "Done."
}
finally {
    $script:Mutex.ReleaseMutex()
    $script:Mutex.Dispose()
}