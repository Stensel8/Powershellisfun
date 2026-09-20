#Set CSV location
$csvlocation = 'c:\temp\Microsoft.Graph.Cmdlets.csv'
 
#Get a list of all available Microsoft.Graph modules
Write-Host ("Getting a list of available online Microsoft.Graph modules...") -ForegroundColor Green
$OnlineMicrosoftGraphModules = Find-PSResource -Name Microsoft.Graph* | Where-Object Name -NotMatch 'Microsoft.Graph.PlusPlus' | Sort-Object Name
 
#Get a list of all installed Microsoft.Graph Modules
Write-Host ("Getting a list of installed Microsoft.Graph modules...") -ForegroundColor Green
$InstalledMicrosoftGraphModules = Get-InstalledPSResource -Name Microsoft.Graph* -ErrorAction SilentlyContinue | Sort-Object Name -Unique
 
#Install and import all Microsoft.Graph modules except the PlusPlus module which is for AzureAD 'work or school' accounts and 'personal' Microsoft accounts
Write-Host ("Installing all Microsoft.Graph Modules but skipping is already installed...") -ForegroundColor Green
foreach ($module in $OnlineMicrosoftGraphModules) {
    if ($module.Name -notin $InstalledMicrosoftGraphModules.Name) {
        Write-Host ("Installing {0}..." -f $module.Name)-ForegroundColor Green
        Install-PSResource -Name $module.Name -TrustRepository:$true -ErrorAction SilentlyContinue
    }
}
 
#Resfresh the list of all installed Microsoft.Graph Modules after installing all Microsft Graph modules
Write-Host ("Resfreshing the list of installed Microsoft.Graph modules...") -ForegroundColor Green
$InstalledMicrosoftGraphModules = Get-InstalledPSResource -Name Microsoft.Graph* -ErrorAction SilentlyContinue | Sort-Object Name -Unique
 
#Remove oldest version of Microsoft.Graph modules if there are more versions installed
Foreach ($Module in $InstalledMicrosoftGraphModules | Sort-Object Name) {
    Write-Host ("Checking for older versions of the {0} PowerShell Module and removing older versions if found..." -f $Module.Name) -ForegroundColor Green
    $AllVersions = Get-InstalledPSResource -Name $Module.Name -ErrorAction:SilentlyContinue | Sort-Object Version -Descending
    $MostRecentVersion = $AllVersions[0].Version
    if ($AllVersions.Count -gt 1 ) {
        Foreach ($Version in $AllVersions) {
            if ($Version.Version -ne $MostRecentVersion) {
                Write-Host ("Uninstalling previous version {0} of Module {1}" -f $Version.Version, $Module.Name) -ForegroundColor Yellow
                Uninstall-PSResource -Name $Module.Name -Version $Version.Version
            }
        }
    }
}
 
#retrieve all cmdlets together with the synopsis and add them to $total
$total = foreach ($module in $InstalledMicrosoftGraphModules) { 
    Write-Host ("Processing {0}..." -f $module.Name) -ForegroundColor Green
    $cmdlets = Get-Command -Module $module.Name
    foreach ($cmdlet in $cmdlets) {
        #Retrieve Synopsis (Remove Read-Only, Read-Wite, Nullable and Supports $expand if found) and URL to docs.microsoft.com for the cmdlet
        $help = Get-Help $cmdlet
        $synopsis = $help.Synopsis.Replace('Read-only.', '').Replace('Read-Write.', '').Replace('Nullable.', '').Replace('Supports $expand.', '').Replace('Not nullable.', '').Replace('\r', " ")
        $synopsis = $synopsis -replace '\n', ' ' -creplace '(?m)^\s*\r?\n', ''
        #Set variable for non matching cmdlet name and synopsis content
        $cmdletoldname = $cmdlet.Name.Replace('-', '-Mg')
        $url = $help.relatedLinks.navigationLink.uri
        #Set Synopsis or URL to "Not Available" when no data is found
        if ($null -eq $synopsis -or $synopsis.Length -le 2 -or $synopsis -match $cmdletoldname -or $synopsis -match $cmdlet.Name) { $synopsis = "Not available" }
        if ($null -eq $url) { $url = "Not available" }
        [PSCustomObject]@{
            Source   = $cmdlet.Source
            Version  = $cmdlet.Version
            Cmdlet   = $cmdlet.Name
            Synopsis = $synopsis
            URL      = $url
        }
    }
}
 
#Save all results to the CSV location specified in the variable $CSVlocation
Write-Host ("Exporting results to {0}" -f $csvlocation) -ForegroundColor Green
try {
    $total | Sort-Object Source, Cmdlet | Export-Csv -Path $csvlocation -NoTypeInformation -Delimiter ';' -Encoding UTF8
}
catch {
    Write-Warning ("Error saving results to {0}, please check if path is accessible" -f $csvlocation)
}