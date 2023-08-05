param(
    [string]$zoneId = "",
    [string]$subnet = "",
    [string]$ipAddressEnding = "250",
    [string]$prefixLength = "24"
)

if($zoneId -eq ""){
    $adapterChoices = [System.Management.Automation.Host.ChoiceDescription[]] (Get-NetAdapter | Select-Object -ExpandProperty Name | ForEach-Object {
        New-Object System.Management.Automation.Host.ChoiceDescription "$_"
    }) 
    $count=0

    $networkAdapters = Get-NetAdapter

    foreach($adapter in $networkAdapters){
        Write-Host "$($count): $($adapter.Name) | $($adapter.InterfaceDescription) | $($adapter.Status)"
        $count+=1
    }
    Write-Host ""
            
    $input = Read-Host -Prompt "Select the network interface to use"
    $interfaceIp = $networkAdapters[$input]
    $zoneId = $interfaceIp.ifIndex
}

if($subnet -eq ""){

    $count=0
    $subnetOptions = @('None', 'DHCP', '0', '10', '20')
    foreach($subnetOption in $subnetOptions){
        Write-Host "$($count): $subnetOption"
        $count+=1
    }

    $option = Read-Host -Prompt "Select subnet option to use"
    $subnet = $subnetOptions[$option]	
}

# DHCP
if( $subnet.ToLower() -eq "dhcp" -or $subnet.ToLower() -eq "d" -or $subnet.ToLower() -eq "dynamic"){
    Set-NetIPInterface -InterfaceIndex $zoneId -AddressFamily IPv4 -DHCP Enabled 
    return
}

# None
if($subnet.ToLower() -eq "none"){
    $subnet = Read-Host -Prompt "Enter subnet (f.E. 0 or 10 or 20)"

    if($subnet -gt 255 -or $subnet -lt 0){
        Write-Host "Subnet must be between 0 and 255"
        return
    }
}

$ipAddress =  "192.168.$subnet.$ipAddressEnding"
""
"Ip address = $ipAddress"
"Prefix length = $prefixLength"


Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $zoneId | Remove-NetIpAddress -Confirm:$false

New-NetIpAddress -AddressFamily IPv4 -InterfaceIndex $zoneId $ipAddress -PrefixLength $prefixLength 
