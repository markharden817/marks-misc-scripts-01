
Param(
    [Parameter(Mandatory=$True,Position=1)][string]$ComputerName
    )

Import-Module ActiveDirectory,DNSServer
﻿
$PDCE = Get-ADDomainController -Discover -Service PrimaryDC
$DNSZones = Get-DnsServerZone -ComputerName $PDCE | ? {$_.IsDsIntegrated -eq $True}
$DNSZones | ForEach-Object {
    Try {$_ | Remove-DNSServerResourceRecord –Name "@" –RRType NS –RecordData $ComputerName -ComputerName $PDCE -Force -Verbose}
    Catch{[System.Exception] "UH oh..got an error"}
    }
