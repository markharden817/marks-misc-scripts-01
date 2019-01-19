# .\Get-WSUSReport_v2.ps1 -WSUSServer hgopagcupd01.gcserv.com -EmailTo mark.harden@gcserv.com -WSUSGroup Desktops
$Outfile = "./DesktopsConfig.json"


$WSUSServers = @()
(Get-ADComputer -Filter 'Name -like "*pagcupd*" -or Name -like"*paupdmg*"').DNSHostName | %{
    $obj = New-Object System.Object
    $obj | Add-Member -type NoteProperty -name WSUSServer -Value $_
    $obj | Add-Member -type NoteProperty -name Port -Value "8530"
    $obj | Add-Member -type NoteProperty -name UseSSL -Value $false
    $obj | Add-Member -type NoteProperty -name EmailTo -Value "Mark.Harden@gcserv.com"
    $WSUSServers += $obj
}
$WSUSServers | ConvertTo-Json | Out-File $Outfile

