Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
trap {
    Write-Host "ERROR: $_"
    ($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$', 'ERROR: $1' | Write-Host
    ($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$', 'ERROR EXCEPTION: $1' | Write-Host
    Exit 1
}

# remove the sshd host keys.
Write-Host 'Removing the sshd host keys...'
Remove-Item -Force C:\ProgramData\ssh\ssh_host_*

# reset cloudbase-init.
Write-Host 'Resetting cloudbase-init...'
Remove-Item 'C:\Program Files\Cloudbase Solutions\Cloudbase-Init\log\*.log'

# create the sysprep unattended.xml file.
$unattendPath = 'C:/Windows/System32/Sysprep/provision-generalize-unattended.xml'
# see https://github.com/rgl/vagrant-windows-sysprep/blob/master/lib/vagrant-windows-sysprep/unattend.xml
Set-Content -Encoding UTF8 -Path $unattendPath -NoNewLine -Value @"
<?xml version="1.0" encoding="utf-8"?>
<!--
    sysprep copies this file to C:\Windows\Panther\unattend.xml
    the logs are stored at C:\Windows\Panther\setupact.log
-->
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="generalize">
        <component name="Microsoft-Windows-Security-SPP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SkipRearm>1</SkipRearm>
        </component>
        <component name="Microsoft-Windows-PnpSysprep" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <PersistAllDeviceInstalls>true</PersistAllDeviceInstalls>
            <DoNotCleanUpNonPresentDevices>true</DoNotCleanUpNonPresentDevices>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Home</NetworkLocation>
                <ProtectYourPC>1</ProtectYourPC>
            </OOBE>
        </component>
    </settings>
</unattend>
"@

# sysprep the machine.
# see https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-states?view=windows-10
Write-Host 'Syspreping the machine...'
C:/Windows/System32/Sysprep/Sysprep.exe `
    /mode:vm `
    /oobe `
    /generalize `
    /quiet `
    /quit `
    "/unattend:$unattendPath" `
    | Out-String -Stream
