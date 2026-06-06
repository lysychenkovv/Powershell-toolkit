<#
.SYNOPSIS
Monitors Active Directory user, computer and group changes.

.DESCRIPTION
Monitors Windows Security events on a domain controller and sends email notifications
when users, computers or groups are created, deleted, or removed from security groups.

.AUTHOR
Volodymyr Lysychenko

.CATEGORY
ActiveDirectory

.VERSION
1.0.0

.TAGS
ActiveDirectory,Security,Audit,Monitoring,Email,TaskScheduler

.EXAMPLE
.\ADChangeMonitor.ps1 -SmtpServer "smtp.contoso.com" -From "ad-monitor@contoso.com" -To "admin@contoso.com"

.NOTES
Recommended to run on a Domain Controller as a scheduled task.
Requires access to the Security event log.
#>

[CmdletBinding()]
param(
    [string]$LogFile = "C:\bin\ADMonitor\ad-monitor.log",

    [string]$CredentialPath = "C:\bin\ADMonitor\smtp-creds.xml",

    [Parameter(Mandatory = $true)]
    [string]$SmtpServer,

    [Parameter(Mandatory = $true)]
    [string]$From,

    [Parameter(Mandatory = $true)]
    [string[]]$To,

    [string]$SubjectPrefix = "AD Change Monitor",

    [int]$IntervalSeconds = 30,

    [int]$SmtpPort = 25,

    [switch]$UseSsl
)

function Write-Log {
    param(
        [string]$Message
    )

    $logDirectory = Split-Path -Path $LogFile -Parent

    if (-not (Test-Path $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp`t$Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

function Send-Notification {
    param(
        [string]$Subject,
        [string]$BodyHtml
    )

    try {
        $credentials = Import-Clixml -Path $CredentialPath
        $encoding = [System.Text.Encoding]::UTF8

        Send-MailMessage `
            -From $From `
            -To $To `
            -Subject $Subject `
            -BodyAsHtml `
            -Body $BodyHtml `
            -SmtpServer $SmtpServer `
            -Credential $credentials `
            -Port $SmtpPort `
            -UseSsl:$UseSsl `
            -Encoding $encoding

        Write-Log "Email sent: $Subject"
    }
    catch {
        Write-Log "Failed to send email: $($_.Exception.Message)"
    }
}

function Get-EventDataValue {
    param(
        [xml]$EventXml,
        [string]$Name
    )

    return (
        $EventXml.Event.EventData.Data |
        Where-Object { $_.Name -eq $Name } |
        Select-Object -ExpandProperty '#text' -ErrorAction SilentlyContinue
    )
}

function New-ChangeNotificationBody {
    param(
        [string]$Title,
        [hashtable]$Rows
    )

    $tableRows = foreach ($key in $Rows.Keys) {
        "<tr><th align='left'>$key</th><td>$($Rows[$key])</td></tr>"
    }

@"
<html>
<body>
<h2>$Title</h2>
<table border='1' cellpadding='6' cellspacing='0' style='border-collapse:collapse;font-family:sans-serif;'>
$tableRows
</table>
</body>
</html>
"@
}

try {
    Write-Log "==== AD Change Monitor started ===="
    $lastCheck = Get-Date

    while ($true) {
        Start-Sleep -Seconds $IntervalSeconds
        $now = Get-Date

        $events = Get-WinEvent -FilterHashtable @{
            LogName   = 'Security'
            ID        = 4720, 4741, 4726, 4730, 4743, 4729, 4733
            StartTime = $lastCheck
        } -ErrorAction SilentlyContinue

        foreach ($event in $events) {
            try {
                [xml]$xml = $event.ToXml()

                $eventId = $event.Id
                $targetName = Get-EventDataValue -EventXml $xml -Name "TargetUserName"
                $creator = Get-EventDataValue -EventXml $xml -Name "SubjectUserName"
                $groupName = Get-EventDataValue -EventXml $xml -Name "GroupName"
                $memberName = Get-EventDataValue -EventXml $xml -Name "MemberName"
                $timeCreated = $event.TimeCreated

                switch ($eventId) {
                    4720 {
                        $subject = "${SubjectPrefix}: New user created - $targetName"
                        $body = New-ChangeNotificationBody -Title "New user created" -Rows @{
                            "User name" = $targetName
                            "Created at" = $timeCreated
                            "Created by" = $creator
                        }
                    }

                    4741 {
                        $subject = "${SubjectPrefix}: New computer created - $targetName"
                        $body = New-ChangeNotificationBody -Title "New computer created" -Rows @{
                            "Computer name" = $targetName
                            "Created at" = $timeCreated
                            "Created by" = $creator
                        }
                    }

                    4726 {
                        $subject = "${SubjectPrefix}: User deleted - $targetName"
                        $body = New-ChangeNotificationBody -Title "User deleted" -Rows @{
                            "User name" = $targetName
                            "Deleted at" = $timeCreated
                            "Deleted by" = $creator
                        }
                    }

                    4730 {
                        $subject = "${SubjectPrefix}: Group deleted - $targetName"
                        $body = New-ChangeNotificationBody -Title "Group deleted" -Rows @{
                            "Group name" = $targetName
                            "Deleted at" = $timeCreated
                            "Deleted by" = $creator
                        }
                    }

                    4743 {
                        $subject = "${SubjectPrefix}: Computer deleted - $targetName"
                        $body = New-ChangeNotificationBody -Title "Computer deleted" -Rows @{
                            "Computer name" = $targetName
                            "Deleted at" = $timeCreated
                            "Deleted by" = $creator
                        }
                    }

                    4729 {
                        $subject = "${SubjectPrefix}: Member removed from global security group"
                        $body = New-ChangeNotificationBody -Title "Member removed from global security group" -Rows @{
                            "Member" = $memberName
                            "Group" = $groupName
                            "Removed at" = $timeCreated
                            "Removed by" = $creator
                        }
                    }

                    4733 {
                        $subject = "${SubjectPrefix}: Member removed from local security group"
                        $body = New-ChangeNotificationBody -Title "Member removed from local security group" -Rows @{
                            "Member" = $memberName
                            "Group" = $groupName
                            "Removed at" = $timeCreated
                            "Removed by" = $creator
                        }
                    }

                    default {
                        continue
                    }
                }

                Send-Notification -Subject $subject -BodyHtml $body
            }
            catch {
                Write-Log "Failed to process event ID $($event.Id): $($_.Exception.Message)"
            }
        }

        $lastCheck = $now
    }
}
catch {
    Write-Log "Fatal error: $($_.Exception.Message)"
}