function Set-IISSMTPRelayRestrictions {
    param (
        [parameter(Mandatory = $true)][string]$CSVFile
    )
    
    #Check if CSV file is present and accessible
    try {
        $IPAddresses = Import-Csv -Path $CSVFile -Delimiter ';'
        Write-Host ("{0} found, continuing..." -f $CSVFile) -ForegroundColor Green
    }
    catch {
        Write-Warning ("{0} not found or not accessible, exiting..." -f $CSVFile)
        return
    }

    #Setting up variables needed
    $ipblock = @(24, 0, 0, 128,
        32, 0, 0, 128,
        60, 0, 0, 128,
        68, 0, 0, 128,
        1, 0, 0, 0,
        76, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
        1, 0, 0, 0,
        0, 0, 0, 0,
        2, 0, 0, 0,
        1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 76, 0, 0, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 255, 255)
    $ipList = @()
    $octet = @()

    #Loop through the list of Single IP-Adresses and add them to the Relay Restrictions
    foreach ($network in $IPAddresses | Where-Object RangeFormat -eq SingleAddress) {
        $ipList = $Network.Expression
        $octet += $ipList.Split(".")
        $ipblock[36] += 1
        $ipblock[44] += 1   
    }

    #Add the ip-adresses to the list. Get-CimInstance/Set-CimInstance replace the deprecated Get-WmiObject and its .Put() method
    $smtpserversetting = Get-CimInstance -Namespace 'root\MicrosoftIISv2' -Query 'Select * from IIsSmtpServerSetting'
    $ipblock += $octet
    $smtpserversetting | Set-CimInstance -Property @{RelayIpList = $ipblock }
    Write-Host ("Added the IP-Adresses to the Relay Restrictions list") -ForegroundColor Green

}