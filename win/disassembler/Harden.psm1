##########
# Harden.psm1 - local hardening tweaks for a standalone Windows laptop.
#
# A drop-in companion library for Disassembler0's Win10-Initial-Setup-Script.
# Loaded alongside Win10.psm1 via the runner's -include switch. Follows the same
# conventions: one idempotent function per tweak, a revert twin for each, and a
# Write-Output status line as the first body statement. RequireAdmin, WaitForKey
# and Restart are provided by Win10.psm1 and are not redefined here.
#
# Configure the two blocks below, then run Harden.cmd. See README.md.
##########


##########
# Configuration - edit these.
##########

# Extra USB hardware IDs to always allow, on top of whatever is connected when
# LockUSBToWhitelist runs. Find IDs via Device Manager > device > Details >
# "Hardware Ids", or run:  LockUSBToWhitelist -DryRun
$Global:USBAllowList = @()

# Local account names. The admin account is for elevation only; day-to-day use
# happens under the standard account.
$Global:AdminUserName    = "lsa"
$Global:StandardUserName = "operator"


##########
# Internals
##########

$RestrictionsKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"
$UACKey          = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$WlanSvcKey      = "HKLM:\SYSTEM\CurrentControlSet\Services\WlanSvc"
$BthSvcKey       = "HKLM:\SYSTEM\CurrentControlSet\Services\bthserv"

# Hardware IDs of every USB-tree device currently present. Capturing these lets a
# docking station, keyboard, mouse, ethernet dongle and monitor survive an
# all-classes whitelist instead of being locked out on the next reboot.
Function Get-ConnectedUSBIDs {
	Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
		Where-Object { $_.InstanceId -like "USB\*" -or $_.Class -in @("USB","HIDClass","Keyboard","Mouse","Net","DiskDrive","Image","Monitor","Media","AudioEndpoint","USBDevice") } |
		ForEach-Object { (Get-PnpDeviceProperty -InstanceId $_.InstanceId -KeyName "DEVPKEY_Device_HardwareIds" -ErrorAction SilentlyContinue).Data } |
		Where-Object { $_ -like "USB\*" } |
		Sort-Object -Unique
}

# Hardware IDs already stored in the registry allow-list (the persistent source of
# truth). Empty if the lock has never been applied.
Function Get-AllowedUSBIDs {
	$allowKey = "$RestrictionsKey\AllowDeviceIDs"
	If (!(Test-Path $allowKey)) { Return @() }
	$props = (Get-Item -Path $allowKey).Property
	@($props | ForEach-Object { (Get-ItemProperty -Path $allowKey -Name $_).$_ } | Where-Object { $_ })
}


##########
# Tweaks
##########

# Lock USB to a whitelist (all device classes): allow specific hardware IDs, deny the
# rest. The applied list MERGES three sources: $USBAllowList (in-module), the IDs
# already in the registry (persistent across runs/reboots), and currently-connected
# devices (capture). Because it merges with the registry, you do NOT need every
# device plugged in on each run. -DryRun reviews; -NoCapture skips live capture.
Function LockUSBToWhitelist {
	Param([switch]$DryRun, [switch]$NoCapture)
	Write-Output "Locking USB to whitelist..."

	$registry  = Get-AllowedUSBIDs
	$connected = If ($NoCapture) { @() } Else { Get-ConnectedUSBIDs }
	$allow = @($Global:USBAllowList) + $registry + $connected
	$allow = $allow | Where-Object { $_ } | Sort-Object -Unique

	If ($DryRun) {
		Write-Output "  [DryRun] Sources: in-module=$(@($Global:USBAllowList).Count) registry=$($registry.Count) connected=$($connected.Count)"
		Write-Output "  [DryRun] Would allow $($allow.Count) hardware ID(s) and deny all others:"
		If ($allow.Count -eq 0) { Write-Output "    (none)" } Else { $allow | ForEach-Object { Write-Output "    $_" } }
		Write-Output "  [DryRun] Nothing written. Re-run without -DryRun to apply."
		Return
	}
	If ($allow.Count -eq 0) {
		Write-Output "  ! Allow-list is empty - refusing to apply (this would block all USB devices)."
		Write-Output "  ! To start over: run UnlockUSB, connect your devices, then run LockUSBToWhitelist."
		Return
	}

	If (!(Test-Path $RestrictionsKey)) { New-Item -Path $RestrictionsKey -Force | Out-Null }
	$allowKey = "$RestrictionsKey\AllowDeviceIDs"
	If (Test-Path $allowKey) { Remove-Item -Path $allowKey -Recurse -Force }
	New-Item -Path $allowKey -Force | Out-Null

	$i = 1
	ForEach ($id in $allow) {
		Set-ItemProperty -Path $allowKey -Name "$i" -Type String -Value $id
		$i++
	}

	Set-ItemProperty -Path $RestrictionsKey -Name "AllowDeviceIDs" -Type DWord -Value 1
	Set-ItemProperty -Path $RestrictionsKey -Name "DenyUnspecified" -Type DWord -Value 1
	Write-Output "  Allowed $($allow.Count) ID(s); all other devices denied."
	Write-Output "  Note: this gates NEW device installs. Devices already installed keep working until removed in Device Manager."
}

