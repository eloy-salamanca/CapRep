<#-----------------------------------------------------------------------------
Capacity Planning Data Gathering

Eloy Salamanca | IT-Consultant & Technical Advisor
@EloySalamancaR

Part of Capacity Planning Auto Populated REPort

Generated on: 12/12/2017

-----------------------------------------------------------------------------#>

<#
.SYNOPSIS
    Set-CapRepDB.ps1 is made to create db schema on a SQL Server
    for CapRep to work properly

.PARAMETER <file>
	File name containing servers list to gather data.

.EXAMPLE
	Set-CapRepDB.ps1 -verbose

.NOTES
	Name                : Set-CapRepDB.ps1
	Author              : @EloySalamancaR
	Last Edit           : 12/12/2017
	Current Version     : 1.0.0

	History				: 1.0.0 - Posted 12/12/2017 - First iteration

	Rights Required		: SQL User with apropiate privileges to create db
                        : Set-ExecutionPolicy to 'Unrestricted' for the .ps1 file to execute the installs

.LINK
    https://twitter.com/EloySalamancaR

.FUNCTIONALITY
   Part of Capacity Planning Data Gathering Report,
   to save performance information of single servers into SQL Server.
#>
[CmdletBinding()]
param (
    [Parameter(HelpMessage="Enter SQL Server to create schema, default: localhost")]
    [string]$DBServer = "localhost",
    [string]$DBUser = "sa",
    [string]$DBPasswd = "P455w.rd",
    [string]$InputSqlFile = ".\CapRep_MASTER.sql"
)
# =======================================================================
# PROCESS
# =======================================================================
$version = '1.0.0'
$date = Get-Date

Write-Verbose "Set-CapRepDB.ps1 version: $version"

Try { 
    Invoke-SqlCmd -ServerInstance "localhost" -Username $DBUser -Password $DBPasswd -InputFile $InputSqlFile | Out-Null
    Write-Verbose "==> CapRep db created and permissions set"
    Write-Verbose "End of history."

    } Catch {
        echo echo $_.Exception|format-list -force
        Write-Error $error
}