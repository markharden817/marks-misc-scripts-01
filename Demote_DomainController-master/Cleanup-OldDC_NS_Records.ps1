Import-Module ActiveDirectory,DNSServer

$oldDNSServer = "<Old_DC_FQDN>"
$PDCE = Get-ADDomainController -Discover -Service PrimaryDC
$DNSZones = Get-DnsServerZone -ComputerName $PDCE | ? {$_.IsDsIntegrated -eq $True}
$DNSZones | ForEach-Object {
    Try {$_ | Remove-DNSServerResourceRecord –Name "@" –RRType NS –RecordData $oldDNSServer -ComputerName $PDCE -Force -Verbose}
    Catch{[System.Exception] "UH oh..got an error"}
    }