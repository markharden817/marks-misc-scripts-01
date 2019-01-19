param (
    [Parameter(Mandatory=$true,Position=0,HelpMessage="Please specify a search string")]$searchString
)

$searchBase = "\\gcserv.com\branchdata"

Function Search-BranchdataFileMatches {
    
    #Search for matching .url and hosts files
    $urlMatchingItems = ls $searchBase -Recurse | ?{$_.Extension -eq ".url" -or $_.Extension -eq ""} | select-string -Pattern $searchString -CaseSensitive:$false

    #Search for matching .lnk files
    $lnkItems = ls $searchBase -Recurse | ?{$_.Extension -eq ".lnk"}
    $sh = New-Object -COM WScript.Shell
    
    foreach ($i in $lnkItems) {
        $lnkMatchingItems = if (($sh.CreateShortcut($i.FullName).Arguments | select-string -Pattern $searchString -CaseSensitive:$false) -ne $null) {Write-Host $i.FullName}
        }

    #Print Output
    $urlMatchingItems.Path
    $lnkMatchingItems
}

Search-BranchdataFileMatches