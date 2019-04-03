#########################################################################################
<#
    .SYNOPSIS
    Creates Webserver CSR

    .DESCRIPTION
    
    Title: Create-WebserverCSR
    Author: Mark Harden
    Version: 1.0

    Creates Webserver CSR based on Common Name and Subject Alternite Names' (SAN) as inputs. Outputs key and csr to directory.
    
    .PARAMETER CommonName
    Common name for sobjust of CSR. Usually should be FQDN of alais.

    .PARAMETER SAN
    Comma spererated list of named dns records certificate will be valid for.

    .EXAMPLE
    C:\> Create-WebserverCSR -CommonName webserver01.prosperitybank.com -SubjectAltName webserver01,webserver01.prosperitybank.com
#>
#########################################################################################


param (
    	[Parameter(Mandatory=$true)][string]$CommonName,
		[Parameter(Mandatory=$false)]$SubjectAltName
)

# Default configuration variables
$dirCertRoot = "O:\Group - Systems and Network\Scripts\Create-CSR"
$strCertLength = "4096"
$strCertCountryName = "US"
$strCertStateOrProvinceName = "TX"
$strCertLocalityName = "Houston"
$strCertOrganizationName = "Example Inc"
$strOrganizationalUnitName = "DC=Information Technology"

#----------------------------------------------------------------
Function Verify-Prereqs {
    if (!(Test-Path "$dirCertRoot\$CommonName")){
        mkdir "$dirCertRoot\$CommonName" -Verbose
        Set-Location "$dirCertRoot\$CommonName" -Verbose
    } elseif (Test-Path "$dirCertRoot\$CommonName"){
        Set-Location "$dirCertRoot\$CommonName" -Verbose
    }
    
    #Check OpenSSL install
    try {
        Start-Process openssl.exe -ArgumentList "version" -NoNewWindow | Write-Output
    } catch {
        Write-Warning "OpenSSL is not installed or missing from system %PATH%"
        Pause
        pause
        break;

    }
}


Function Build-CSRConfig {
    #Buld SAN list
    if ($SubjectAltName -ne $null){
        #Check if Common Name is missing from SAN
        if ($SubjectAltName.split(",") -notcontains $CommonName){
          Write-Warning "subjectAltName missing Common Name. Adding Common Name to subjectAltName list"
          $SubjectAltName = "$SubjectAltName" + ",$CommonName"
          Write-Warning "Corrected subjectAltName list: $SubjectAltName"
        }
        [string]$strSAN = "subjectAltName = @alt_names`r`n"
        $strSAN += "[alt_names]`r`n"
        
        for ($i = 1; $i -le $SubjectAltName.split(",").count; $i++ ){
            $strSAN += "DNS.$i = $($SubjectAltName.split(',')[$i-1])`r`n"
        }
    } elseif ($SubjectAltName -eq $null){
        Write-Warning "No subjectAltName defined. Skipping subjectAltName config."
    }

    #Build Configuartion file
    $strConfig = `
"[ req ]
prompt = no
default_bits = 4096
distinguished_name = dn
req_extensions = v3_req

[ dn ]
countryName = $strCertCountryName
stateOrProvinceName = $strCertStateOrProvinceName
localityName = $strCertLocalityName
organizationName = $strCertOrganizationName
organizationalUnitName = $strOrganizationalUnitName 
commonName = $CommonName

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
$strSAN"
    return $strConfig
}

Function Create-CSR{
    if (Test-Path "$CommonName.ini"){
        #Generate Key
        Start-Process openssl.exe -ArgumentList "genrsa -out $CommonName.key $strCertLength" -Wait -NoNewWindow
        #Generate CSR
        Start-Process openssl.exe -ArgumentList "req -new -sha512 -key $CommonName.key -config $CommonName.ini -out $CommonName.csr -batch" -Wait -NoNewWindow
    } else {Write-Warning "CSR config file not present"}   
}

Function Verify-CSR {
    Start-Process openssl.exe -ArgumentList "req -text -noout -in $CommonName.csr" -Wait -NoNewWindow -RedirectStandardOutput stdout.txt
    if (Test-Path stdout.txt){cat stdout.txt}
}

Function Main {
    cls

    #call Verify-Prereqs
    Write-Host -ForegroundColor Green "Verifying Prerequisites"
    Verify-Prereqs

    #call Build-CSRConfig
    Write-Host -ForegroundColor Green "Building CSR configuration template"
    $objConfig = Build-CSRConfig #| Tee -FilePath "$CommonName.ini"
    $objConfig | Out-File -FilePath "$CommonName.ini" -Encoding ascii
    if (Test-Path "$CommonName.ini"){
        Write-Host -ForegroundColor Green "Success"
    } else {Write-Warning "Failed"}
    
    #call Create-CSR
    Create-CSR
    Write-Host -ForegroundColor Green "Generating Private key and CSR"
    if ((Test-Path "$CommonName.key") -and (Test-Path "$CommonName.csr")){
        Write-Host -ForegroundColor Green "Success"
    } else {Write-Warning "Failed"}
    
    #call Verify-CSR
    Write-Host -ForegroundColor Green "Validating CSR"
    $objCSRVerif = Verify-CSR 
    $objCSRVerif | Out-File -FilePath "$CommonName.csr.check" 
    & notepad.exe "$CommonName.csr.check"

    Write-Host -ForegroundColor Green -BackgroundColor Black """
}

Main
