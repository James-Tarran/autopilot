$ProgressPreference = 'SilentlyContinue'
# Configure 
Set-NetConnectionProfile -NetworkCategory Private
winrm quickconfig -quiet

# Get tenant ID
Install-PackageProvider NuGet -force -ErrorAction SilentlyContinue
Import-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
install-module Microsoft.Graph.Authentication -Force -scope CurrentUser -ErrorAction SilentlyContinue -Confirm:$false
install-module Microsoft.Graph.Identity.DirectoryManagement -force -scope CurrentUser -ErrorAction SilentlyContinue -Confirm:$false
import-module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue -force
import-module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction SilentlyContinue -force
Connect-MgGraph
$TenantID = (Get-MgOrganization).id

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
    # Report an error when the hash isn't available
    Write-Error -Message "Unable to retrieve device hardware data (hash) from computer" -Category DeviceError
}

$computers += $c
Write-Host "Gathered details for device with serial number: $serial"
$computers

Remove-CimSession $session
