# PowerShell Toolkit

A collection of PowerShell scripts for infrastructure administration, automation, monitoring, and Microsoft ecosystem operations.

This repository is focused on practical scripts used by system administrators and infrastructure engineers.

## Categories

| Category | Description |
|---|---|
| ActiveDirectory | User, computer, group and password automation |
| Azure | Azure VM, backup and cloud infrastructure scripts |
| ExchangeOnline | Mailbox, archive and reporting scripts |
| Microsoft365 | Entra ID, Graph, SharePoint and OneDrive scripts |
| SCCM | MECM/SCCM automation and deployment scripts |
| RDS | Remote Desktop Services administration |
| Monitoring | Zabbix, Grafana, Wazuh and log-related scripts |
| Security | MFA, audit, access control and hardening scripts |
| VMware | vCenter, ESXi and PowerCLI scripts |
| HyperV | Hyper-V and SCVMM automation |
| Networking | DNS, DHCP, VPN and routing scripts |
| Utilities | General helper scripts |

## Featured Scripts

| Script | Description |
|---|---|
| [ADChangeMonitor](ActiveDirectory/ADChangeMonitor/) | Monitors important Active Directory changes and sends email alerts |
| [PasswordExpirationNotifier](ActiveDirectory/PasswordExpirationNotifier/) | Sends password expiration reminders to Active Directory users |

## Repository Structure

```text
Powershell-toolkit/
├── ActiveDirectory/
│   ├── ADChangeMonitor/
│   └── PasswordExpirationNotifier/
├── Azure/
├── ExchangeOnline/
├── Microsoft365/
├── SCCM/
├── RDS/
├── Monitoring/
├── Security/
├── VMware/
├── HyperV/
├── Networking/
├── Utilities/
├── docs/
├── templates/
└── tools/
```

## Script Layout

Each script should be placed in its own folder:

```text
Category/
└── ScriptName/
    ├── ScriptName.ps1
    ├── README.md
    └── examples/
```

## Script Header Standard

Each script should include a metadata header:

```powershell
<#
.SYNOPSIS
Short script description.

.DESCRIPTION
Detailed description of what the script does.

.AUTHOR
Volodymyr Lysychenko

.CATEGORY
ActiveDirectory

.VERSION
1.0.0

.TAGS
PowerShell,Automation,Infrastructure

.NOTES
Additional notes and requirements.
#>
```

## Security Rules

Before publishing scripts, remove or replace:

- real domain names;
- internal server names;
- SMTP servers;
- public IP addresses;
- usernames;
- real email addresses;
- credentials;
- tokens;
- tenant IDs;
- customer names;
- internal URLs;
- logs and reports.

Do not commit:

```gitignore
*.log
*.csv
*.clixml
smtp-creds.xml
*.key
*.pem
*.pfx
*.cer
*.config
.env
```

## Notes

Some scripts are designed for Windows PowerShell 5.1 because many enterprise environments still rely on it.

Where possible, scripts include:

- description;
- requirements;
- usage examples;
- scheduled task examples;
- security notes.

## License

Internal / personal PowerShell toolkit.