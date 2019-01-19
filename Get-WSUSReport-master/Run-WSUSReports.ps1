$ConfigPath = ".\report.conf.json"
$Config = ConvertFrom-Json -InputObject (cat $ConfigPath -Raw)

Foreach ($item in $Config){
    Write-Host "Running $($item.WSUSServer) Report..." -ForegroundColor Green -BackgroundColor Black
    $item
    Try {
        if ($item.UseSSL){
                .\Get-WSUSReport_v2.ps1 -WSUSServer $($item.WSUSServer) -EmailTo $($item.EmailTo) -Port $($item.Port) -WSUSGroup $($item.WSUSGroup) -StaleDays $($item.StaleDays) -TracyReport:$item.TracyReport -UseSSL
            } else {
                .\Get-WSUSReport_v2.ps1 -WSUSServer $($item.WSUSServer) -EmailTo $($item.EmailTo) -Port $($item.Port) -WSUSGroup $($item.WSUSGroup) -StaleDays $($item.StaleDays) -TracyReport:$item.TracyReport
            }
        } 
    Catch {
        Write-Host "que?"
    }
}
