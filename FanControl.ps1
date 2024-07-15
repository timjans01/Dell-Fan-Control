# Description: This script is used to control the fans manually on a Dell server
# Tested on Dell T620, R730XD and R630
# 

$ipmiPath = "$env:APPDATA\DellFanControl\ipmitool"
$ipmiExe = "$ipmiPath\ipmitool.exe"

$IPMIURL = "https://www.dannynieuwenhuis.nl/downloads/ipmitool.zip"

$ipmiConfig = "$PSScriptRoot\ipmi.config"

# Check if ipmitool is installed
if(-not (Test-Path "$ipmiPath\ipmitool.exe")) {
    Write-Host "IPMI not found in expected directory. Downloading IPMI..." -ForegroundColor Yellow
    curl -o "$PSScriptRoot\temp.zip" $IPMIURL
    Expand-Archive -Path "$PSScriptRoot\temp.zip" -DestinationPath $ipmiPath\..
    Write-Host "IPMI downloaded and installed in $ipmiPath" -ForegroundColor Green
    remove-item "$PSScriptRoot\temp.zip"
}

if(-not (Test-Path $ipmiConfig)) {
    Write-Host "IPMI config not found." -ForegroundColor Yellow
    $ipmiLoginName = Read-Host "Enter the IPMI username(IDRAC username)"
    $ipmiLoginPassword = Read-Host "Enter the IPMI password(IDRAC password)"
    $ipmiServerIP = Read-Host "Enter the IPMI IP address(IDRAC IP address)"

    # Check if the IPMI IP is valid, if not, ask again
    while(-not ($ipmiServerIP -as [ipaddress])) {
        Write-Host "Invalid IP address" -ForegroundColor Red
        $ipmiServerIP = Read-Host "Enter the IPMI IP address(IDRAC IP address)"
    }

    # Create the config file and load values as json
    $ipmiConfigContent = @"
{
    "ipmiLoginName": "$ipmiLoginName",
    "ipmiLoginPassword": "$ipmiLoginPassword",
    "ipmiServerIP": "$ipmiServerIP"
}
"@ 
    $ipmiConfigContent | Out-File $ipmiConfig

    
    Write-Host "IPMI config created in $ipmiConfig" -ForegroundColor Green
}

# Load the config file
$ipmiConfigContent = Get-Content $ipmiConfig | ConvertFrom-Json

$ipmiLoginName = $ipmiConfigContent.ipmiLoginName
$ipmiLoginPassword = $ipmiConfigContent.ipmiLoginPassword
$ipmiServerIP = $ipmiConfigContent.ipmiServerIP

Write-Host "IPMI config loaded! IP: $ipmiServerIP, Username: $ipmiLoginName" -ForegroundColor Green

# Test if the IPMI server is reachable
if(-not (Test-Connection -ComputerName $ipmiServerIP -Count 1 -Quiet)) {
    Write-Host "IPMI server not reachable" -ForegroundColor Red
    exit
}

#test if the IPMI credentials are correct
$ipmiTest = & $ipmiExe -I lanplus -H $ipmiServerIP -U $ipmiLoginName -P $ipmiLoginPassword chassis status
if($LASTEXITCODE -ne 0) {
    Write-Host "IPMI credentials are incorrect or IPMI is disabled!" -ForegroundColor Red
    Write-Host "To check if IPMI is enabled, go to the IDRAC web interface, go to IDRAC settings > Network and enable IPMI over LAN." -ForegroundColor Yellow
    exit
}
else {
    Write-Host "Connected to server." -ForegroundColor Green
}

# Get current speed of all the fans and display them all together in a table
$fanSpeeds = & $ipmiExe -I lanplus -H $ipmiServerIP -U $ipmiLoginName -P $ipmiLoginPassword sdr type fan | Select-String -Pattern "Fan" | ForEach-Object { $_ -replace ".*Fan \d+.*\s(\d+)%.*",'$1' }
$fanSpeeds = $fanSpeeds | ForEach-Object { [PSCustomObject]@{Fan = $_} }
Write-Host "Current fan speeds:"
$fanSpeeds | Format-Table -AutoSize


$manualControl = Read-Host "Do you want to manually control the fans? (y/n)"
if ($manualControl -eq "y") {
    $fanSpeed = Read-Host "Enter the fan speed in percentage (0-100)"
    while (-not [int]::TryParse($fanSpeed, [ref]$null) -or [int]$fanSpeed -lt 0 -or [int]$fanSpeed -gt 100) {
        Write-Host "Invalid fan speed" -ForegroundColor Red
        $fanSpeed = Read-Host "Enter the fan speed in percentage (0-100)"
    }

    # Convert fan speed to hex
    $hexFanSpeed = "{0:x2}" -f [int]$fanSpeed

    # Set the fan speed
    & $ipmiExe -I lanplus -H $ipmiServerIP -U $ipmiLoginName -P $ipmiLoginPassword raw 0x30 0x30 0x01 0x00
    & $ipmiExe -I lanplus -H $ipmiServerIP -U $ipmiLoginName -P $ipmiLoginPassword raw 0x30 0x30 0x02 0xff 0x$hexFanSpeed
    Write-Host "Fan speed set to $fanSpeed%" -ForegroundColor Green
} else {
    & $ipmiExe -I lanplus -H $ipmiServerIP -U $ipmiLoginName -P $ipmiLoginPassword raw 0x30 0x30 0x01 0x01
    Write-Host "Exiting..." -ForegroundColor Yellow
}
