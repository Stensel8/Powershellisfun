#Set the output location for .csv file
$output = 'd:\temp\ssid_passwords.csv'
 
#Retrieve all WLAN profiles, loop through them and try to get the passsword
$wlanprofiles = (netsh wlan show profiles) | Select-String ': '
if ($null -ne $wlanprofiles) {
    $passwords = foreach ($wlanprofile in $wlanprofiles | Sort-Object) {
        try {
            $profile_information = netsh wlan show profile name="$($wlanprofile.ToString().Split(':')[1].Substring(1))" key=clear
            Write-Host ("Retrieving password for SSID {0}" -f $wlanprofile.ToString().Split(':')[1].Substring(1)) -ForegroundColor Green
            [PSCustomObject]@{
                'SSID'                = $wlanprofile.ToString().Split(':')[1].Substring(1)
                'Authentication Type' = ($profile_information | Select-String 'Authentication' | Select-Object -First 1).ToString().Split(':')[1].Substring(1)
                'Password'            = ($profile_information | Select-String 'Key Content').ToString().Split(':')[1].Substring(1)
            }
        }
        catch {
            #If retrieving the password fails, add the reason why to $passwords in the password field
            $authenticationtype = ($profile_information | Select-String 'Authentication' | Select-Object -First 1).ToString().Split(':')[1].Substring(1)
            Write-Warning ("Could not retrieve password for SSID {0}, check {1}" -f $wlanprofile.ToString().Split(':')[1].Substring(1), $output)
            [PSCustomObject]@{
                'SSID'                = $wlanprofile.ToString().Split(':')[1].Substring(1)
                'Authentication Type' = ($profile_information | Select-String 'Authentication' | Select-Object -First 1).ToString().Split(':')[1].Substring(1)
                'Password'            = "Could not retrieve password for the SSID because it's an $($authenticationtype) network"
            }
        }
    }
     
    #Export to $output path and open Excel (Or prompt to associate the .csv file, choose Notepad/Wordpad etc. to view the contents)
    $passwords | Export-Csv -NoTypeInformation -Encoding UTF8 -Delimiter ';' -Path $output
    Invoke-Item $output
}
else {
    Write-Warning ("No WLAN profiles found, please check if {0} has a Wi-Fi adapter or any saved networks" -f $env:COMPUTERNAME)
}