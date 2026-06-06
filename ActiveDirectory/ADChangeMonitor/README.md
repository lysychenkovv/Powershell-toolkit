\# ADChangeMonitor



\## Description



`ADChangeMonitor.ps1` monitors important Active Directory changes by reading Windows Security events on a Domain Controller.



The script sends email notifications when the following events are detected:



| Event ID | Description |

|---|---|

| 4720 | User account created |

| 4726 | User account deleted |

| 4741 | Computer account created |

| 4743 | Computer account deleted |

| 4730 | Security group deleted |

| 4729 | Member removed from global security group |

| 4733 | Member removed from local security group |



This script is useful for basic Active Directory auditing and quick email alerting about important user, computer and group changes.



\## Requirements



\- Windows Server with Active Directory Domain Services

\- PowerShell 5.1 or newer

\- Access to the `Security` event log

\- SMTP server access

\- SMTP credentials exported to XML

\- Recommended to run on a Domain Controller



\## Repository Path



```text

ActiveDirectory/ADChangeMonitor/ADChangeMonitor.ps1

```



\## Parameters



| Parameter | Description | Default |

|---|---|---|

| `LogFile` | Path to the script log file | `C:\\bin\\ADMonitor\\ad-monitor.log` |

| `CredentialPath` | Path to exported SMTP credentials | `C:\\bin\\ADMonitor\\smtp-creds.xml` |

| `SmtpServer` | SMTP server address | Required |

| `From` | Sender email address | Required |

| `To` | Recipient email addresses | Required |

| `SubjectPrefix` | Email subject prefix | `AD Change Monitor` |

| `IntervalSeconds` | Monitoring interval in seconds | `30` |

| `SmtpPort` | SMTP port | `25` |

| `UseSsl` | Enables SSL for SMTP | Disabled by default |



\## SMTP Authentication



The script uses a PowerShell credential object stored in an XML file.



Default location:



```text

C:\\bin\\ADMonitor\\smtp-creds.xml

```



The credential file contains:



\* SMTP username

\* Encrypted SMTP password



Example structure:



```xml

<Objs>

&#x20; <Obj>

&#x20;   <Props>

&#x20;     <S N="UserName">smtp-user@example.com</S>

&#x20;     <SS N="Password">encrypted-password-data</SS>

&#x20;   </Props>

&#x20; </Obj>

</Objs>

```



The password is encrypted using Windows Data Protection API (DPAPI) and cannot be read as plain text.



\### Create Credential File



Create the directory:



```powershell

New-Item -ItemType Directory -Force -Path "C:\\bin\\ADMonitor"

```



Generate the credential file:



```powershell

Get-Credential | Export-Clixml -Path "C:\\bin\\ADMonitor\\smtp-creds.xml"

```



A credential prompt will appear.



Enter:



\* SMTP username

\* SMTP password



The generated file will be used automatically by the script.



\### Important Notes



The credential file is tied to:



\* The Windows user account that created it

\* The computer where it was created



Because of this:



\* The file cannot normally be copied to another server.

\* The file cannot normally be used by another user account.

\* If the scheduled task runs under a service account, create the credential file while logged in as that same account.

\* If the script is moved to another server, recreate the credential file.



\### Security Recommendations



Never store SMTP passwords directly in the script.



Never upload the following files to GitHub:



```text

smtp-creds.xml

\*.clixml

\*.log

```



For public repositories, use placeholder values instead of real SMTP servers, usernames, or email addresses.



\## Manual Run Example



```powershell

.\\ADChangeMonitor.ps1 `

&#x20; -SmtpServer "smtp.contoso.com" `

&#x20; -From "ad-monitor@contoso.com" `

&#x20; -To "admin1@contoso.com","admin2@contoso.com"

```



Example with custom SMTP port:



```powershell

.\\ADChangeMonitor.ps1 `

&#x20; -SmtpServer "smtp.contoso.com" `

&#x20; -From "ad-monitor@contoso.com" `

&#x20; -To "admin1@contoso.com","admin2@contoso.com" `

&#x20; -SmtpPort 587 `

&#x20; -UseSsl

```



\## Scheduled Task Example



Create a scheduled task that starts automatically when the server starts.



```powershell

$ScriptPath = "C:\\Scripts\\ADChangeMonitor\\ADChangeMonitor.ps1"



$Action = New-ScheduledTaskAction `

&#x20;   -Execute "powershell.exe" `

&#x20;   -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" -SmtpServer `"smtp.contoso.com`" -From `"ad-monitor@contoso.com`" -To `"admin1@contoso.com`",`"admin2@contoso.com`""



$Trigger = New-ScheduledTaskTrigger -AtStartup



$Principal = New-ScheduledTaskPrincipal `

&#x20;   -UserId "DOMAIN\\ServiceAccount" `

&#x20;   -LogonType Password `

&#x20;   -RunLevel Highest



Register-ScheduledTask `

&#x20;   -TaskName "AD Change Monitor" `

&#x20;   -Action $Action `

&#x20;   -Trigger $Trigger `

&#x20;   -Principal $Principal `

&#x20;   -Description "Monitors Active Directory changes and sends email notifications."

```



\## Recommended Folder on Server



```text

C:\\Scripts\\ADChangeMonitor\\

```



Example:



```text

C:\\Scripts\\ADChangeMonitor\\ADChangeMonitor.ps1

C:\\bin\\ADMonitor\\smtp-creds.xml

C:\\bin\\ADMonitor\\ad-monitor.log

```



\## Notes



\- The script runs continuously in a loop.

\- The default check interval is 30 seconds.

\- For production use, it is recommended to run it as a scheduled task.

\- The script should be tested manually before creating the scheduled task.

\- The account running the script must have permission to read the Security event log.

\- SMTP credentials should not be stored in GitHub.

\- Do not commit `smtp-creds.xml` or real email addresses to the repository.



\## Security Notes



Never upload sensitive data to GitHub, including:



\- SMTP passwords

\- Real production credentials

\- Internal server names, if the repository is public

\- Real user email addresses, if not intended for public use

\- Logs containing usernames or domain information



\## License



Internal / personal PowerShell toolkit.