# Remove all USB device-installation restrictions (revert to default). Wipes the
# registry allow-list too - use RevokeUSBDevice to drop a single device instead.
Function UnlockUSB {
	Write-Output "Removing USB restrictions..."
	Remove-ItemProperty -Path $RestrictionsKey -Name "DenyUnspecified" -ErrorAction SilentlyContinue
	Remove-ItemProperty -Path $RestrictionsKey -Name "AllowDeviceIDs" -ErrorAction SilentlyContinue
	If (Test-Path "$RestrictionsKey\AllowDeviceIDs") { Remove-Item -Path "$RestrictionsKey\AllowDeviceIDs" -Recurse -Force }
}

# Onboard a new USB device without unplugging everything else: temporarily lift only
# the deny flag (the existing registry allow-list is preserved), let the device
# install cleanly so ALL its nodes enumerate (parent + interface children), then
# relock - which merges the existing list with the newly-connected device. Interactive.
Function OnboardUSBDevice {
	Write-Output "Onboarding a new USB device..."
	$wasLocked = ((Get-ItemProperty -Path $RestrictionsKey -Name "DenyUnspecified" -ErrorAction SilentlyContinue).DenyUnspecified -eq 1)

	Write-Output "  Step 1/4: UNPLUG the device you want to add (if connected), then press Enter."
	[void](Read-Host)
	# Lift ONLY the deny flag so installs are allowed; keep the allow-list intact.
	Remove-ItemProperty -Path $RestrictionsKey -Name "DenyUnspecified" -ErrorAction SilentlyContinue
	Start-Sleep -Seconds 1
	$before = @(Get-ConnectedUSBIDs)

	Write-Output "  Step 2/4: now PLUG IN the device, wait for Windows to finish installing it, then press Enter."
	[void](Read-Host)
	Clear-FailedUSBDevices | Out-Null
	Start-Sleep -Seconds 2
	$after = @(Get-ConnectedUSBIDs)

	$newIds = @($after | Where-Object { $before -notcontains $_ })
	If ($newIds.Count -eq 0) {
		Write-Output "  ! No new USB IDs detected. If the device still shows forbidden, uninstall it in"
		Write-Output "  ! Device Manager (right-click > Uninstall device), then re-run and replug at step 2."
	} Else {
		Write-Output "  Step 3/4: detected $($newIds.Count) new ID(s):"
		$newIds | ForEach-Object { Write-Output "    $_" }
	}

	If ($wasLocked) {
		Write-Output "  Step 4/4: re-applying lock (merges existing allow-list + the new device)..."
		LockUSBToWhitelist | Out-Null
		Write-Output "  Done. New device whitelisted in the registry and lock re-applied."
	} Else {
		Write-Output "  Step 4/4: USB was not locked before. Leave the device connected and run"
		Write-Output "  LockUSBToWhitelist when ready - it will capture it into the registry allow-list."
	}
}

