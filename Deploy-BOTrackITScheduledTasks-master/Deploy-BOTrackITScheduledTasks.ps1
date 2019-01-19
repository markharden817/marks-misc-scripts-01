$serverList = Get-ADComputer -Filter 'Name -like "WSUS"' | ?{$_.Name -ne "MASTER-WSUS"}


$sb = {
	$uploadScript = "U:\Syslogd\Scripts\Trackit_Upload.bat"
	$dataScript = "U:\Syslogd\Scripts\Trackit-DATA.PS1"
	
    #UploadScript
	$taskName = "TrackIT_Upload"
	$description = "Upload TrackIT Data"
	$action = New-ScheduledTaskAction -Execute $uploadScript
	$trigger =  New-ScheduledTaskTrigger -Daily -At 4am
	if (!(Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)){
		Write-Warning "$($env:computername): Task not found"
		Write-Host "$($env:computername): Creating Task $($taskName)" -ForegroundColor Green
		Register-ScheduledTask -Action $action -User "System" -Trigger $trigger -TaskName $taskName -Description $description
		Sleep 3;
		$task = Get-ScheduledTask -TaskName $taskName
		$task.Triggers.repetition.Duration = 'PT24H'
		$task.Triggers.repetition.Interval = 'PT60M'
		$task.Settings.MultipleInstances = 'Parallel'
		$task | Set-ScheduledTask
	}
	#dataScript
	$taskName = "TrackIT_Merge"
	$description = "Merge TrackIT Data"
	$action = New-ScheduledTaskAction -Execute powershell.exe -Argument "-ExecutionPolicy Bypass -File $dataScript"
	$trigger =  New-ScheduledTaskTrigger -Daily -At 4am
	if (!(Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)){
		Write-Warning "$($env:computername): Task not found"
		Write-Host "$($env:computername): Creating Task $($taskName)" -ForegroundColor Green
		Register-ScheduledTask -Action $action -User "System" -Trigger $trigger -TaskName $taskName -Description $description
		Sleep 3;
		$task = Get-ScheduledTask -TaskName $taskName
		#$task.Triggers.repetition.Duration = 'PT24H'
		#$task.Triggers.repetition.Interval = 'PT60M'
		$task.Settings.MultipleInstances = 'Parallel'
		$task | Set-ScheduledTask
	}
	
}

$serverList | %{
	Invoke-Command -ScriptBlock $sb -Computername $($_.Name)
}
