#Set-WSUSReportersPermissions

$WSUSServers = Get-ADComputer -Filter 'Name -like "*UPDMG*" -or Name -like "*GCUPD*"'
$localGroup = "WSUS Reporters"
$domainGroup = "Desktop Support"
$domain = "gcserv.com"


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
