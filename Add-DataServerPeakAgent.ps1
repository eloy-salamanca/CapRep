<#-----------------------------------------------------------------------------
Capacity Planning Data Gathering

Eloy Salamanca | IT-Consultant & Technical Advisor
@EloySalamancaR

Part of Capacity Planning Auto Populated REPort

Generated on: 23/11/2017

Set-Version:
    (Get-FileHash .\Add-DataServerPeakAgent.ps1).hash | out-file .\Add-DataServerPeakAgent.md5


-----------------------------------------------------------------------------#>

<#
.SYNOPSIS
	Add-DataServerPeakAgent.ps1 meassure and push current server performance 
	values into a SQL Server db.
.DESCRIPTION
	Add-DataServerPeakAgent.ps1 uses CIM/WMI to retrieve system information.
    Then, uses ADO.NET to push all this information in a SQL Server db.
    
    This script have to be rollout in every server, and scheduled at different
    periods of time. This way, messurements aren't affected by remote connection,
    and evaluate server performarce on different time windows.

    Initially is deployed by Set-ServerCapRep.ps1 script, part of Capactiy
    Planning Data Gathering.

    It depends on SQL User "CapRepUser" for "CapRep" db, and must have dbowner
    role to handle data.

.EXAMPLE
	Add-DataServerPeakAgent.ps1 -verbose

.PARAMETER <DBServer>
    To specify a different server to save data.


.NOTES
	Name                : Add-DataServerPeakAgent.ps1
	Author              : @EloySalamancaR
	Last Edit           : 23/11/2017
	Current Version     : 1.0.0

	History				: 1.0.0 - Posted 23/11/2017 - First iteration

	Rights Required		: Local admin on workshop for installing applications
                        : Set-ExecutionPolicy to 'Unrestricted' for the .ps1 file to execute the installs

.LINK
    https://twitter.com/EloySalamancaR

.FUNCTIONALITY
   Part of Capacity Planning Data Gathering Report,
   to save performance information of single servers into SQL db.
#>
[CmdletBinding()]
param (
    [string]$DBServer = "GSTD048",
    [string]$DBName = "CapRep",
    [string]$DBUser = "CapRepUser",
    [string]$DBPasswd = "C4p4c1tyPl4n01"
)
# =======================================================================
# FUNCTIONS
# =======================================================================
Function ExecNonQuery {
    param ($conStr, $cmdText) 
 
    # Checking for parameters. 
    if (!$conStr -or !$cmdText) { 
        # One or more parameters didn't contain values. 
        Write-Host "ExecNonQuery function called with no connection string and/or command text." 
    } else { 

        #ADO.NET object definition
        Write-Verbose "------------------------------------"
        # Instantiate new SqlConnection object
        $conn = New-Object System.Data.SqlClient.SqlConnection
        # Set the SqlConnection object's string to the passed value
        $conn.ConnectionString = $conStr
        Write-Verbose $conn.ConnectionString

        try {
            Write-Verbose $cmdText
	        Write-Verbose "Opening SQL Connection..."
            $conn.Open()
            Write-Verbose "Connection Stablish"

	        $cmd = $conn.CreateCommand()
            Write-Verbose "Creating SQL Command..." 
            $cmd.CommandText = $cmdText
	        Write-Verbose "Executing SQL Command..."
            $cmd.ExecuteNonQuery() | out-null
            Write-Verbose "Query executed"

        } catch [Exception] {
            echo echo $_.Exception|format-list -force
        } finally { 
            # Determine if the connection was opened. 
            if ($conn.State -eq "Open") 
            { 
                Write-Verbose "Closing Connection..." 
                # Close the currently open connection. 
                $conn.Close()
                Write-Verbose "Connection closed"
            } 
        } 	

    }
}

# =======================================================================
# PROCESS
# =======================================================================
$Rundate = Get-Date
$ComputerName = $env:COMPUTERNAME

# Specify SQL Connection String..............................................................................................
# Case SQL Server isolated (SQL Authentication, plaintext)
$conStr = “Data Source=$DBServer; Initial Catalog=$DBName; Integrated Security=False; User ID=$DBUser; Password = $DBPasswd”
# ...........................................................................................................................
   
