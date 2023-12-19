param(
    [Parameter(Mandatory=$true)]
    [string]$new_ip,

    [Parameter(Mandatory=$true)]
    [string]$new_gateway
)

# Getting all active network interfaces
$interfaces = Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway -ne $null}

if ($interfaces.Count -eq 0) {
    Write-Error "No active network interfaces found."
    exit
}

if ($interfaces.Count -gt 1) {
    Write-Host "Multiple active network adapters found. Please select an adapter to change IP and gateway:"
    $i = 1
    foreach ($interface in $interfaces) {
        Write-Host "$i. Adapter with IP: $($interface.IPv4Address.IPAddress)"
        $i++
    }
    $selectedInterfaceIndex = Read-Host "Enter the adapter number (1 or 2)"

    if ($selectedInterfaceIndex -ne "1" -and $selectedInterfaceIndex -ne "2") {
        Write-Error "Invalid adapter choice. Script is terminating."
        exit
    }

    $interface = $interfaces[$selectedInterfaceIndex - 1]
} else {
    $interface = $interfaces[0]
}

# Displaying current IP address and gateway
$current_ip = $interface.IPv4Address.IPAddress
$current_gateway = $interface.IPv4DefaultGateway.NextHop
Write-Host "Current IP address: $current_ip"
Write-Host "Current gateway: $current_gateway"

# Delay
Start-Sleep -Seconds 3

$interfaceIndex = $interface.InterfaceIndex

# Removing the old IP address and gateway
Remove-NetIPAddress -InterfaceIndex $interfaceIndex -Confirm:$false
Remove-NetRoute -InterfaceIndex $interfaceIndex -DestinationPrefix "0.0.0.0/0" -Confirm:$false

# Setting the new IP address
New-NetIPAddress -InterfaceIndex $interfaceIndex -IPAddress $new_ip -PrefixLength 24

# Setting the new default gateway
New-NetRoute -InterfaceIndex $interfaceIndex -DestinationPrefix "0.0.0.0/0" -NextHop $new_gateway

# Displaying the new IP address and gateway
Write-Host "New IP address: $new_ip"
Write-Host "New gateway: $new_gateway"
