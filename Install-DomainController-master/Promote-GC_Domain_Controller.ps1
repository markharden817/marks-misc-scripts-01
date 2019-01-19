<#
.SYNOPSIS

Promotes New DC.

.DESCRIPTION

Promotes and configures Domain Controller to new system.

.EXAMPLE

C:\PS> Promote-GC_Domain_Controller.ps1 -Site "SAN" -TestPromote $True -ReplicationSourceDC "DC01.sample.com"

#>

param (
    	[Parameter(Mandatory=$true)][string]$Site,
		[Parameter(Mandatory=$true)][bool]$TestPromote,
        [Parameter(Mandatory=$true)][string]$ReplicationSourceDC
)
#-----------------------------------------------------------

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
