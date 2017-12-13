<#-----------------------------------------------------------------------------
Capacity Planning Data Gathering

Eloy Salamanca | IT-Consultant & Technical Advisor
@EloySalamancaR

Part of Capacity Planning Auto Populated REPort

Generated on: 23/11/2017

-----------------------------------------------------------------------------#>

<#
.SYNOPSIS
    Set-ServerCapRep.ps1 retrieves basic system information from servers and
    install every single agent to pull data at scheduled times.
.DESCRIPTION
	Set-ServerCapRep.ps1 uses CIM/WMI to retrieve system information from servers.
    Also, uses ADO.NET to push all this information in a SQL Server
    
    Then, Set-ServerCapRep.ps1 install Add-DataServerPeakAgent.ps1 on every
    single server and schedule apropiate timeslot to push data in SQL Server

.PARAMETER <file>
	File name containing servers list to gather data.

.PARAMETER <drivetype>
	3 is a fixed disk, 2 is removable disk. 
    See Win32_LogicalDisk documentation for a list of values.

.PARAMETER <InstallAgent>
    Include installation and scheduling of agent in all servers list.

.EXAMPLE
	Set-ServerCapRep.ps1 -verbose

.NOTES
	Name                : Set-ServerCapRep.ps1
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
   to save performance information of single servers into SQL Server.
