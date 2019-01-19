# SYNOPSIS

Updates Systems DNS server settings by AD OU.

# NOTES

If RunReport flag is $True no changes will be made to remote systems.

# SYNTAX

`.\Change-NameServers.ps1 [-OU <String[]>] [-RunReport:<$True|$False>]`

# EXAMPLES

### EXAMPLE 1

`.\Change-NameServers.ps1 -OU "OU=Development,OU=Servers,DC=sample,DC=com" -RunReport:$false`
### EXAMPLE 2

`.\Change-NameServers.ps1 -OU "OU=Development,OU=Servers,DC=sample,DC=com" -RunReport:$true`
