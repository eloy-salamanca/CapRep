--#-----------------------------------------------------------------------------
--Capacity Planning Data Gathering Database

--Eloy Salamanca | IT-Consultant & Technical Advisor
--@EloySalamancaR

--Part of Capacity Planning Auto Populated REPort

--Generated on: 12/12/2017

-----------------------------------------------------------------------------#>

--Configuring SQLServerAgent to be enabled
sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE;  
GO  
sp_configure 'Agent XPs', 1;  
GO  
RECONFIGURE  
GO 

--Creating CapRep db
CREATE DATABASE [CapRep]
GO

--Configuring permissions
USE master
CREATE LOGIN CapRepUser WITH PASSWORD = 'C4p4c1tyPl4n01'
GO

USE [CapRep]
CREATE USER CapRepUser FROM LOGIN CapRepUser
GO

ALTER ROLE db_datareader ADD MEMBER CapRepUser
GO
ALTER ROLE db_datawriter ADD MEMBER CapRepUser
GO

--######################### Generating TABLES #########################
USE [CapRep]
GO

/****** Object:  Table [dbo].[DiskCAP]    Script Date: 03/15/2017 13:53:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[DiskCAP](
	[Rundate] [datetime] NOT NULL,
	[ComputerName] [varchar](50) NOT NULL,
	[DiskDrive] [char](10) NOT NULL,
	[VolumeName] [nchar](10) NULL,
	[DiskCapacity] [float] NOT NULL,
	[DiskFree] [float] NOT NULL,
	[DiskPercentUsed] [float] NOT NULL,
	[DiskPercentFree] [float] NOT NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


USE [CapRep]
GO

/****** Object:  Table [dbo].[DiskPeaksCAP]    Script Date: 11/23/2017 11:53:57 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DiskPeaksCAP](
	[Rundate] [datetime] NOT NULL,
	[ComputerName] [varchar](50) NOT NULL,
	[Drive] [char](10) NOT NULL,
	[DiskUsed] [float] NULL,
	[DiskFree] [float] NULL,
	[DiskCapacity] [float] NULL,
	[DiskPctFree] [float] NULL,
	[LogPctDiskReadTime] [float] NULL,
	[LogPctDiskWriteTime] [float] NULL,
	[LogPctDiskTime] [float] NULL,
	[LogPctIdleTime] [float] NULL,
	[LogCurrentDiskQueueLength] [float] NULL,
	[LogDiskReads] [float] NULL,
	[LogDiskWrites] [float] NULL,
	[LogSplitIO] [float] NULL
) ON [PRIMARY]
GO

USE [CapRep]
GO

/****** Object:  Table [dbo].[EventCAP]    Script Date: 11/23/2017 11:54:25 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[EventCAP](
	[Rundate] [datetime] NOT NULL,
	[ComputerName] [varchar](50) NOT NULL,
	[LogName] [varchar](50) NOT NULL,
	[EntryType] [varchar](50) NOT NULL,
	[Source] [varchar](50) NOT NULL,
	[Message] [varchar](max) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

USE [CapRep]
GO

/****** Object:  Table [dbo].[ServerCAP]    Script Date: 11/24/2017 12:36:05 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ServerCAP](
	[Rundate] [datetime] NOT NULL,
	[ComputerName] [varchar](max) NOT NULL,
	[SerialNumber] [varchar](max) NULL,
	[BIOSVersion] [varchar](max) NULL,
	[Domain] [varchar](50) NULL,
	[Model] [varchar](max) NULL,
	[OSName] [varchar](max) NULL,
	[OSVersion] [varchar](max) NULL,
	[OSServicePack] [varchar](max) NULL,
	[OSSerialNumber] [varchar](max) NULL,
	[LastBootUpTime] [datetime] NULL,
	[ProcessorType] [varchar](max) NULL,
	[ProcessorModel] [varchar](max) NULL,
	[ProcessorCores] [int] NULL,
	[ProcessorInUse] [float] NULL,
	[ProcessorPhysical] [int] NULL,
	[MemoryPhysicalMB] [float] NULL,
	[MemoryInUseMB] [float] NULL,
	[StoragePhysicalGB] [float] NULL,
	[StorageInUseGB] [float] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


USE [CapRep]
GO

/****** Object:  Table [dbo].[ServerNICsCAP]    Script Date: 11/24/2017 12:35:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ServerNICsCAP](
	[Rundate] [datetime] NOT NULL,
	[ComputerName] [varchar](max) NOT NULL,
	[NICIndex] [int] NULL,
	[NICDescription] [varchar](max) NULL,
	[NICDHCPEnabled] [varchar](50) NULL,
	[NICDHCPServer] [varchar](50) NULL,
	[NICDNSServerSearchOrder] [varchar](max) NULL,
	[NICDNSSuffixSearchOrder] [varchar](max) NULL,
	[NICIpAddress] [varchar](max) NULL,
	[NICDefaultGateway] [varchar](50) NULL,
	[NICIPSubnet] [varchar](50) NULL,
	[NICMACAddress] [varchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


USE [CapRep]
GO

/****** Object:  Table [dbo].[ServerPeaksCAP]    Script Date: 11/28/2017 11:33:40 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ServerPeaksCAP](
	[Rundate] [datetime] NOT NULL,
	[Computername] [varchar](50) NOT NULL,
	[LastBootUpTime] [datetime] NULL,
	[ProcessorTime] [float] NULL,
	[ProcessorQueueLength] [float] NULL,
	[MemoryPhysicalMB] [float] NULL,
	[MemoryAvailableMB] [float] NULL,
	[MemoryInUseMB] [float] NULL,
	[MemoryPercentUsed] [float] NULL
) ON [PRIMARY]
GO


USE [CapRep]
GO

/****** Object:  Table [dbo].[TotalCAP]    Script Date: 11/23/2017 11:58:11 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TotalCAP](
	[Rundate] [datetime] NOT NULL,
	[TimeToEnd] [datetime] NULL,
	[TotalServer] [int] NOT NULL,
	[TotalServerInUse] [int] NULL,
	[TotalServerTrend] [float] NULL,
	[TotalCores] [float] NOT NULL,
	[TotalCoresInUse] [float] NULL,
	[TotalCoresOverhead] [float] NULL,
	[TotalCoresTrend] [float] NULL,
	[TotalMemoryMB] [float] NOT NULL,
	[TotalMemoryInUseMB] [float] NULL,
	[TotalMemoryOverhead] [float] NULL,
	[TotalMemoryTrend] [float] NULL,
	[TotalStorageGB] [float] NOT NULL,
	[TotalStorageInUseGB] [float] NULL,
	[TotalStorageOverhead] [float] NULL,
	[TotalStorageTrend] [float] NULL
) ON [PRIMARY]
GO