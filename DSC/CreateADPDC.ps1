configuration CreateADPDC
{
   param
   (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    Import-DscResource -ModuleName xActiveDirectory, xStorage, xNetworking, xComputerManagement, PSDesiredStateConfiguration, xPendingReboot
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $Interface=Get-NetAdapter|Where Name -Like "Ethernet*"|Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature DNS
        {
            Ensure = "Present"
            Name = "DNS"
        }

        Script EnableDNSDiags
        {
      	    SetScript = {
                Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics"
            }
            GetScript =  { @{} }
            TestScript = { $false }
            DependsOn = "[WindowsFeature]DNS"
        }

        WindowsFeature DnsTools
        {
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
        }

        xDnsServerAddress DnsServerAddress
        {
            Address        = '127.0.0.1'
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
            DependsOn = "[WindowsFeature]DNS"
        }

        xWaitforDisk Disk2
        {
            DiskNumber = 2
            RetryIntervalSec =$RetryIntervalSec
            RetryCount = $RetryCount
        }

        xDisk ADDataDisk {
            DiskNumber = 2
            DriveLetter = "F"
            DependsOn = "[xWaitForDisk]Disk2"
        }

        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
            DependsOn="[WindowsFeature]DNS"
        }

        WindowsFeature ADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter
        {
            Ensure = "Present"
            Name = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSTools"
        }

        xADDomain FirstDS
        {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "F:\NTDS"
            LogPath = "F:\NTDS"
            SysvolPath = "F:\SYSVOL"
            DependsOn = @("[WindowsFeature]ADDSInstall", "[xDisk]ADDataDisk")
        }

        Script InstallAADConnect {
            SetScript  = {
                $AADConnectDLUrl = "https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi"
                $exe = "$env:SystemRoot\system32\msiexec.exe"
                $webclient = New-Object System.Net.WebClient
                $iserror = $false
                
                for ($i = 1; $i -le 3; $i++) {
                    $tempfile = [System.IO.Path]::GetTempFileName()
                    if (((get-item -Path $tempfile).Length -eq "0") -or $iserror -eq $true) {
                        try {
                            $webclient.DownloadFile($AADConnectDLUrl, $tempfile)
                            $iserror = $false
                        }
                        catch {
                            $iserror = $true
                            start-sleep -s 10
                        }
                    }
                }              
                $folder = [System.IO.Path]::GetDirectoryName($tempfile)
                Rename-Item -Path $tempfile -NewName "AzureADConnect.msi"
                $MSIPath = $folder + "\AzureADConnect.msi"

                Invoke-Expression "& `"$exe`" /i $MSIPath /qn /passive /forcerestart"
            }

            GetScript  = { @{ } }
            TestScript = { 
                return Test-Path "$env:TEMP\AzureADConnect.msi" 
            }
        }

        Script Shortcuts {
            SetScript  = {   
                $WshShell = New-Object -comObject WScript.Shell
                $dt = "C:\Users\Public\Desktop\"

                $links = @(
                    @{site = "%windir%\system32\WindowsPowerShell\v1.0\PowerShell_ISE.exe"; name = "PowerShell ISE"; icon = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell_ise.exe, 0" },
                    @{site = "%SystemRoot%\system32\ServerManager.exe"; name = "Server Manager"; icon = "%SystemRoot%\system32\ServerManager.exe, 0" },
                    @{site = "%SystemRoot%\system32\gpmc.msc"; name = "Group Policy Management"; icon = "%SystemRoot%\system32\gpoadmin.dll, 0" },
                    @{site = "%SystemRoot%\system32\dsa.msc"; name = "AD Users and Computers"; icon = "%SystemRoot%\system32\dsadmin.dll, 0" },
                    @{site = "%SystemRoot%\system32\domain.msc"; name = "AD Domains and Trusts"; icon = "%SystemRoot%\system32\domadmin.dll, 0" },
                    @{site = "%SystemRoot%\system32\dnsmgmt.msc"; name = "DNS"; icon = "%SystemRoot%\system32\dnsmgr.dll, 0" },
                    @{site = "%windir%\system32\services.msc"; name = "Services"; icon = "%windir%\system32\filemgmt.dll, 0" }
                )

                foreach ($link in $links) {
                    $Shortcut = $WshShell.CreateShortcut("$($dt)$($link.name).lnk")
                    $Shortcut.TargetPath = $link.site
                    $Shortcut.IconLocation = $link.icon
                    $Shortcut.Save()
                }
            }
            GetScript  = { @{ } }
            TestScript = { 
                return $false
            }
        }

        xPendingReboot RebootAfterPromotion{
            Name = "RebootAfterPromotion"
            DependsOn = "[xADDomain]FirstDS", "[Script]InstallAADConnect", "[Script]Shortcuts"
        }

   }
}