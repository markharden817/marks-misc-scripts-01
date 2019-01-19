#Set-WSUSReportersPermissions

$WSUSServers = Get-ADComputer -Filter 'Name -like "*WSUS*" -or Name -like "*UPD*"'
$localGroup = "WSUS Reporters"
$domainGroup = "Desktop Support"
$domain = "sample.com"


$WSUSServers.Name | %{
    Try {
        Write-Host "Setting Permissions on $_"
        $dg = [ADSI]"WinNT://$domain/$domainGroup,group" 
        $lg = [ADSI]"WinNT://$_/$localGroup,group"  
        $lg.Add($dg.Path) 
    } Catch {
        Write-Warning "$_" 
    }
}
