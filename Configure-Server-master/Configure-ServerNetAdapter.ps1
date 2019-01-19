$NetAdapter = Get-NetAdapter | ?{$_.InterfaceDescription -notlike "*Loopback*"} | select ifIndex, Name, InterfaceDescription, Status, MacAddress, LinkSpeed | FT


function Main 
    {
    cls
    Write-Host "==================================================="
    Write-Host "              Configure NetAdapter                 "
    Write-Host "==================================================="
    Write-Host "`n"
    Write-Host "Current Settings:"
    $NetAdapter 
	
	Write-Host "Consistent Value: GC_Default for Default VLAN or VLAN 210 for Development"
	Write-Host ""
    $newInterfaceAlias = Read-Host -Prompt "New Interface Name "
    Get-NetAdapter | ?{$_.InterfaceDescription -notlike "*Loopback*"} | Rename-NetAdapter -NewName $newInterfaceAlias # -Name $($NetAdapter.Name) 
    #Set NetAdapterRSS
    Get-NetAdapterRss | ?{$_.Enabled -eq $false} | Set-NetAdapterRss -Enabled $true
    #Set NetAdapter Power Management
    Get-NetAdapterPowerManagement | ?{$_.WakeOnMagicPacket -eq "Enabled" -or $_.WakeOnPattern -eq  "Enabled"} | Set-NetAdapterPowerManagement -WakeOnMagicPacket Disabled -WakeOnPattern Disabled

#Set NetAdapterRSS
    Get-NetAdapterRss | ?{$_.Enabled -eq $false} | Set-NetAdapterRss -Enabled $true
#Set NetAdapter Power Management
    Get-NetAdapterPowerManagement | ?{$_.WakeOnMagicPacket -eq "Enabled" -or $_.WakeOnPattern -eq  "Enabled"} | Set-NetAdapterPowerManagement -WakeOnMagicPacket Disabled -WakeOnPattern Disabled
#Disable IPV6    
    Write-Host "Remove IPv6 (NIC options)"
    Set-ItemProperty -path HKLM:\SYSTEM\CurrentControlSet\services\TCPIP6\Parameters -type DWORD -name DisabledComponents -value 0xff -force

    }
   
main
sleep 5;
