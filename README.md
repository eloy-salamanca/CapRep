# CapRep

When it comes to controlling the growth of Windows Systems it's not an easy one, especially if you want to keep it simple, fast and cheap.

As I'm been requested to summarize this info several times a year in specific reports, I decided to try and automate this process as much as possible.

I designed 3 PowerShell scripts:

Set-CapRepDB.ps1: To create a new db on selected SQL Server almost automatically.
Set-ServerCapRep.ps1: To deploy a PowerShell agent massively on every single Windows System and schedule intervals to run.
Add-DataServerPeakAgent.ps1: Agent on every Windows System to push data into db at scheduled times

The goal is to present all this information on PowerBI, to get nice visuals and analytics, and even download into excel file for reporting, for example.

for more information and detailed steps to implement this, check out my blog: https://eloysalamanca.es