#>
[CmdletBinding()]
param (
    [Parameter(HelpMessage="Enter file name with servers list to query")]
    [string]$file=".\Servers.txt",

    [ValidateSet(2,3)]
    [Alias('dt')]
    [int]$drivetype = 3,

    [string]$DBServer = "localhost",

    [bool]$InstallAgent = $true
)
# =======================================================================
# FUNCTIONS
# =======================================================================
Function ExecNonQuery 
{
    param ($conStr, $cmdText) 
 
    # Checking for parameters. 
    if (!$conStr -or !$cmdText) { 
        # One or more parameters didn't contain values. 
        Write-Host "ExecNonQuery function called with no connection string and/or command text." 
    } else { 

        #ADO.NET object definition
        $conn = New-Object System.Data.SqlClient.SqlConnection($conStr)

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
Function Install-Agent
{
    param ($srv)

    $SourceAgentFile = '.\Add-DataServerPeakAgent.ps1'
    $DestinationAgentFile = '\\$srv\c$\SoftwareBase\CapRep\Add-DataServerPeakAgent.ps1'
    $DestinationAgentPath = '\\$srv\c$\SoftwareBase\CapRep'
    
    # read-host -prompt "Enter password to be encrypted in mypassword.txt" -assecurestring | convertfrom-securestring | out-file 'H:\DEV\PS\CapRep\securestring.txt'
    $pass = cat '.\securestring.txt' | convertto-securestring
    $mycred = new-object -typename System.Management.Automation.PSCredential -argumentlist "AdmSalamaE@gstwdt.local",$pass

    # Checking for parameter.
    if (!$srv) { 
        # One or more parameters didn't contain values. 
        Write-Host "Install-Agent function called with no server destination." 
    } else {     
        # Copying and Scheduling Agent
        Write-Verbose "Stage-2: Copying Agent to $srv"
        Write-Verbose "Check for SoftwareBase directory"
        If (!(Test-Path "\\$srv\c$\SoftwareBase")) {
            Invoke-Command -ComputerName $srv -Credential $mycred -ScriptBlock { New-Item -Path "C:\SoftwareBase" -ItemType Directory -Force } 
            Write-Verbose "C:\SoftwareBase Directory created on $srv"
        }
        Write-Verbose "Check for CapRep directory"
        If (!(Test-Path $DestinationAgentPath)) {
            Write-Verbose "Creating CapRep Directory on $srv"
            Invoke-Command -ComputerName $srv -Credential $mycred -ScriptBlock { New-Item -Path "C:\SoftwareBase\CapRep" -ItemType Directory -Force }
            Write-Verbose "CapRep Directory created on $srv"
        }
        If (Test-Path $DestinationAgentFile) {
            $RemoteAgentHash = (Get-FileHash $DestinationAgentFile).hash
            $LocalAgentHash = (Get-FileHash $SourceAgentFile).hash
            If (!($RemoteAgentHash -match $LocalAgentHash)) {
                Write-Verbose "Removing old version"
                Remove-Item $DestinationAgentFile -Force
                Write-Verbose "Copying new version agent script"
                #Copy-Item -path $SourceAgentFile -Destination $DestinationAgentPath
                New-PSDrive -Name X -PSProvider FileSystem -Root \\$srv\c$\SoftwareBase\CapRep\
                Copy-Item $SourceAgentFile X:\
                Remove-PSDrive X
            } Else {
                Write-Verbose "Nothing to do, newest agent script already in place"
            }
        } Else {
            Write-Verbose "Copying last version agent script"
            #Copy-Item -path $SourceAgentFile -Destination $DestinationAgentPath
            New-PSDrive -Name X -PSProvider FileSystem -Root \\$srv\c$\SoftwareBase\CapRep\
            Copy-Item $SourceAgentFile X:\
            Remove-PSDrive X
        }
        # Setting Scheduling Agent: Morning - Afternoon - Nigth (Off Business hours)
        Invoke-Command -ComputerName $srv -Credential $mycred -ScriptBlock { schtasks /create /tn 1CapRepAgent_Nigth /tr "powershell -NoLogo -WindowStyle hidden -file C:\SoftwareBase\CapRep\Add-DataServerPeakAgent.ps1" /sc DAILY /st 02:00 /ru SYSTEM }
        Invoke-Command -ComputerName $srv -Credential $mycred -ScriptBlock { schtasks /create /tn 2CapRepAgent_Morning /tr "powershell -NoLogo -WindowStyle hidden -file C:\SoftwareBase\CapRep\Add-DataServerPeakAgent.ps1" /sc DAILY /st 10:00 /ru SYSTEM }
        Invoke-Command -ComputerName $srv -Credential $mycred -ScriptBlock { schtasks /create /tn 3CapRepAgent_Afternoon /tr "powershell -NoLogo -WindowStyle hidden -file C:\SoftwareBase\CapRep\Add-DataServerPeakAgent.ps1" /sc DAILY /st 16:00 /ru SYSTEM }
    }
}    
# =======================================================================
# PROCESS
# =======================================================================
#$date = (Get-Date -Format ‘yyyyMMddHHmmss’).ToString()
$date = Get-Date
$servers = Get-Content $file
$TotalServers = $Servers.count
$Count = 1
$Message = "Deploying Add-DataServerPeakAgent on Servers list..."

# Specify SQL Connection String..............................................................................................
# Case that SQL Server joined to domain
#$conStr = “Data Source=$DBServer; Initial Catalog=CAPRep; Integrated Security=SSPI”
# ...........................................................................................................................
# Case SQL Server isolated (SQL Authentication, plaintext)
$DBName = "CapRep"
$DBUser = "CapRepUser"
$DBPasswd = "C4p4c1tyPl4n01"
$conStr = “Data Source=$DBServer; Initial Catalog=$DBName; Integrated Security=False; User ID=$DBUser; Password = $DBPasswd”
# ...........................................................................................................................
   
foreach ($server in $servers) {
    Try { 
        # CountDown: <http://community.spiceworks.com/scripts/show/1712-start-countdown>
        Write-Progress -Id 1 -Activity $Message -Status "Deploying Agent on $TotalServers servers, $($TotalServers - $Count) left, currently on: $server" -PercentComplete (($Count / $TotalServers) * 100)
        Write-Verbose "Trying with $server.."
        
        Test-Connection $server -Count 1 -ErrorAction Stop | Out-Null

        # SERVER-INFORMATION#################################################################################################
        Write-Verbose "Getting Server information..."
        $ComputerName = $server
        $ComputerInfo = Get-WmiObject Win32_ComputerSystem -ComputerName $server #Get Computer Information
        $OSInfo = Get-WmiObject Win32_OperatingSystem -ComputerName $server #Get OS Information
        $BIOSInfo = Get-WmiObject Win32_BIOS -ComputerName $server #Get BIOS Information

        #Network information
        #$Networks = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $server | ? {$_.IpEnabled}
        #$ActiveIPs = $Networks.IPAddress[0] + "---" + $Networks.MACAddress[0]
        $NICs = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=$true -ComputerName $server | Select-Object -Property [a-z]* -ExcludeProperty IPX*,WINS*
        Foreach ($NIC in $NICs) {
            $NICIndex = $NIC.Index
            $NICDescription = $NIC.Description
            $NICDHCPEnabled = $NIC.DHCPEnabled
            $NICDHCPServer = $NIC.DHCPServer
            $NICDNSServerSearchOrder = $NIC.DNSServerSearchOrder
            $NICDNSSuffixSearchOrder = $NIC.DNSSuffixSearchOrder
            $NICIpAddress = $NIC.IpAddress
            $NICDefaultGateway = $NIC.DefaultGateway
            $NICIPSubnet = $NIC.IPSubnet
            $NICMACAddress = $NIC.MACAddress

            # Each NIC will be a record onto ServerNICsCAP
            $cmdTextServerNICs = "INSERT ServerNICsCAP(Rundate, ComputerName, NICIndex, NICDescription, NICDHCPEnabled, NICDHCPServer, NICDNSServerSearchOrder, NICDNSSuffixSearchOrder, `
                                               NICIpAddress, NICDefaultGateway, NICIPSubnet, NICMACAddress) `
                              VALUES ('$date', '$ComputerName', $NICIndex, '$NICDescription', '$NICDHCPEnabled', '$NICDHCPServer', '$NICDNSServerSearchOrder', '$NICDNSSuffixSearchOrder', `
                                  '$NICIpAddress', '$NICDefaultGateway', '$NICIPSubnet', '$NICMACAddress' )"

            # Adding Server values to database - ServerCap Table
            Write-Verbose "Stage-1: Saving Network Information into ServerNICsCAP Table"
            ExecNonQuery -conStr $conStr -cmdText $cmdTextServerNICs
        }

        $SerialNumber = $BIOSInfo.SerialNumber
        $BIOSVersion = $BIOSInfo.SMBIOSBIOSVersion
        $Domain = $ComputerInfo.Domain
        $Model = $ComputerInfo.Model
        $OSName = $OSInfo.Caption
        $OSVersion = $OSInfo.Version 
        $OSServicePack = $OSInfo.CSDVersion
        $OSSerialNumber = $OSInfo.SerialNumber
        $LastBootUpTime = $OSInfo.ConverttoDateTime($OSInfo.LastBootUpTime)

        $CPUInfo = Get-WmiObject Win32_Processor -ComputerName $server #Get CPU Information
        
        If ($Model -like '*Virtual*') {
            $ProcessorType = $CPUInfo.Name
            $ProcessorModel = $CPUInfo.Description
            $ProcessorCores = $CPUInfo.NumberOfCores
            $ProcessorInUse = $CPUInfo.LoadPercentage
            $ProcessorPhysical = 0
        } else {
            If ($CPUInfo.Count) {
                $ProcessorType = $CPUInfo[0].Name
                $ProcessorModel = $CPUInfo[0].Description
                $ProcessorCores = $CPUInfo[0].NumberOfLogicalProcessors
                $ProcessorInUse = $CPUInfo.LoadPercentage
                $ProcessorPhysical = $CPUInfo.Count
            } else {
                $ProcessorType = $CPUInfo.Name
                $ProcessorModel = $CPUInfo.Description
                $ProcessorCores = $CPUInfo.NumberOfLogicalProcessors
                $ProcessorInUse = $CPUInfo.LoadPercentage
                $ProcessorPhysical = 1
            }          
        }

        #Get Memory Information. 
        $MemoryPhysicalMB = Get-WmiObject CIM_PhysicalMemory -ComputerName $server | Measure-Object -Property capacity -Sum | % { [Math]::Round(($_.sum / 1MB), 2) }
        $MemoryInUseMB = [math]::Round((Get-WmiObject win32_operatingSystem -ComputerName $server).FreephysicalMemory/1KB,0)

        $ServerDisks = Get-WmiObject win32_logicaldisk -ComputerName GSTSX001 -Filter "Drivetype=3" -ErrorAction SilentlyContinue
        $StoragePhysicalGB = 0
        $StorageInUseGB = 0
        Foreach ($ServerDisk in $ServerDisks) {
            $DiskSize = $ServerDisk.Size / 1gb
            $DiskFree = $ServerDisk.Freespace / 1gb
            $StoragePhysicalGB += $DiskSize
            $StorageInUseGB += $DiskFree
        }

        $cmdTextServer = "INSERT ServerCAP(Rundate, ComputerName, SerialNumber, BIOSVersion, Domain, Model, OSName, OSVersion, OSServicePack, OSSerialNumber, `
                                           LastBootUpTime, ProcessorType, ProcessorModel, ProcessorCores, ProcessorInUse, ProcessorPhysical, `
                                           MemoryPhysicalMB, MemoryInUseMB, StoragePhysicalGB, StorageInUseGB) `
                          VALUES ('$date', '$ComputerName', '$SerialNumber', '$BIOSVersion', '$Domain', '$Model', '$OSName', `
                                  '$OSVersion', '$OSServicePack', '$OSSerialNumber', '$LastBootUpTime', '$ProcessorType', '$ProcessorModel', `
                                  '$ProcessorCores', '$ProcessorInUse', '$ProcessorPhysical', '$MemoryPhysicalMB', '$MemoryInUseMB', `
                                  '$StoragePhysicalGB', $StorageInUseGB )"
    
    } Catch {
        $ServersDown += $server
        Throw "Server $Server is not reachable. Leaving it from the process. Adding it to Servers Down"
    }

    # Adding Server values to database - ServerCap Table
    Write-Verbose "Stage-2: Saving Server Information data to ServerCAP table"
    ExecNonQuery -conStr $conStr -cmdText $cmdTextServer

    # Installing and Scheduling Agent
    Write-Verbose "Stage-3: Checking and deploying agent if needed"
    If ($InstallAgent) {
        Install-Agent -Srv $server
    }
    $Count++
}
Write-Progress -Id 1 -Activity $Message -Status "Completed" -PercentComplete 100 -Completed
Write-Verbose "List of Servers Down: $ServersDown"
Write-Verbose "==> Set-ServerCapRep Finished"