# Remove a single hardware ID from the registry allow-list and re-write the list in
# place (no capture, so it is not re-added). Pass -Id "USB\VID_..."; omit -Id to list
# the current allow-list. To fully drop a device that is currently installed, also
# unplug it and uninstall its node in Device Manager.
Function RevokeUSBDevice {
	Param([string]$Id)
	$current = @(Get-AllowedUSBIDs)
	If (!$Id) {
		Write-Output "Registry USB allow-list (re-run with -Id <hardware id> to remove one):"
		If ($current.Count -eq 0) { Write-Output "  (empty)" } Else { $current | ForEach-Object { Write-Output "  $_" } }
		Return
	}
	Write-Output "Revoking USB device $Id..."
	$kept = @($current | Where-Object { $_ -ne $Id })
	$allowKey = "$RestrictionsKey\AllowDeviceIDs"
	If (Test-Path $allowKey) { Remove-Item -Path $allowKey -Recurse -Force }
	If ($kept.Count -gt 0) {
		New-Item -Path $allowKey -Force | Out-Null
		$i = 1
		ForEach ($k in $kept) { Set-ItemProperty -Path $allowKey -Name "$i" -Type String -Value $k; $i++ }
	}
	Write-Output "  Allow-list now has $($kept.Count) ID(s). If the device is installed, unplug it and uninstall its node in Device Manager to fully remove it."
}

# Clear USB device nodes stuck in a failed/blocked state ("forbidden by policy"), so
# they re-install cleanly on the next scan - removes the dead node via pnputil and
# rescans. Runs automatically inside OnboardUSBDevice; can also be run standalone.
Function Clear-FailedUSBDevices {
	Write-Output "Clearing failed/blocked USB device nodes..."
	$problem = @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -like "USB\*" -and $_.Status -ne "OK" })
	If ($problem.Count -eq 0) { Write-Output "  None found."; Return }
	ForEach ($d in $problem) {
		Write-Output "  Removing stuck node: $($d.FriendlyName) [$($d.InstanceId)]"
		Try {
			& pnputil /remove-device "$($d.InstanceId)" 2>&1 | Out-Null
			If ($LASTEXITCODE -ne 0) { Throw }
		} Catch {
			Write-Output "    ! Auto-removal unavailable on this build. In Device Manager: right-click the device > Uninstall device."
		}
	}
	Try { & pnputil /scan-devices 2>&1 | Out-Null } Catch { }
	Write-Output "  Rescanned for hardware changes."
}

# Disable wireless by disabling the WLAN AutoConfig service. A standard user
# cannot restart a disabled service, so this is the hardest path to bypass.
Function DisableWireless {
	Write-Output "Disabling wireless (WlanSvc)..."
	Stop-Service -Name "WlanSvc" -Force -ErrorAction SilentlyContinue
	Set-Service -Name "WlanSvc" -StartupType Disabled -ErrorAction SilentlyContinue
	Set-ItemProperty -Path $WlanSvcKey -Name "Start" -Type DWord -Value 4 -ErrorAction SilentlyContinue
}

# Re-enable wireless (restore WlanSvc to Automatic and start it).
Function EnableWireless {
	Write-Output "Enabling wireless (WlanSvc)..."
	Set-ItemProperty -Path $WlanSvcKey -Name "Start" -Type DWord -Value 2 -ErrorAction SilentlyContinue
	Set-Service -Name "WlanSvc" -StartupType Automatic -ErrorAction SilentlyContinue
	Start-Service -Name "WlanSvc" -ErrorAction SilentlyContinue
}

# Disable Bluetooth by disabling the Bluetooth Support Service. A standard user
# cannot restart a disabled service, so this is the hardest path to bypass.
Function DisableBluetooth {
	Write-Output "Disabling Bluetooth (bthserv)..."
	Stop-Service -Name "bthserv" -Force -ErrorAction SilentlyContinue
	Set-Service -Name "bthserv" -StartupType Disabled -ErrorAction SilentlyContinue
	Set-ItemProperty -Path $BthSvcKey -Name "Start" -Type DWord -Value 4 -ErrorAction SilentlyContinue
}

