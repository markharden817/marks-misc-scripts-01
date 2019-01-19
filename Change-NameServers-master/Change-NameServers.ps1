Param(
    [Parameter(Mandatory=$True,Position=1)][string]$OU,
    [Parameter(Mandatory=$False,Position=2)][string]$RunReport
    )

$newDNS = "10.2.7.201","10.2.7.203"

$OUComputers = Get-ADComputer -SearchBase $OU -Filter *
#$OUComputers = @("hgo174613")

$myArr = New-Object System.Collections.ArrayList

function Change-NameServers {
    Param($ComputerName)
    if (Test-Connection $ComputerName -Quiet -ErrorAction SilentlyContinue){
        $nics = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $ComputerName -ErrorAction SilentlyContinue | Where{$_.IPEnabled -eq "TRUE" -and $_.DNSServerSearchOrder}
        foreach($nic in $nics)
        {
            #Write-Host "`tExisting DNS Servers " $nic.DNSServerSearchOrder
            $myObj = New-Object System.Object 
            $myObj | add-member -MemberType Noteproperty -Name ComputerName -Value $ComputerName
            $myObj | add-member -MemberType Noteproperty -Name ifIndex -Value $nic.Index
            $myObj | add-member -MemberType Noteproperty -Name DNSServers -Value $nic.DNSServerSearchOrder
            if ($RunReport -ne $True){
                $nic.SetDNSServerSearchOrder($newDNS) | Out-Null
                $updatedNic = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $ComputerName | Where{$_.Index -eq $nic.Index}
                $myObj | add-member -MemberType Noteproperty -Name NewDNSServers -Value $updatedNic.DNSServerSearchOrder            
            }
            $myObj
            $myArr.Add($myObj) | Out-Null
        }
    } else {
        Write-Warning "$($ComputerName): Connection Failed"
    }

}

Foreach ($ComputerName in $OUComputers.Name){
        Change-NameServers($ComputerName)
    }
    $myArr | FT
    $myArr | Out-GridView