$OSInfo = Get-WmiObject Win32_OperatingSystem #Get OS Information
$LastBootUpTime = $OSInfo.ConverttoDateTime($OSInfo.LastBootUpTime)
$ProcessorStats = Get-WmiObject win32_processor
Get-Ciminstance Win32_OperatingSystem

#Processor
Write-Verbose "======================================================"
#$ProcessorTime = [double][math]::round((Get-Counter -Counter "\processor(_total)\% processor time" -SampleInterval 5 -MaxSamples 10).CounterSamples.CookedValue,2) #Acceptable: below 85%. Last 5sec, 10 meassures
$ProcessorTime = $ProcessorStats.LoadPercentage
Write-Verbose "ProcessorTime: $ProcessorTime"
#$ProcessorQueueLength = [double][math]::round((Get-Counter -Counter "\System\Processor Queue Length").CounterSamples.CookedValue,2) #Acceptable: less than 10
#Write-Verbose "ProcessorQueueLength: $ProcessorQueueLength"

#Memory
#gwmi -Class win32_operatingsystem | Select-Object @{Name = "MemoryUsage"; Expression = { “{0:N2}” -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize) } }
Write-Verbose "======================================================"
$MemoryPhysicalMB = [double][math]::round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory /1GB,0)
Write-Verbose "MemoryPhysicalMB: $MemoryPhysicalMB"
#$MemoryAvailableMB = (Get-Counter -Counter "\Memory\Available MBytes").CounterSamples | select CookedValue #Acceptable: Not fall below 5% total
#[double]$MemoryAvailableMB = ($MemoryAvailableMB).CookedValue
$MemoryAvailableMB = $OSInfo.FreePhysicalMemory
Write-Verbose "MemoryAvailableMB: $MemoryAvailableMB"
$MemoryInUseMB = $MemoryPhysicalMB - $MemoryAvailableMB
Write-Verbose "MemoryInUseMB: $MemoryInUseMB"
$MemoryPercentUsed = "{0:N2}" -f $MemoryAvailableMB
Write-Verbose "MemoryPercentUsed = $MemoryPercentUsed"
Write-Verbose "#################################################################"
Write-Verbose "Writting down to db.."
$cmdTextSrvPeaks = "INSERT ServerPeaksCAP(Rundate, ComputerName, LastBootUpTime, ProcessorTime, MemoryPhysicalMB, MemoryAvailableMB, MemoryInUseMB, MemoryPercentUsed) `
                        VALUES ('$rundate', '$ComputerName', '$LastBootUpTime', '$ProcessorTime', '$MemoryPhysicalMB', '$MemoryAvailableMB', '$MemoryInUseMB'. '$MemoryPercentUsed' )"
# Adding Proc/Mem values to database - ServerPeaksCAP table
ExecNonQuery -conStr $conStr -cmdText $cmdTextSrvPeaks
Write-Verbose "#################################################################"