# Re-enable Bluetooth (restore bthserv to its default Manual/trigger startup).
Function EnableBluetooth {
	Write-Output "Enabling Bluetooth (bthserv)..."
	Set-ItemProperty -Path $BthSvcKey -Name "Start" -Type DWord -Value 3 -ErrorAction SilentlyContinue
	Set-Service -Name "bthserv" -StartupType Manual -ErrorAction SilentlyContinue
	Start-Service -Name "bthserv" -ErrorAction SilentlyContinue
}

# Create a dedicated admin account and a standard (non-admin) account, then
# disable the built-in Administrator. Prompts for passwords (never stored).
# Idempotent: existing accounts are reused, not recreated. The built-in
# Administrator is only disabled once the new admin is confirmed, to avoid lockout.
Function SetupAccountSeparation {
	Write-Output "Setting up admin / standard account separation..."

	$adminName = $Global:AdminUserName
	$stdName   = $Global:StandardUserName

	If (!(Get-LocalUser -Name $adminName -ErrorAction SilentlyContinue)) {
		$p = Read-Host "  Set a password for admin account $adminName" -AsSecureString
		$params = @{
			Name                 = $adminName
			Password             = $p
			FullName             = $adminName
			Description          = "Dedicated local administrator"
			PasswordNeverExpires = $true
			AccountNeverExpires  = $true
		}
		New-LocalUser @params | Out-Null
	}
	Add-LocalGroupMember -Group "Administrators" -Member $adminName -ErrorAction SilentlyContinue

	If (!(Get-LocalUser -Name $stdName -ErrorAction SilentlyContinue)) {
		$p = Read-Host "  Set a password for standard account $stdName" -AsSecureString
		$params = @{
			Name                 = $stdName
			Password             = $p
			FullName             = $stdName
			Description          = "Standard (non-admin) user"
			PasswordNeverExpires = $true
			AccountNeverExpires  = $true
		}
		New-LocalUser @params | Out-Null
	}
	Add-LocalGroupMember -Group "Users" -Member $stdName -ErrorAction SilentlyContinue
	Remove-LocalGroupMember -Group "Administrators" -Member $stdName -ErrorAction SilentlyContinue

	$adminConfirmed = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*\$adminName" }
	If ($adminConfirmed) {
		Disable-LocalUser -Name "Administrator" -ErrorAction SilentlyContinue
		Write-Output "  Built-in Administrator disabled; $adminName is the elevation account."
	} Else {
		Write-Output "  ! New admin account not confirmed in Administrators group - leaving built-in Administrator enabled."
	}
}

# Harden UAC: always prompt admins on the secure desktop and require standard
# users to enter credentials to elevate (no silent elevation).
Function HardenUAC {
	Write-Output "Hardening UAC..."
	Set-ItemProperty -Path $UACKey -Name "EnableLUA"                  -Type DWord -Value 1
	Set-ItemProperty -Path $UACKey -Name "ConsentPromptBehaviorAdmin" -Type DWord -Value 2
	Set-ItemProperty -Path $UACKey -Name "ConsentPromptBehaviorUser"  -Type DWord -Value 1
	Set-ItemProperty -Path $UACKey -Name "PromptOnSecureDesktop"      -Type DWord -Value 1
}

# Restore UAC to Windows defaults.
Function RestoreUAC {
	Write-Output "Restoring UAC defaults..."
	Set-ItemProperty -Path $UACKey -Name "ConsentPromptBehaviorAdmin" -Type DWord -Value 5
	Set-ItemProperty -Path $UACKey -Name "ConsentPromptBehaviorUser"  -Type DWord -Value 3
	Set-ItemProperty -Path $UACKey -Name "PromptOnSecureDesktop"      -Type DWord -Value 1
}

# Enable the firewall on all profiles with a default-deny inbound policy.
Function EnableFirewallStrict {
	Write-Output "Enabling strict firewall (default-deny inbound)..."
	Set-NetFirewallProfile -All -Enabled True -DefaultInboundAction Block -DefaultOutboundAction Allow -ErrorAction SilentlyContinue
}

