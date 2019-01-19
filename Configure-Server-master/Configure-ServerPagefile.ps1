#Configure-ServerPagefile
#$pagefileVolume = Get-Volume | ?{$_.FileSystemLabel -eq "Pagefile"}
if (Test-Path "P:")
    {
        Write-host "Current memory: $($(Get-WmiObject Win32_PhysicalMemory).Capacity/1024/1024)MB"
	    Write-host "Using value: $($(Get-WmiObject Win32_PhysicalMemory).Capacity/1024/1024*1.5)MB"
                
        ${pagefileSize}=$($(Get-WmiObject Win32_PhysicalMemory).Capacity/1024/1024*1.5)
        ${pagefileDisk}=1
        ${pagefileLocation}="P"
        
        Start-Process wmic.exe -ArgumentList "pagefileset create name=`"${pagefileLocation}:\pagefile.sys`"" -Wait -NoNewWindow
        Start-Process wmic.exe -ArgumentList "pagefileset where name=`"${pagefileLocation}:\\pagefile.sys`" set InitialSize=${pagefileSize}`,MaximumSize=${pagefileSize}" -Wait -NoNewWindow
        Start-Process wmic.exe -ArgumentList "pagefileset where name=`"C:\\pagefile.sys`" delete" -Wait -NoNewWindow
    }