# Define the URL to download Google Chrome if it is not installed
$chromeInstallerUrl = "https://dl.google.com/chrome/install/375.126/chrome_installer.exe"
$chromeInstallerPath = "$env:TEMP\chrome_installer.exe"

# Check if Chrome is installed
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-Not (Test-Path $chromePath)) {
    # Download the Chrome installer
    Invoke-WebRequest -Uri $chromeInstallerUrl -OutFile $chromeInstallerPath

    # Install Chrome silently
    Start-Process -FilePath $chromeInstallerPath -ArgumentList "/silent /install" -Wait

    # Clean up the installer file
    Remove-Item $chromeInstallerPath
}

# Set Chrome as the default browser in Windows 11
$chromeAppId = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe").'(Default)'
if ($chromeAppId -eq $null) {
    $chromeAppId = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe").'(Default)'
}

if ($chromeAppId -ne $null) {
    $chromeAppId = [System.Uri]::EscapeDataString($chromeAppId)

    # Set Chrome as the default handler for various protocols and file types
    $assocList = @(
        "HTTP",
        "HTTPS",
        ".htm",
        ".html"
    )

    foreach ($assoc in $assocList) {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-Command Set-DefaultAppAssociation -ProgId 'Google.Chrome' -ExtensionOrProtocol $assoc" -NoNewWindow -Wait
    }

    # Set Chrome as the default browser
    $json = @{
        "declaration" = @{
            "@xmlns" = "http://schemas.microsoft.com/AssignedAccess/2015"
            "Properties" = @{
                "DefaultBrowser" = "Google.Chrome"
            }
        }
    } | ConvertTo-Json -Compress

    $json | Out-File -FilePath "$env:LOCALAPPDATA\Microsoft\Windows\DefaultAssociationsConfiguration.json"

    & "$env:WINDIR\System32\dism.exe" /Online /Import-DefaultAppAssociations:"$env:LOCALAPPDATA\Microsoft\Windows\DefaultAssociationsConfiguration.json"
}

Write-Output "Google Chrome is set as the default browser."
