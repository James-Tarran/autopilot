$ProgressPreference = 'SilentlyContinue'
function CountDown() {
    param($timeSpan)

    $spinner = @('|', '/', '-', '\')
    $colours = @("Red", "DarkRed", "Magenta", "DarkMagenta", "Blue", "DarkBlue", "Cyan", "DarkCyan", "Green", "DarkGreen", "Yellow", "DarkYellow", "White", "Gray", "DarkGray", "Black")
    $colourIndex = 0

    while ($timeSpan -gt 0)
        {
            foreach ($spin in $spinner) {
                Write-Host "`r$spin" -NoNewline -ForegroundColor $colours[$colourIndex]
                Start-Sleep -Milliseconds 90
            }
            $colourIndex++
            if ($colourIndex -ge $colours.Length) {
                $colourIndex = 0
            }
            $timeSpan = $timeSpan - 1
        }
}
# Configure 
Set-NetConnectionProfile -NetworkCategory Private | out-null
winrm quickconfig -quiet | out-null

# Get tenant ID
Install-PackageProvider NuGet -force -ErrorAction SilentlyContinue | out-null
Import-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | out-null
install-module Microsoft.Graph.Authentication -Force -scope CurrentUser -ErrorAction SilentlyContinue -Confirm:$false | out-null
install-module Microsoft.Graph.Identity.DirectoryManagement -force -scope CurrentUser -ErrorAction SilentlyContinue -Confirm:$false | out-null
import-module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue -force | out-null
import-module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction SilentlyContinue -force | out-null
Connect-MgGraph -nowelcome
$TenantID = (Get-MgOrganization).id
disconnect-mggraph | out-null

# Initialise
$bad = $false
$computers = @()

# Get a CIM session
$session = New-CimSession

# Get the common properties.
Write-Verbose "Checking serial number"
$serial = (Get-CimInstance -CimSession $session -Class Win32_BIOS).SerialNumber

# Get the hash (if available)
$devDetail = (Get-CimInstance -CimSession $session -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'")
if ($devDetail -and (-not $Force)){
    $hash = $devDetail.DeviceHardwareData
} else {
    $bad = $true
    $hash = ""
}

# Getting the PKID is generally problematic for anyone other than OEMs, so let's skip it here
$product = ""

# Create a pipeline object
$c = New-Object psobject -Property @{
    "Device Serial Number" = $serial
    "Windows Product ID" = $product
    "Hardware Hash" = $hash
    "tenant ID" = $TenantID
}

# Write the object to the pipeline or array
if ($bad) {
    # Report an error when the hash isn't availacable
    Write-Error -Message "Unable to retrieve device hardware data (hash) from computer" -Category DeviceError
}

$computers += $c
Write-Host "Gathered details for device; please allow 60 minutes for processing, then restart your device.`nIf you are still not prompted to sign in with your corporate account after 60 minutes, please contact technicalsupport@techary.com"
countdown 3600
Write-host "Please now restart your computer"
$computers

Remove-CimSession $session