# Restore firewall inbound/outbound actions to default (firewall stays enabled).
Function RestoreFirewall {
	Write-Output "Restoring firewall defaults..."
	Set-NetFirewallProfile -All -Enabled True -DefaultInboundAction NotConfigured -DefaultOutboundAction NotConfigured -ErrorAction SilentlyContinue
}


# Skip the "choose privacy settings" experience shown at first sign-in of a new user.
Function DisablePrivacyExperienceOnLogon {
	Write-Output "Disabling first-logon privacy experience..."
	$k = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OOBE"
	If (!(Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
	Set-ItemProperty -Path $k -Name "DisablePrivacyExperience" -Type DWord -Value 1
}

# Restore default (privacy experience shown at first sign-in).
Function EnablePrivacyExperienceOnLogon {
	Write-Output "Restoring first-logon privacy experience..."
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OOBE" -Name "DisablePrivacyExperience" -ErrorAction SilentlyContinue
}

##########
# Verification
##########

# Print the live state of every control so you can confirm the end state after a
# run (and after big Windows Updates, which can reset some settings). Read-only.
Function HardenVerify {
	Write-Output "==== Harden state ===="

	Write-Output "[USB]"
	$deny  = (Get-ItemProperty -Path $RestrictionsKey -Name "DenyUnspecified" -ErrorAction SilentlyContinue).DenyUnspecified
	$useAllow = (Get-ItemProperty -Path $RestrictionsKey -Name "AllowDeviceIDs" -ErrorAction SilentlyContinue).AllowDeviceIDs
	$count = 0
	If (Test-Path "$RestrictionsKey\AllowDeviceIDs") {
		$count = (Get-Item "$RestrictionsKey\AllowDeviceIDs").Property.Count
	}
	Write-Output ("  DenyUnspecified : {0}" -f $(If ($deny -eq 1) { "ON" } Else { "off" }))
	Write-Output ("  Allow-list      : {0} ({1} ID(s))" -f $(If ($useAllow -eq 1) { "ON" } Else { "off" }), $count)

	Write-Output "[Wireless]"
	$svc = Get-Service -Name "WlanSvc" -ErrorAction SilentlyContinue
	If ($svc) {
		Write-Output ("  WlanSvc         : {0}, {1}" -f $svc.StartType, $svc.Status)
	} Else {
		Write-Output "  WlanSvc         : not found"
	}

	Write-Output "[Bluetooth]"
	$bt = Get-Service -Name "bthserv" -ErrorAction SilentlyContinue
	If ($bt) {
		Write-Output ("  bthserv         : {0}, {1}" -f $bt.StartType, $bt.Status)
	} Else {
		Write-Output "  bthserv         : not found"
	}

	Write-Output "[Accounts]"
	ForEach ($u in @($Global:AdminUserName, $Global:StandardUserName, "Administrator")) {
		$lu = Get-LocalUser -Name $u -ErrorAction SilentlyContinue
		If ($lu) {
			$isAdmin = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*\$u" }
			Write-Output ("  {0,-14}: enabled={1} admin={2}" -f $u, $lu.Enabled, [bool]$isAdmin)
		} Else {
			Write-Output ("  {0,-14}: (does not exist)" -f $u)
		}
	}

	Write-Output "[UAC]"
	$u = Get-ItemProperty -Path $UACKey -ErrorAction SilentlyContinue
	Write-Output ("  EnableLUA={0} AdminPrompt={1} UserPrompt={2} SecureDesktop={3}" -f $u.EnableLUA, $u.ConsentPromptBehaviorAdmin, $u.ConsentPromptBehaviorUser, $u.PromptOnSecureDesktop)

	Write-Output "[Firewall]"
	ForEach ($p in Get-NetFirewallProfile -ErrorAction SilentlyContinue) {
		Write-Output ("  {0,-8}: enabled={1} inbound={2}" -f $p.Name, $p.Enabled, $p.DefaultInboundAction)
	}
	Write-Output "======================"
}