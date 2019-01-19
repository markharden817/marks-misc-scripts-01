#Configure-ServerVolumes
$disksConfigured = $False
$diskobj = @()
$allDisks = Get-Disk

function Main {
    cls
    Write-Host "==================================================="
    Write-Host "              Configure ServerVolumes                 "
    Write-Host "==================================================="
        $diskobj = @()
        $allDisks | where {$_.Size -gt 0} | select Number, OperationalStatus, @{n='Size(GB)';e={[int]($_.Size/1GB)}}, PartitionStyle | sort Number | FT -AutoSize
        $i = 0               
        Foreach ($disk in ($allDisks | where {$_.Size -gt 0}) | sort Number)
            {
                $isSQL = $null
                $volLetter = $null
                $diskobj += New-Object PSObject
                if ($disk.Number -eq 0){
                    Write-Host "===== Disk $($disk.Number) ====="
                    Add-Member -InputObject $diskobj[$i] -MemberType NoteProperty -Name DiskNumber -Value $disk.Number
                    Write-host "Disk $($disk.Number) will be set to drive letter `"C`""
                    Write-host "Disk $($disk.Number) will be set to drive label `"OS`""
                    Add-Member -InputObject $diskobj[$i] -MemberType NoteProperty -Name VolumeLetter -Value "C"
                    Add-Member -InputObject $diskobj[$i] -MemberType NoteProperty -Name FriendlyName -Value "OS"
                    Add-Member -InputObject $diskobj[$i] -MemberType NoteProperty -Name isSQL -Value "N"
                    }
                elseif ($disk.Number -eq 1){
                    Write-Host "===== Disk $($disk.Number) ====="
                    Add-Member -InputObject $diskobj[$i] -MemberType NoteProperty -Name DiskNumber -Value $disk.Number
                    Write-host "Disk $($disk.Number) will be set to drive letter `"P`""
                    Write-host "Disk $($disk.Number) will be set to drive label `"Pagefile`""
                    Add-Member -InputObject $diskobj[$i] -MemberType NoteProperty -Name VolumeLetter -Value "P"
                    Add-Member -InputObject $diskobj[$i] -MemberType NoteProperty -Name FriendlyName -Value "Pagefile"
                    Add-Member -InputObject $diskobj[$i] -MemberType NoteProperty -Name isSQL -Value "N"
                    }
                else {
                    Write-Host "===== Disk $($disk.Number) ====="
                    Add-Member -InputObject $diskobj[$i] -MemberType NoteProperty -Name DiskNumber -Value $disk.Number
                    do
                        {
                            $volLetter = Read-Host -Prompt "Enter Disk $($disk.Number) Drive Letter"
                            $volLetter = $volLetter.ToUpper()
                        } until ($volLetter.Length -eq "1")
                    Add-Member -InputObject $diskobj[$i] -MemberType NoteProperty -Name VolumeLetter -Value $volLetter
                    Add-Member -InputObject $diskobj[$i] -MemberType NoteProperty -Name FriendlyName -Value (Read-Host -Prompt "Enter Disk $($disk.Number) Drive Label")
                    do
                        {
                            $isSQL = Read-Host -Prompt "Is This a SQL Volume (Y/N)"
                            $isSQL = $isSQL.ToUpper()
                        } until ($isSQL -eq "Y" -or $isSQL -eq "N")
                    Add-Member -InputObject $diskobj[$i] -MemberType NoteProperty -Name isSQL -Value $isSQL
                }
                $i++
            }
        $disksConfigured = $true
        Configure-CDROMDrive
        Configure-Volumes
}

function Configure-CDROMDrive
    {
        if ((Get-WmiObject Win32_cdromdrive).drive.count -eq "1")
            {
                (Get-WmiObject Win32_cdromdrive).drive | Where-Object {$a = mountvol $_ /l;mountvol $_ /d;$a = $a.Trim();mountvol B: $a}       
            }
        Else 
            {
                Write-Warning "Ensure exactly 1 CD-ROM drive is installed. System CD-ROM drive could not be set to B:"
                Write-Warning "Correct issue and re-run the follow command"
                Write-Warning '(Get-WmiObject Win32_cdromdrive).drive | Where-Object {$a = mountvol $_ /l;mountvol $_ /d;$a = $a.Trim();mountvol Z: $a}'
				Pause
				Break
            }
    }

function Configure-Volumes 
    {
    if ($disksConfigured)
            {
            #Confirm
            cls
            Write-Host "=============Confirm the following Values=================="
            if ($disksConfigured)
                {
                $diskobj | FT -AutoSize       
                }
            else
                {
                Write-Host "Disks have not been configured"
                }
            $confirmed = Read-Host -Prompt "Is this correct? (Y/N)"
            if ($confirmed.ToUpper() -eq "Y")
                {
                #Configure
                foreach ($obj in $diskobj) 
                    {
                        if ($obj.DiskNumber -eq 0) 
                            {
                                Set-Volume -DriveLetter C -NewFileSystemLabel OS
                            }
                        #elseif ($obj.DiskNumber -eq 1) {}
                        else 
                            {
                            if ($obj.isSQL.ToUpper() -eq "Y")
                                {
                                    #Write-Host "$($obj.VolumeLetter) is SQL"
                                    "RESCAN","SELECT DISK $($obj.DiskNumber)","ATTRIBUTES DISK CLEAR READONLY","ONLINE DISK","CONVERT MBR","CREATE PARTITION PRIMARY","FORMAT FS=NTFS unit=64K LABEL=$($obj.FriendlyName) QUICK NOWAIT","ASSIGN LETTER=$($obj.VolumeLetter)" | Diskpart
           
                                }
                            else 
                                {
                                    #Write-Host "$($obj.VolumeLetter) is !NOT! SQL"
                                    "RESCAN","SELECT DISK $($obj.DiskNumber)","ATTRIBUTES DISK CLEAR READONLY","ONLINE DISK","CONVERT MBR","CREATE PARTITION PRIMARY","FORMAT FS=NTFS LABEL=$($obj.FriendlyName) QUICK NOWAIT","ASSIGN LETTER=$($obj.VolumeLetter)" | Diskpart
                                }
                            }
                    }
            }
            else 
                {
					Main        
                }
            
        }
 
    }
     
              
Main
