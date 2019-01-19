Param(
    [Parameter(Mandatory=$True,Position=1)][string]$ComputerName
    )

$NamespaceFolders = @(
    "Client"
    "Clients"
    "Common"
    "Sites"
    "Stage"
    )
$DFSWriteableMembers = @(
    "hgopndmctl02.gcserv.com"
    "hgopndmctl04.gcserv.com"
    #"hgopnmsadc02.gcserv.com"
    #"hgopnmsadc04.gcserv.com"
    )

function Configure-BranchdataDFSR {
    #Install Roles and Tools
    Write-Host -ForegroundColor Green "Install Roles and Tools..."
    Install-WindowsFeature "FS-DFS-Namespace","FS-DFS-Replication" -IncludeManagementTools -ComputerName $ComputerName
    
    #Create Base Directorys
    Write-Host -ForegroundColor Green "Create Base Directorys..."
    if (!(Test-Path "\\$ComputerName\d$\BranchData")){
        Write-Host "Creating "\\$ComputerName\d$\BranchData"" -ForegroundColor Green Green
        mkdir "\\$ComputerName\d$\BranchData" -Verbose
        }
    if (!(Test-Path "\\$ComputerName\d$\BranchData_Repository")){
        Write-Host "Creating "$\\$ComputerName\d$\BranchData_Repository"" -ForegroundColor Green
        mkdir "\\$ComputerName\d$\BranchData_Repository" -Verbose
        }

    
    foreach ($Folder in $NamespaceFolders) {
        #Create Namespace Folders Directorys 
        Write-Host -ForegroundColor Green "Create Namespace Folders Directorys..."
        if (!(Test-Path "\\$ComputerName\d$\BranchData_Repository\$Folder")){
            Write-Host "Creating $Folder" -ForegroundColor Green
            mkdir "\\$ComputerName\d$\BranchData_Repository\$Folder"
        }

        #Create Namespace Shares
        Write-Host -ForegroundColor Green "Create Namespace Shares..."
        Try {
            $c = new-CimSession -ComputerName $ComputerName 
        }catch {
            Write-Warning "Connection Failed"
        }
        if (!(Get-SmbShare -Name "$Folder$" -CimSession $c -ErrorAction SilentlyContinue)){
            New-SmbShare -Path "D:\BranchData_Repository\$Folder" -Name "$Folder$" -CimSession $c -Verbose
        }
      
        #Add DFS Folder Target
        Write-Host -ForegroundColor Green "Adding DFS Folder Target..."
        if ((Get-DfsnFolderTarget -Path \\gcserv.com\branchdata\$Folder).TargetPath -notcontains "\\$ComputerName\$Folder$"){
            New-DfsnFolderTarget -Path \\gcserv.com\branchdata\$Folder -TargetPath "\\$ComputerName\$Folder$" -Verbose
        }

        #Add DFSRMember
        Write-Host -ForegroundColor Green "Adding DFSR Members..."
        if ((Get-DfsReplicationGroup -GroupName "branchdata\$Folder" | Get-DfsReplicatedFolder -FolderName "$Folder" | Get-DfsrMember).DnsName -notcontains $ComputerName){
            Get-DfsReplicationGroup -GroupName "branchdata\$Folder" | Get-DfsReplicatedFolder -FolderName "$Folder" | Add-DfsrMember -ComputerName $ComputerName -Verbose | Format-Table dnsname,groupname -auto -wrap
            Set-DfsrMembership -GroupName "branchdata\$Folder" -FolderName "$Folder" -ContentPath "D:\BranchData_Repository\$Folder" -ComputerName $ComputerName -PrimaryMember $False -ReadOnly:$True -Force -Verbose| Format-Table *name,*path,primary* -auto -wrap
            $DFSWriteableMembers | %{
                Add-DfsrConnection -GroupName "branchdata\$Folder" -SourceComputerName $_ -DestinationComputerName $ComputerName -Verbose | Format-Table *name -wrap -auto
            }
        }
    }
}


Configure-BranchdataDFSR
#Pause
