Param(
    [Parameter(Mandatory=$True,Position=1)][string]$WSUSServer,
    [Parameter(Mandatory=$True,Position=2)][string]$EmailTo,
    [Parameter(Mandatory=$False,Position=3)][string]$WSUSGroup,
    [Parameter(Mandatory=$False,Position=4)][string]$Port,
    [Parameter(Mandatory=$False,Position=5)][string]$UseSSL,
    [Parameter(Mandatory=$True,Position=6)][int]$StaleDays,
    [Parameter(Mandatory=$False,Position=7)][bool]$TracyReport
    )

Import-Module PoshWSUS


if ($TracyReport){
    $ReportFileRoot = "\\hgopagcupd01.gcserv.com\WSUSReports"
    $ReportFilePathPendingUpdates = "$ReportFileRoot\$WSUSGroup WSUSReportFull-$((get-date).tostring("MMddyyyy-HHmmss")) PendingUpdates.csv"
    $ReportFilePathStaleWorkstations = "$ReportFileRoot\$WSUSGroup WSUSReportFull- $((get-date).tostring("MMddyyyy-HHmmss")) StaleWorkstations.csv"
} else {
    $ReportFilePath = "\\hgopagcupd01.gcserv.com\WSUSReports\$WSUSServer - $WSUSGroup - $((get-date).tostring("MMddyyyy-HHmmss")).html"
}



if ($UseSSL){
    Try {
        $connect = Connect-PSWSUSServer -WsusServer $WSUSServer -Port $Port -SecureConnection
    }
    Catch {
        Break
    }
} else {
    Try {
        $connect = Connect-PSWSUSServer -WsusServer $WSUSServer -Port $Port
    }
    Catch {
        #Break
    }
}

if (!($connect)){
    Write-Host ""
    Send-MailMessage -From "WSUS-Reports@noreply.gcserv.com" -To $EmailTo -Subject "ERROR: $WSUSServer WSUS Report" -Body "Report Failed: Connection Error" -SmtpServer gcsmtp.gcserv.com
}

#Declare globals
$siteWorkstationsData = @()
$wsusServerInfoData = @()

##Get Workstation Data
if ($TracyReport){
    $rawSiteWorkstations = Get-PSWSUSClient -IncludeDownstreamComputerTargets | ?{$_.RequestedTargetGroupName -like "$WSUSGroup*"}
} else {
    $rawSiteWorkstations = Get-PSWSUSClient | ?{$_.RequestedTargetGroupName -like "$WSUSGroup*"}
}

$rawSiteWorkstations | %{
    $obj = New-Object System.Object
    $obj | Add-Member -type NoteProperty -name FullDomainName -Value $_.FullDomainName
    $obj | Add-Member -type NoteProperty -name IPAddress -Value $_.IPAddress
    $obj | Add-Member -type NoteProperty -name Make -Value $_.Make
    $obj | Add-Member -type NoteProperty -name Model -Value $_.Model
    $obj | Add-Member -type NoteProperty -name OSArchitecture -Value $_.OSArchitecture
    $obj | Add-Member -type NoteProperty -name ClientVersion -Value $_.ClientVersion
    $obj | Add-Member -type NoteProperty -name OSDescription -Value $_.OSDescription
    $obj | Add-Member -type NoteProperty -name LastSyncTime -Value $_.LastSyncTime
    $obj | Add-Member -type NoteProperty -name LastSyncResult -Value $_.LastSyncResult
    $obj | Add-Member -type NoteProperty -name LastReportedStatusTime -Value $_.LastReportedStatusTime
    $obj | Add-Member -type NoteProperty -name RequestedTargetGroupName -Value $_.RequestedTargetGroupName
    $obj | Add-Member -type NoteProperty -name InstalledCount -Value $_.GetUpdateInstallationSummary().InstalledCount
    $obj | Add-Member -type NoteProperty -name NotInstalledCount -Value $_.GetUpdateInstallationSummary().NotInstalledCount
    $obj | Add-Member -type NoteProperty -name PendingRebootCount -Value $_.GetUpdateInstallationSummary().InstalledPendingRebootCount
    $obj | Add-Member -type NoteProperty -name FailedCount -Value $_.GetUpdateInstallationSummary().FailedCount
    $siteWorkstationsData += $obj
}

