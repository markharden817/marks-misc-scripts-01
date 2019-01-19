#Server 2016 Base Configuration
	
#Enable RDP
	(Get-WmiObject Win32_TerminalServiceSetting -Namespace root\cimv2\TerminalServices).SetAllowTsConnections(1,1) 
	(Get-WmiObject -Class "Win32_TSGeneralSetting" -Namespace root\cimv2\TerminalServices -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(1) 
#Set Power Profile to High Proformance
	powercfg /S 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
#Disable some Tasks
	SCHTASKS /Change /TN "\Microsoft\Windows\AppID\SmartScreenSpecific" /DISABLE 
    SCHTASKS /Change /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" /DISABLE 
    SCHTASKS /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /DISABLE 
    SCHTASKS /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /DISABLE 
    SCHTASKS /Change /TN "\Microsoft\Windows\Autochk\Proxy" /DISABLE 
    SCHTASKS /Change /TN "\Microsoft\Windows\Ras\MobilityManager" /DISABLE 
    SCHTASKS /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /DISABLE 
    SCHTASKS /Change /TN "\Microsoft\Windows\PI\Sqm-Tasks" /DISABLE 
#Disable SMB Strict Name Checking
	Set-ItemProperty -path HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters -type DWORD -name DisableStrictNameChecking -value 1 -force
#TCP Offload Fix (KB888750)
    Set-ItemProperty -path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -type DWORD -name DisableTaskOffload -value 1 -force 
#Disable Forcing of Single Session per User
    Set-ItemProperty -path HKLM:"\SYSTEM\CurrentControlSet\Control\Terminal Server" -type DWORD -name fSingleSessionPerUser -value 0 -force 
#Disable UAC
    Set-ItemProperty -path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -type DWORD -name EnableLUA -value 0 -force 
#Silence Server Manager
    Set-ItemProperty -path HKLM:\SOFTWARE\Microsoft\ServerManager -type DWORD -name DoNotOpenServerManagerAtLogon -value 1 -force 
    Set-ItemProperty -path HKLM:\SOFTWARE\Microsoft\ServerManager\Oobe -type DWORD -name DoNotOpenInitialConfigurationTasksAtLogon -value 1 -force 
#Disable Auto-Updates
	Set-ItemProperty -path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -type DWORD -name NoAutoUpdate -value 3 -force
#Additional Hardening
	SCHTASKS /Change /TN "\Microsoft\XblGameSave\XblGameSaveTask" /DISABLE
	SCHTASKS /Change /TN "\Microsoft\XblGameSave\XblGameSaveTaskLogon" /DISABLE 
#Remove Windows Defender
	Uninstall-WindowsFeature Windows-Defender-Features
#Install Windows Backup
    Add-WindowsFeature Windows-Server-Backup

sleep 5;