#Disk - {0:###0.00}
#Get-WmiObject -Class win32_Volume -ComputerName $_ -Filter "DriveLetter = 'C:'" | Select-object @{Name = "C PercentFree"; Expression = { “{0:N2}” -f (($_.FreeSpace / $_.Capacity)*100) } }
Write-Verbose "======================================================"
$Drives = Get-PSDrive -PSProvider FileSystem | Where { $_.used } # We only take into account Local Drives
Foreach ($Drive in $Drives) {
    #Write-Verbose "DiskUsed($Drive): $DiskUsed"
    $DiskUsed = [math]::round($Drive.used/1gb,2)
    #$DiskFree = (Get-Counter -Counter "\LogicalDisk(*)\% Free Space").CounterSamples.CookedValue
    $DiskFree = [math]::round($Drive.free/1gb,2)
    $DiskCapacity = [math]::round([float]$DiskUsed+$DiskFree,2)
    Write-Verbose "DiskCapacity($Drive): $DiskCapacity"
    Write-Verbose "DiskFree($Drive): $DiskFree"
    $DiskPctFree= [math]::round($Drive.free/($Drive.free+$Drive.used)*100 –as [float],2)
    Write-Verbose "DiskPctFree($Drive): $DiskPctFree"
    $FormatedDrive = $Drive.Name + ":"
    #DiskActivity - Logical
    $LogPctDiskReadTime = [math]::round((Get-Counter -Counter "\LogicalDisk($FormatedDrive)\% Disk Read Time").CounterSamples.CookedValue,2)
    Write-Verbose "LogPctDiskReadTime($FormatedDrive): $LogPctDiskReadTime"
    $LogPctDiskWriteTime = [math]::round((Get-Counter -Counter "\LogicalDisk($FormatedDrive)\% Disk Write Time").CounterSamples.CookedValue,2)
    Write-Verbose "LogPctDiskWriteTime($FormatedDrive): $LogPctDiskWriteTime"
    $LogPctDiskTime = [math]::round((Get-Counter -Counter "\LogicalDisk($FormatedDrive)\% Disk Time").CounterSamples.CookedValue,2)
    Write-Verbose "LogPctDiskTime($FormatedDrive): $LogPctDiskTime"
    $LogPctIdleTime = [math]::round((Get-Counter -Counter "\LogicalDisk($FormatedDrive)\% Idle Time").CounterSamples.CookedValue,2)
    Write-Verbose "LogPctIdleTime($FormatedDrive): $LogPctIdleTime"
    $LogCurrentDiskQueueLength = [math]::round((Get-Counter -Counter "\LogicalDisk($FormatedDrive)\Current Disk Queue Length").CounterSamples.CookedValue,2)
    Write-Verbose "LogCurrentDiskQueueLength($FormatedDrive): $LogCurrentDiskQueueLength"
    $LogDiskReads = [math]::round((Get-Counter -Counter "\LogicalDisk($FormatedDrive)\Disk Reads/sec").CounterSamples.CookedValue,2)
    Write-Verbose "LogDiskReads($FormatedDrive): $LogDiskReads"
    $LogDiskWrites = [math]::round((Get-Counter -Counter "\LogicalDisk($FormatedDrive)\Disk Writes/sec").CounterSamples.CookedValue,2)
    Write-Verbose "LogDiskWrites($FormatedDrive): $LogDiskWrites"
    $LogSplitIO = [math]::round((Get-Counter -Counter "\LogicalDisk($FormatedDrive)\Split IO/Sec").CounterSamples.CookedValue,2)
    Write-Verbose "LogSplitIO($FormatedDrive): $LogSplitIO"

    #Drive line to add to query
    $cmdTextDiskPeaks = "INSERT DiskPeaksCAP(Rundate, ComputerName, Drive, DiskUsed, DiskFree, DiskCapacity, DiskPctFree, "
    $cmdTextDiskPeaks = $cmdTextDiskPeaks + "LogPctDiskReadTime, LogPctDiskWriteTime, LogPctDiskTime, LogPctIdleTime, LogCurrentDiskQueueLength, "
    $cmdTextDiskPeaks = $cmdTextDiskPeaks + "LogDiskReads, LogDiskWrites, LogSplitIO) "
    $cmdTextDiskPeaks = $cmdTextDiskPeaks + "VALUES ('$rundate', '$ComputerName', '$Drive', '$DiskUsed', '$DiskFree', '$DiskCapacity', "
    $cmdTextDiskPeaks = $cmdTextDiskPeaks + "'$DiskPctFree ', '$LogPctDiskReadTime', '$LogPctDiskWriteTime', '$LogPctDiskTime', '$LogPctIdleTime', "
    $cmdTextDiskPeaks = $cmdTextDiskPeaks + "'$LogCurrentDiskQueueLength', '$LogDiskReads', '$LogDiskWrites', '$LogSplitIO' )"
    
    # Adding Disk values to database - DiskPeaksCAP table
    ExecNonQuery -conStr $conStr -cmdText $cmdTextDiskPeaks
    Write-Verbose "Drive $Drive completed"
    Write-Verbose "======================================================"
}