##Get WSUS Server Data
$getWSUSServer = Get-PSWSUSServer
$getWSUSServerConfig = Get-PSWSUSConfiguration
$obj = New-Object System.Object
$obj | Add-Member -type NoteProperty -name ServerName -Value $getWSUSServer.ServerName
$obj | Add-Member -type NoteProperty -name IsReplicaServer -Value $getWSUSServerConfig.IsReplicaServer
$obj | Add-Member -type NoteProperty -name Version -Value $getWSUSServer.Version
$obj | Add-Member -type NoteProperty -name PortNumber -Value $getWSUSServer.PortNumber
$obj | Add-Member -type NoteProperty -name UseSecureConnection -Value $getWSUSServer.UseSecureConnection
$obj | Add-Member -type NoteProperty -name ServerProtocolVersion -Value $getWSUSServer.ServerProtocolVersion 
$wsusServerInfoData = $obj


###################Report#######################
[string]$html = $null

$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
TR:nth-child(even) {background-color: #CCC}
TR:nth-child(odd) {background-color: #FFF}
</style>
"@
    
#WSUS Info
$paramHash = @{
    Head = $Header
    Title = "WSUS Information"
    PreContent = "<H3>WSUS Information</H3>"
    Property = "ServerName","IsReplicaServer","Version","PortNumber","UseSecureConnection","ServerProtocolVersion"
}
$wsusServerInfoData | ConvertTo-Html @paramHash | Out-File -FilePath $ReportFilePath -Force
$html += $wsusServerInfoData | ConvertTo-Html @paramHash
 
#Stale Workstations
$paramHash = @{
    Head = $Header
    Title = "Stale Systems "
    PreContent = "<H3>Stale Systems (Has not reported in $StaleDays)</H3>"
    Property = "FullDomainName","IPAddress","Make","Model","OSArchitecture","ClientVersion","OSDescription","LastReportedStatusTime"
}
if ($TracyReport){
    $staleWorkstations = $siteWorkstationsData | ?{$_.LastReportedStatusTime -le ((get-date).AddDays($StaleDays*-1))}
    $staleWorkstations | sort LastReportedStatusTime | Export-Csv -Path "$ReportFilePathStaleWorkstations" -NoTypeInformation -Force
}else{
    $staleWorkstations = $siteWorkstationsData | ?{$_.LastReportedStatusTime -le ((get-date).AddDays($StaleDays*-1))}
    $staleWorkstations | sort LastReportedStatusTime | ConvertTo-Html @paramHash | Out-File -FilePath $ReportFilePath -Append -Force
    $html += $staleWorkstations | sort LastReportedStatusTime | ConvertTo-Html @paramHash
}

#Workstations with pending updates
$paramHash = @{
    Head = $Header
    Title = "Systems with pending updates"
    PreContent = "<H3>Systems with pending updates (Not including stale systems)</H3>"
    Property = "FullDomainName","IPAddress","Make","Model","OSArchitecture","ClientVersion","OSDescription","LastReportedStatusTime","NotInstalledCount","PendingRebootCount","FailedCount"
}

if ($TracyReport){
    $pendingUpdatesWorkstations = $siteWorkstationsData 
    $pendingUpdatesWorkstations  | ?{$_.LastReportedStatusTime -ge ((get-date).AddDays($StaleDays*-1))} | sort NotInstalledCount -Descending | Export-Csv -Path "$ReportFilePathPendingUpdates" -NoTypeInformation -Force
} else {
    $pendingUpdatesWorkstations = $siteWorkstationsData | ?{$_.NotInstalledCount -gt "0" -or $_.FailedCount -gt "0"}
    $pendingUpdatesWorkstations | ?{$_.LastReportedStatusTime -ge ((get-date).AddDays($StaleDays*-1))} | sort NotInstalledCount -Descending | ConvertTo-Html @paramHash | Out-File -FilePath $ReportFilePath -Append -Force
    $html += $pendingUpdatesWorkstations | sort NotInstalledCount -Descending | ConvertTo-Html @paramHash
}


#Email Report

if ($TracyReport){
    Send-MailMessage -From "WSUS-Reports@noreply.gcserv.com" -To $EmailTo -Subject "$WSUSServer WSUS Report" -Body "A copy of this report has been saved" -BodyAsHtml -SmtpServer gcsmtp.gcserv.com -Attachments @($ReportFilePathPendingUpdates,$ReportFilePathStaleWorkstations)
}else{
    Send-MailMessage -From "WSUS-Reports@noreply.gcserv.com" -To $EmailTo -Subject "$WSUSServer WSUS Report" -Body $html -BodyAsHtml -SmtpServer gcsmtp.gcserv.com
}
