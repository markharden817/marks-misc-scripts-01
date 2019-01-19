<#
.SYNOPSIS

Promotes New DC.

.DESCRIPTION

Promotes and configures Domain Controller to new system.

.EXAMPLE

C:\PS> Promote-GC_Domain_Controller.ps1 -Site "SAN" -hardenedTLS $True -TestPromote $True

#>

param (
    	[Parameter(Mandatory=$true)][string]$Site,
		[Parameter(Mandatory=$true)][bool]$hardenedTLS,
		[Parameter(Mandatory=$true)][bool]$TestPromote
)

#-----------------------------------------------------------

$ReplicationSourceDC="$($Site)PNMSADC01.gcserv.com"

#Configure TLS Settings
if ($hardenedTLS){
	Write-host "Configuing TLS settings in accordance with InScope-TLS1.2-HARDCORE.ictpl policys"
	\\itsupport\install\tech\IISCrypto\IISCryptoCli.exe /template \\itsupport\install\tech\IISCrypto\InScope-TLS1.2-HARDCORE.ictpl
} elseif (!($hardenedTLS)) {
	Write-host "Configuing TLS settings in accordance with 2k16-DC-Default.ictpl policys"
	\\itsupport\install\tech\IISCrypto\IISCryptoCli.exe /template \\itsupport\install\tech\IISCrypto\2k16-DC-Default.ictpl
} else {Write-Warning "que?"}

#Install Role
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

#Import ADDSDeployment Module
Import-Module ADDSDeployment

#Create AD Directorys
"SYSVOL","NTDS_Data","NTDS_Logs" | %{ if (!(Test-Path D:\$_)) {New-Item -Path D:\$_ -ItemType directory}}

if ($TestPromote -eq $True){
	#Preform Prerequisite Checks
	Test-ADDSDomainControllerInstallation `
		-DomainName gcserv.com `
		-SiteName $Site `
		-ReplicationSourceDC $ReplicationSourceDC `
		-DatabasePath D:\NTDS_Data `
		-SysvolPath D:\SYSVOL `
		-LogPath D:\NTDS_Logs `
		-InstallDns `
		-NoRebootOnCompletion `
		-Verbose
} else {
	#Promote Domain Controller 
	Install-ADDSDomainController `
		-DomainName gcserv.com `
		-SiteName $Site `
		-ReplicationSourceDC $ReplicationSourceDC `
		-DatabasePath D:\NTDS_Data `
		-SysvolPath D:\SYSVOL `
		-LogPath D:\NTDS_Logs `
		-InstallDns `
		-NoRebootOnCompletion `
		-Verbose
	sleep 30
	#Reboot
	shutdown -r -t 0
}	
