# Check arg
if (-not ($args[0])){
    echo "Usage: run.ps1 PLATFORM-NAME"
    echo "Platforms: android, ios, windows, macos, linux, web"
    return
}
if (Test-Path -Path "./platforms/modules-$($args[0])" -PathType Container){
    echo "Using platform $($args[0])"
    echo "Copying platform files over to 'modules' dir..."
}
else{
    echo "No such platform at 'platforms/modules-$($args[0])'"
}

# Copy files
$files = Get-ChildItem -Path "./platforms/modules-$($args[0])/*" -File -recurse

foreach ($file in $files) {
    Write-Host "Found file: $($file.FullName)"

    # Make lowdash after file name
    $absPath = $($file.FullName)
    $newPath = Resolve-Path -Path $absPath -Relative
    $newPath = $newPath -replace "\.dart", "_.dart"
    $newPath = $newPath -replace "\\platforms", ""
    $newPath = $newPath -replace "-$($args[0])", ""
    echo "Copying to: $newPath"

    # Make target folder path
    $destFolder = Split-Path -Path $newPath -Parent
    
    if (-not (Test-Path -Path $destFolder -PathType Container)) {
        New-Item -Path $destFolder -ItemType Directory -Force | Out-Null
    }

    # Copy
    Copy-Item -Path $absPath -Destination $newPath -Force
}

# Run Dart
echo ""
dart app.dart 
