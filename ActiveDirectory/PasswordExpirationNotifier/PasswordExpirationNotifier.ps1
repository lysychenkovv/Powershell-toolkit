```powershell
<#
.SYNOPSIS
Sends password expiration email notifications to Active Directory users.

.DESCRIPTION
Checks enabled Active Directory users with expiring passwords and sends email reminders
before or shortly after password expiration. The script also generates a CSV report and
can email the report to an administrator.

.AUTHOR
Volodymyr Lysychenko

.CATEGORY
ActiveDirectory

.VERSION
1.0.0

.TAGS
ActiveDirectory,PasswordExpiration,Email,Notification,Security,ScheduledTask

.NOTES
Requires the ActiveDirectory PowerShell module.
Designed to run as a Windows Scheduled Task.
#>

#################################################################################################################
# Requires: Windows PowerShell Module for Active Directory
#################################################################################################################

# Task Scheduler configuration:
# Program:
# C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe
#
# Arguments:
# -ExecutionPolicy Bypass -WindowStyle Hidden -File "YOURSCRIPT.ps1"
# or
# -ExecutionPolicy Bypass -NoProfile -NonInteractive -File "YOURSCRIPT.ps1"

#################################################################################################################
# Configuration
#################################################################################################################

# Set to $false to email users.
# Set to $true to send sample emails to administrators only.
$testing = $false

# Active Directory search base.
$SearchBase = "DC=contoso,DC=com"

# SMTP server.
$smtpServer = "smtp.contoso.com"

# Number of days before password expiration to start sending notifications.
$expireindays = 7

# Number of days after password expiration to continue sending notifications.
$negativedays = -3

# Sender email address.
$from = "servicedesk@contoso.com"

# Set to $false to disable CSV logging.
$logging = $true

# Set to $true to log non-expiring accounts.
$logNonExpiring = $false

# CSV log file path.
$logFile = "C:\Logs\PasswordExpirationNotifier\password-expiry-$(Get-Date -Format dd-MM-yyyy).csv"

# Administrator email address for reports and testing mode.
$adminEmailAddr = "it-admins@contoso.com"

# Number of sample emails to send to admin when testing mode is enabled.
# Valid values: 0, 3, "all"
$sampleEmails = 3

# Service Desk contact details shown in the user email.
$serviceDeskEmail = "servicedesk@example.com"
$serviceDeskUrl = "https://servicedesk.example.com"

#################################################################################################################
# System Settings
#################################################################################################################

$textEncoding = [System.Text.Encoding]::UTF8
$date = Get-Date -Format dd-MM-yyyy
$starttime = Get-Date

Write-Host "Processing `"$SearchBase`" for password expiration notifications"
Write-Host "Testing mode: $testing"

Import-Module ActiveDirectory

Write-Host "Gathering user list"

$users = Get-ADUser -SearchBase $SearchBase `
    -Filter { (Enabled -eq $true) -and (PasswordNeverExpires -eq $false) } `
    -Properties sAMAccountName, DisplayName, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress, LastLogon, WhenCreated

Write-Host "Filtering user list"

$DefaultmaxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge

$countprocessed = $users.Count
$samplesSent = 0
$countsent = 0
$countnotsent = 0
$countfailed = 0
$nonexpiring = 0

Write-Host "$countprocessed user accounts selected for processing."

# Set max sample emails to send to admin address.
if ($sampleEmails -isnot [int]) {
    if ($sampleEmails.ToLower() -eq "all") {
        $sampleEmails = $users.Count
    }
}

if (($testing -eq $true) -and ($sampleEmails -ge 0)) {
    Write-Host "Testing only. $sampleEmails sample emails will be sent to $adminEmailAddr"
}
elseif (($testing -eq $true) -and ($sampleEmails -eq 0)) {
    Write-Host "Testing only. Emails will not be sent."
}

