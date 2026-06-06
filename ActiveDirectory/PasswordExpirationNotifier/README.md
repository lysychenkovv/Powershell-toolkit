# PasswordExpirationNotifier

`PasswordExpirationNotifier.ps1` sends email reminders to Active Directory users whose passwords are close to expiration or have recently expired.

The script checks enabled AD users, calculates password expiration based on the effective password policy, sends HTML email notifications, and generates a CSV report for administrators.

## Features

- Checks enabled Active Directory users
- Skips accounts with `PasswordNeverExpires`
- Supports default domain password policy
- Supports Fine-Grained Password Policies
- Sends HTML password expiration reminders
- Supports testing mode
- Sends sample emails to administrators only during testing
- Generates CSV report
- Sends CSV report to administrator
- Designed for Windows Task Scheduler

## Requirements

- Windows PowerShell 5.1
- ActiveDirectory PowerShell module
- Domain-joined server or admin workstation
- Permissions to query Active Directory users
- SMTP relay access
- User accounts should have the `EmailAddress` attribute populated

## Repository Path

```text
ActiveDirectory/PasswordExpirationNotifier/PasswordExpirationNotifier.ps1
```

## Configuration

Edit the configuration section inside the script before running it:

```powershell
$testing = $false
$SearchBase = "DC=contoso,DC=com"
$smtpServer = "smtp.contoso.com"
$expireindays = 7
$negativedays = -3
$from = "servicedesk@contoso.com"
$logging = $true
$logNonExpiring = $false
$logFile = "C:\Logs\PasswordExpirationNotifier\password-expiry-$(Get-Date -Format dd-MM-yyyy).csv"
$adminEmailAddr = "it-admins@contoso.com"
$sampleEmails = 3
$serviceDeskEmail = "servicedesk@example.com"
$serviceDeskUrl = "https://servicedesk.example.com"
```

## Configuration Values

| Variable | Description |
|---|---|
| `$testing` | If `$true`, sends sample emails to administrator only |
| `$SearchBase` | Active Directory search base |
| `$smtpServer` | SMTP relay server |
| `$expireindays` | Number of upcoming days before expiration to notify users |
| `$negativedays` | Number of past days after expiration to continue notifications |
| `$from` | Sender email address |
| `$logging` | Enables or disables CSV logging |
| `$logNonExpiring` | Logs accounts with non-expiring passwords |
| `$logFile` | CSV report path |
| `$adminEmailAddr` | Administrator email for reports and testing |
| `$sampleEmails` | Number of test sample emails sent to admin |
| `$serviceDeskEmail` | Service Desk email shown in user email |
| `$serviceDeskUrl` | Service Desk portal URL shown in user email |

## Testing Mode

Testing mode allows you to validate the script without sending emails to real users.

To enable testing:

```powershell
$testing = $true
$sampleEmails = 3
$adminEmailAddr = "it-admins@contoso.com"
```

In this mode:

- user emails are not used as recipients;
- sample notifications are sent to `$adminEmailAddr`;
- `$sampleEmails` controls how many test messages are sent;
- the CSV report is still generated;
- the administrator receives the final CSV report.

Examples:

```powershell
$sampleEmails = 0
```

No user notification samples are sent.

```powershell
$sampleEmails = 3
```

Three sample notifications are sent to the administrator.

```powershell
$sampleEmails = "all"
```

Sample notifications are sent to the administrator for all matching users.

## Manual Run

Run PowerShell as administrator and execute:

```powershell
cd C:\Scripts\PasswordExpirationNotifier

.\PasswordExpirationNotifier.ps1
```

## Scheduled Task

Recommended program:

```text
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
```

Recommended arguments:

```powershell
-ExecutionPolicy Bypass -NoProfile -NonInteractive -File "C:\Scripts\PasswordExpirationNotifier\PasswordExpirationNotifier.ps1"
```

Alternative hidden-window arguments:

```powershell
-ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Scripts\PasswordExpirationNotifier\PasswordExpirationNotifier.ps1"
```

## Scheduled Task Creation Example

```powershell
$ScriptPath = "C:\Scripts\PasswordExpirationNotifier\PasswordExpirationNotifier.ps1"

$Action = New-ScheduledTaskAction `
    -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -NoProfile -NonInteractive -File `"$ScriptPath`""

$Trigger = New-ScheduledTaskTrigger -Daily -At "09:00"

$Principal = New-ScheduledTaskPrincipal `
    -UserId "DOMAIN\ServiceAccount" `
    -LogonType Password `
    -RunLevel Highest

Register-ScheduledTask `
    -TaskName "Password Expiration Notifier" `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Description "Sends password expiration reminders to Active Directory users."
```

## Recommended Server Folder

```text
C:\Scripts\PasswordExpirationNotifier\
```

Example:

```text
C:\Scripts\PasswordExpirationNotifier\PasswordExpirationNotifier.ps1
C:\Logs\PasswordExpirationNotifier\password-expiry-01-01-2026.csv
```

## CSV Report

The script creates a CSV report with the following fields:

| Field | Description |
|---|---|
| `Date` | Script run date |
| `SAMAccountName` | User logon name |
| `DisplayName` | User display name |
| `Created` | AD account creation date |
| `PasswordSet` | Last password set date |
| `DaysToExpire` | Days before or after expiration |
| `ExpiresOn` | Calculated expiration date |
| `EmailAddress` | User email address |
| `Notified` | Notification status |

Common `Notified` values:

| Value | Meaning |
|---|---|
| `Yes` | Email was sent to user |
| `toAdmin` | Testing mode email was sent to admin |
| `No` | Email was skipped |
| `No addr` | User has no email address |
| `Send fail` | Email sending failed |
| `NeverExp` | Account has non-expiring password |

## Notes About Send-MailMessage

This script uses `Send-MailMessage`.

`Send-MailMessage` is deprecated by Microsoft, but it is still widely used in Windows PowerShell 5.1 environments and internal enterprise automation.

For PowerShell 7+ or modern cloud mail scenarios, consider replacing the mail sending part with a supported SMTP library, Microsoft Graph, or another approved mail API.

## Security Notes

Before publishing or sharing this script, replace all production values with examples.

Do not commit:

```gitignore
*.csv
*.log
*.clixml
smtp-creds.xml
```

Avoid publishing:

- internal domain names;
- real SMTP server names;
- real service desk emails;
- real user emails;
- internal URLs;
- production logs.

## License

Internal / personal PowerShell toolkit.