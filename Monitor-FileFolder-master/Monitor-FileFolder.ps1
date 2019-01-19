$folderPath = "\\itsupport\install\Tech\Scripts\Mark\Powershell\Monitor-FileFolder"
$recurse = $True
$filter = '*.*'

$emailTo = 'Mark.Harden@gcserv.com'
$emailFrom = 'BranchdataBot@gcserv.com'
$emailBody = 'See Attached'




$fsw = New-Object IO.FileSystemWatcher $folderPath, $filter -Property @{IncludeSubdirectories = $recurse;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite, DirectoryName'}

function File-Created {
    Register-ObjectEvent $fsw Created -SourceIdentifier FileCreated -Action { 
        $name = $Event.SourceEventArgs.Name 
        $fullPath = $Event.SourceEventArgs.FullPath
        $changeType = $Event.SourceEventArgs.ChangeType 
        $timeStamp = $Event.TimeGenerated 
        $summery = "The file '$name' was $changeType at $timeStamp" 
        $emailSubject = "The file '$name' was $changeType at $timeStamp"
        $emailAttachment = $fullPath
        SendMail $emailFrom $emailTo $emailSubject $emailBody $emailAttachment
    }
} 
function File-Changed {
    Register-ObjectEvent $fsw Changed -SourceIdentifier FileChanged -Action { 
        $name = $Event.SourceEventArgs.Name
        $fullPath = $Event.SourceEventArgs.FullPath 
        $changeType = $Event.SourceEventArgs.ChangeType 
        $timeStamp = $Event.TimeGenerated 
        $emailSubject = "The file '$name' was $changeType at $timeStamp"
        $emailAttachment = $fullPath
        Write-Host "The file '$name' was $changeType at $timeStamp" -fore white
        SendMail $emailFrom $emailTo $emailSubject $emailBody $emailAttachment
    }
}
function File-Deleted {
    Register-ObjectEvent $fsw Deleted -SourceIdentifier FileDeleted -Action { 
        $name = $Event.SourceEventArgs.Name 
        $fullPath = $Event.SourceEventArgs.FullPath
        $changeType = $Event.SourceEventArgs.ChangeType 
        $timeStamp = $Event.TimeGenerated 
        #Write-Host "The file '$name' was $changeType at $timeStamp" -fore red 
        $emailSubject = "The file '$name' was $changeType at $timeStamp"
        $emailAttachment = $fullPath
        #Write-Host $emailAttachment
        SendMail $emailFrom $emailTo $emailSubject $emailBody $emailAttachment
    } 
}
function SendMail {
    Param(
        [parameter(position=1)]$emailFrom,
        [parameter(position=2)]$emailTo,
        [parameter(position=3)]$emailSubject,
        [parameter(position=4)]$emailBody,
        [parameter(position=5)]$emailAttachment
        ) 
        Write-Host "1 $emailFrom" 
        Write-Host "2 $emailTo"
        Write-Host "3 $emailSubject"
        Write-Host "4 $emailBody"
        Write-Host "5 $emailAttachment"
    Send-MailMessage -From $emailFrom -To $emailTo -Subject $emailSubject -Body $emailBody -Attachments $emailAttachment -SmtpServer "gcsmtp.gcserv.com" -Verbose
    Write-Host $emailFrom
}
function main{
    File-Changed
    File-Deleted
    File-Created
}
function UnregisterEvents {
    Unregister-Event -SourceIdentifier FileDeleted
    Unregister-Event -SourceIdentifier FileChanged
    Unregister-Event -SourceIdentifier FileCreated
}

cls
UnregisterEvents | Out-Null
main