# Create CSV log.
if ($logging -eq $true) {
    $logDirectory = Split-Path -Path $logFile -Parent

    if (-not (Test-Path $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    }

    Out-File $logFile
    Add-Content $logFile "`"Date`",`"SAMAccountName`",`"DisplayName`",`"Created`",`"PasswordSet`",`"DaysToExpire`",`"ExpiresOn`",`"EmailAddress`",`"Notified`""
}

# Process each user.
foreach ($user in $users) {
    $dName = $user.DisplayName
    $sName = $user.sAMAccountName
    $emailaddress = $user.EmailAddress
    $whencreated = $user.WhenCreated
    $passwordSetDate = $user.PasswordLastSet

    # Reset sent flag.
    $sent = ""

    $PasswordPol = Get-ADUserResultantPasswordPolicy $user

    # Check for Fine-Grained Password Policy.
    if (($PasswordPol) -ne $null) {
        $maxPasswordAge = $PasswordPol.MaxPasswordAge
    }
    else {
        # No FGPP found. Use domain default policy.
        $maxPasswordAge = $DefaultmaxPasswordAge
    }

    # If MaxPasswordAge is 0, it acts like PasswordNeverExpires even if the bit is not set.
    if ($maxPasswordAge -eq 0) {
        Write-Host "$sName : MaxPasswordAge = $maxPasswordAge. User will not receive email."
    }

    $expiresOn = $passwordSetDate + $maxPasswordAge
    $today = Get-Date

    if (($user.PasswordExpired -eq $false) -and ($maxPasswordAge -ne 0)) {
        $daystoexpire = (New-TimeSpan -Start $today -End $expiresOn).Days
    }
    elseif (($user.PasswordExpired -eq $true) -and ($passwordSetDate -ne $null) -and ($maxPasswordAge -ne 0)) {
        # Password has already expired.
        $daystoexpire = -((New-TimeSpan -Start $expiresOn -End $today).Days)
    }
    else {
        # Password was never set or MaxPasswordAge is 0.
        $daystoexpire = "NA"
        $nonexpiring += 1
    }

    # Set message text based on days to expiration.
    switch ($daystoexpire) {
        { $_ -ge $negativedays -and $_ -le -1 } {
            $messageDays = "has already expired"
        }
        "0" {
            $messageDays = "expires today"
        }
        "1" {
            $messageDays = "expires in 1 day"
        }
        default {
            $messageDays = "expires in $daystoexpire days"
        }
    }

    # Email subject.
    $subject = "Your password $messageDays"

    # Email body.
    $body = @"
<html>
<body style="font-family: Arial, sans-serif; font-size: 14px;">
<p>Hello,</p>

<p>This is an automated reminder that the password for your account <b>$sName</b> $messageDays.</p>

<p>Please change your password as soon as possible to avoid access issues with your workstation, corporate services, or remote desktop servers.</p>

<p>If you need help, please contact the Service Desk:</p>

<ul>
  <li>Email: <a href="mailto:$serviceDeskEmail">$serviceDeskEmail</a></li>
  <li>Portal: <a href="$serviceDeskUrl">$serviceDeskUrl</a></li>
</ul>

<p><b>Security reminder:</b> do not click password reset links from unknown or suspicious emails. If you are not sure whether this message is legitimate, contact the Service Desk using verified company contacts.</p>

<br>
<p>Regards,<br>
Service Desk</p>
</body>
</html>
"@

    # If testing is enabled, send samples to admin only. Otherwise send to the user's email address.
    if (($testing -eq $true) -and ($samplesSent -le $sampleEmails)) {
        $recipient = $adminEmailAddr
    }
    else {
        $recipient = $emailaddress
    }

    # Send email if user is inside the trigger range.
    if (($daystoexpire -ge $negativedays) -and ($daystoexpire -le $expireindays) -and ($daystoexpire -ne "NA")) {
        Write-Host "$sName : Selected to receive email. Password $messageDays"

        if (($emailaddress) -ne $null) {
            if (($testing -eq $false) -or (($testing -eq $true) -and ($samplesSent -lt $sampleEmails))) {
                try {
                    Send-MailMessage `
                        -SmtpServer $smtpServer `
                        -From $from `
                        -To $recipient `
                        -Subject $subject `
                        -Body $body `
                        -BodyAsHtml `
                        -Priority High `
                        -Encoding $textEncoding `
                        -ErrorAction Stop `
                        -ErrorVariable err
                }
                catch {
                    Write-Host "Error: Could not send email to $recipient via $smtpServer"
                    $sent = "Send fail"
                    $countfailed++
                }
                finally {
                    if ($err.Count -eq 0) {
                        Write-Host "Sent email for $sName to $recipient"
                        $countsent++

                        if ($testing -eq $true) {
                            $samplesSent++
                            $sent = "toAdmin"
                        }
                        else {
                            $sent = "Yes"
                        }
                    }
                }
            }
            else {
                Write-Host "Testing mode: skipping email to $recipient"
                $sent = "No"
                $countnotsent++
            }
        }
        else {
            Write-Host "$dName ($sName) has no email address."
            $sent = "No addr"
            $countnotsent++
        }

        # Log details if logging is enabled.
        if ($logging -eq $true) {
            Add-Content $logFile "`"$date`",`"$sName`",`"$dName`",`"$whencreated`",`"$passwordSetDate`",`"$daystoexpire`",`"$expiresOn`",`"$emailaddress`",`"$sent`""
        }
    }
    else {
        # Log non-expiring passwords if enabled.
        if (($logging -eq $true) -and ($logNonExpiring -eq $true)) {
            if ($maxPasswordAge -eq 0) {
                $sent = "NeverExp"
            }
            else {
                $sent = "No"
            }

            Add-Content $logFile "`"$date`",`"$sName`",`"$dName`",`"$whencreated`",`"$passwordSetDate`",`"$daystoexpire`",`"$expiresOn`",`"$emailaddress`",`"$sent`""
        }
    }
}

$endtime = Get-Date
$totaltime = ($endtime - $starttime).TotalSeconds
$minutes = "{0:N0}" -f ($totaltime / 60)
$seconds = "{0:N0}" -f ($totaltime % 60)

Write-Host "$countprocessed users from `"$SearchBase`" processed in $minutes minutes $seconds seconds."
Write-Host "Email trigger range from $negativedays past days to $expireindays upcoming days of user's password expiry date."
Write-Host "$nonexpiring non-expiring accounts."
Write-Host "$countsent emails sent."
Write-Host "$countnotsent emails skipped."
Write-Host "$countfailed emails failed."

# Sort CSV file and send report.
if ($logging -eq $true) {
    Rename-Item $logFile "$logFile.old"
    Import-Csv "$logFile.old" | Sort-Object ExpiresOn | Export-Csv $logFile -NoTypeInformation
    Remove-Item "$logFile.old"

    Write-Host "CSV file created at $logFile."

    if ($testing -eq $true) {
        $body = "Testing mode.<br>"
    }
    else {
        $body = ""
    }

    $body += @"
CSV attached for $date<br>
$countprocessed users from "$SearchBase" processed in $minutes minutes $seconds seconds.<br>
Email trigger range from $negativedays past days to $expireindays upcoming days of user's password expiry date.<br>
$nonexpiring non-expiring accounts.<br>
$countsent emails sent.<br>
$countnotsent emails skipped.<br>
$countfailed emails failed.
"@

    try {
        Send-MailMessage `
            -SmtpServer $smtpServer `
            -From $from `
            -To $adminEmailAddr `
            -Subject "Password Expiry Logs" `
            -Body $body `
            -BodyAsHtml `
            -Attachments "$logFile" `
            -Priority High `
            -Encoding $textEncoding `
            -ErrorAction Stop `
            -ErrorVariable err
    }
    catch {
        Write-Host "Error: Failed to email CSV log to $adminEmailAddr via $smtpServer"
    }
    finally {
        if ($err.Count -eq 0) {
            Write-Host "CSV emailed to $adminEmailAddr"
        }
    }
}
```
