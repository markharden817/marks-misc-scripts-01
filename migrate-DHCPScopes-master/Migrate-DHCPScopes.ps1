<#
.SYNOPSIS

DHCP migration tool.

.DESCRIPTION

Given two new and two old DHCP servers this script installs DHCP role, migrates server and lease data, creates failover partnership, and configures scheduled task.

.EXAMPLE

C:\PS> Migrate-DHCPScopes.ps1 -oldDC1 covpnmsadc01.gcserv.com -oldDC2 covpnmsadc02.gcserv.com -newDC1 covpndmctl01.gcserv.com -newDC2 covpndmctl02.gcserv.com -taskUserName srvDHCP@gcserv.com

#>

param (
    [Parameter(Mandatory=$true)][string]$oldDC1,
	[Parameter(Mandatory=$true)][string]$oldDC2,
	[Parameter(Mandatory=$true)][string]$newDC1,
	[Parameter(Mandatory=$true)][string]$newDC2,
	[string]$taskUserName = "HGO\srvDHCP"
)
 
 
$taskPassword = $password = Read-Host -AsSecureString -Prompt "Enter $($taskUserName) Password"
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $taskUserName, $taskPassword
$Password = $Credentials.GetNetworkCredential().Password 

$dhcpExportFile_1 = "\\$newDC1\c$\dhcp-$oldDC1-$(get-date -f yyyy-MM-dd).xml"
$dhcpExportFile_2 = "\\$newDC1\c$\dhcp-$oldDC2-$(get-date -f yyyy-MM-dd).xml"
$failoverInstanceName = "$($newDC1)_$($newDC2)_LoadBalance"
$loadBalancePercent = 70
$maxClientLeadTime = "1:00:00"
$stateSwitchInterval = "00:45:00"
$autoStateTransition = $True

#1. Install Roles
$newDC1, $newDC2 | %{Install-WindowsFeature DHCP -IncludeManagementTools -ComputerName $_}

#2. Export DHCP Data
Export-DhcpServer -ComputerName $oldDC1 -File $dhcpExportFile_1 -Leases -Verbose -Force
Export-DhcpServer -ComputerName $oldDC2 -File $dhcpExportFile_2 -Leases -Verbose -Force

#3. Concatenate Lease Data 
[xml]$xmlData_1 = cat $dhcpExportFile_1
[xml]$xmlData_2 = cat $dhcpExportFile_2
$xmlScopes_1 = $xmlData_1.DHCPServer.IPv4.Scopes.Scope | ?{$_.State -eq "Active"}
$xmlScopes_2 = $xmlData_2.DHCPServer.IPv4.Scopes.Scope | ?{$_.State -eq "Active"}

foreach ($xmlScope in $xmlScopes_2){
	$leases = ($xmlScope.Leases.Lease | ?{$_.AddressState -eq "Active"})
	foreach ($lease in $leases) {
		if ($leases.count -gt 1) {
			Write-Host "Merging lease $($leases.indexof($lease)) of $(($leases).count) in Scope $($xmlScope.ScopeID) | $($lease.IPAddress)" -ForegroundColor Green -BackgroundColor Black
			$newNode = $xmlData_1.ImportNode($xmlScope.Leases.Lease[$leases.indexof($lease)], $true)
			if ($xmlScopes_2.count -gt 1){
				$xmlScopes_1[$xmlScopes_1.ScopeId.indexof($xmlScope.ScopeID)].Leases.AppendChild($newNode) | Out-Null
			} elseif ($xmlScopes_2.count -eq 1 -or $xmlScopes_2.count -eq $Null){
				$xmlScopes_1.Leases.AppendChild($newNode) 
			} else {
				Write-Host "que?"
			}
		} elseif ($leases.count -eq 1 -or $leases.count -eq $Null){
			$newNode = $xmlData_1.ImportNode($xmlScope.Leases.Lease, $true)
			if (Get-Member -InputObject $xmlScopes_2[$xmlScopes_1.ScopeId.indexof($xmlScope.ScopeID)].Leases -Name "AppendChild"){
				$xmlScopes_1[$xmlScopes_1.ScopeId.indexof($xmlScope.ScopeID)].Leases.AppendChild($newNode) | Out-Null}
		} else {
			Write-Host "que?"
		}
	}
}

try {
	Write-Host "`r`nWriting concatenated data to file" -ForegroundColor Green -BackgroundColor Black
	$xmlData_1.Save($dhcpExportFile_1)
	Write-Host "Success!" -ForegroundColor Green -BackgroundColor Black
} catch {
	Write-Warning "Dava save failure"
	exit 1;
}



#4. Import DHCP Data
Import-DhcpServer -ComputerName $newDC1 -File $dhcpExportFile_1 -BackupPath C:\export\backup -Verbose -Leases -Force
Import-DhcpServer -ComputerName $newDC2 -File $dhcpExportFile_1 -BackupPath C:\export\backup -Verbose -ServerConfigOnly -Force

#5. Configure DHCP Load Balance
$serverScopes = @((Get-DhcpServerv4Scope -ComputerName $newDC1).ScopeId.IPAddressToString)
	Add-DhcpServerv4Failover `
		–ComputerName $newDC1 `
		–PartnerServer $newDC2 `
		–Name $failoverInstanceName `
		–LoadBalancePercent $loadBalancePercent `
		-MaxClientLeadTime $maxClientLeadTime `
		-StateSwitchInterval $stateSwitchInterval `
		-ScopeId $serverScopes[0]
	for ($i=1;$i -lt $serverScopes.count;$i++) {
		Add-DhcpServerv4FailoverScope `
			-ComputerName $newDC1 `
			-Name $failoverInstanceName `
			-ScopeId $serverScopes[$i]
}

#6. Configure Scope Replication Scheduled Task
$taskName = "Replicate_DHCP_Data"
$description = "Replicate DHCP Scope Information"
$action = New-ScheduledTaskAction -Execute Powershell.exe -Argument '-ExecutionPolicy Bypass -Command "Invoke-DhcpServerv4FailoverReplication -Force"'
$trigger =  New-ScheduledTaskTrigger -Daily -At 9am
Register-ScheduledTask -Action $action -User $taskUserName -Password $Password -Trigger $trigger -TaskName $taskName -Description $description
$task = Get-ScheduledTask -TaskName $taskName
$task.Triggers.repetition.Duration = "PT24H"
$task.Triggers.repetition.Interval = "PT05M"
$task.Settings.MultipleInstances = "Parallel"
$task | Set-ScheduledTask -User $taskUserName -Password $Password 

#99. Clean Up
Remove-Item C:\export -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $dhcpExportFile_1 -Force -ErrorAction SilentlyContinue
Remove-Item $dhcpExportFile_2 -Force -ErrorAction SilentlyContinue
