#Load the Exchange cmdlets if they aren't available yet. Snap-ins are legacy, Add-PSSnapin doesn't exist in PowerShell 7
#and Exchange 2010 and up ship RemoteExchange.ps1 instead of a snap-in
if (-not (Get-Command -Name Get-ReceiveConnector -ErrorAction SilentlyContinue)) {
    try {
        . (Join-Path -Path $env:ExchangeInstallPath -ChildPath 'bin\RemoteExchange.ps1')
        Connect-ExchangeServer -Auto -ErrorAction Stop
    }
    catch {
        Write-Warning ('Could not load the Exchange cmdlets, run this script from the Exchange Management Shell instead, exiting...')
        return
    }
}
 
#Set variables
$receiveconnector = Get-ReceiveConnector | Out-GridView -OutputMode Single -Title 'Please select the Receive Connector to copy the settings from and click OK'
$newserver = Get-ExchangeServer | Out-GridView -OutputMode Single -Title 'Please select destination server to create the Receive Connector on and click OK'
 
#Set the options for creating the Receive Connector
$options = @{
    Bindings             = $receiveconnector.Bindings
    Enabled              = $receiveconnector.Enabled
    MaxHopCount          = $receiveconnector.MaxHopCount
    MaxLocalHopCount     = $receiveconnector.MaxLocalHopCount
    MaxMessageSize       = $receiveconnector.MaxMessageSize
    MessageRateLimit     = $receiveconnector.MessageRateLimit
    Name                 = $receiveconnector.Identity.Name
    PermissionGroups     = $receiveconnector.PermissionGroups.ToString().Split(',')[0]
    ProtocolLoggingLevel = $receiveconnector.ProtocolLoggingLevel
    RemoteIPRanges       = $receiveconnector.RemoteIPRanges
    Server               = $newserver
    SizeEnabled          = $receiveconnector.SizeEnabled
    TransportRole        = $receiveconnector.TransportRole
    Usage                = 'Custom'
    WhatIf               = $True
     
}
 
#Create new Receive Connector and copy the settings from the existing one
New-ReceiveConnector @options