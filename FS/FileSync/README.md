# FileSync

`FileSync.ps1` is a PowerShell-based file synchronization tool designed for automated folder replication, backup preparation, and scheduled synchronization tasks.

Unlike traditional synchronization tools, FileSync supports XML configuration files that can contain multiple synchronization jobs executed sequentially.

## Why Use FileSync?

The primary advantage of FileSync is its XML-based configuration system.

A single configuration file can contain multiple synchronization jobs, each with its own:

* Source folder
* Target folder
* File filters
* Exclusion rules

While tools such as Robocopy support job files, each Robocopy job file typically contains only a single task. FileSync allows multiple synchronization jobs to be managed from a single configuration file.

## Features

* XML configuration files
* Multiple synchronization jobs per configuration
* Local and network path support
* Include filters
* Exclusion lists
* Detailed logging
* Verbose console output
* WhatIf support
* PowerShell-native implementation
* Suitable for Windows Task Scheduler

## Configuration File Structure

A configuration file starts with the root element:

```xml
<Configuration>
</Configuration>
```

Each synchronization job is defined inside a `SyncPair` block.

### Basic Example

```xml
<Configuration>

    <SyncPair>
        <Source>C:\Data</Source>
        <Target>D:\Backup\Data</Target>
    </SyncPair>

</Configuration>
```

## Multiple Synchronization Jobs

A single configuration file can contain multiple jobs.

```xml
<Configuration>

    <SyncPair>
        <Source>C:\Source1</Source>
        <Target>D:\Backup1</Target>
    </SyncPair>

    <SyncPair>
        <Source>C:\Source2</Source>
        <Target>D:\Backup2</Target>
    </SyncPair>

</Configuration>
```

All jobs are executed sequentially.

## Using Filters

The `Filter` element allows synchronization of only matching files.

Example:

```xml
<Filter>*.txt</Filter>
```

Only text files will be copied.

### Match Files Containing a String

```xml
<Filter>*old*</Filter>
```

Matches:

```text
oldfile.txt
fileold.txt
backup_old.docx
```

### Match Files Starting With a String

```xml
<Filter>old*</Filter>
```

Matches:

```text
oldfile.txt
old_document.docx
```

Does not match:

```text
fileold.txt
```

### Important Limitation

Only a single filter can be specified per synchronization job.

This will NOT work as expected:

```xml
<Filter>*.jpg, *.png</Filter>
```

If multiple file types are required, create separate synchronization jobs.

Example:

```xml
<SyncPair>
    <Source>C:\Images</Source>
    <Target>D:\Backup</Target>
    <Filter>*.jpg</Filter>
</SyncPair>

<SyncPair>
    <Source>C:\Images</Source>
    <Target>D:\Backup</Target>
    <Filter>*.png</Filter>
</SyncPair>
```

## Exclusions

Multiple exclusions can be configured using `ExceptionList`.

Example:

```xml
<SyncPair>

    <Source>C:\Source</Source>
    <Target>D:\Backup</Target>

    <Filter>*.txt</Filter>

    <ExceptionList>
        <Exception>*p234*.txt</Exception>
        <Exception>*temp*</Exception>
    </ExceptionList>

</SyncPair>
```

Files matching the exclusion patterns will be skipped.

## Example Configuration

```xml
<Configuration>

    <SyncPair>
        <Source>C:\synctest\source1</Source>
        <Target>C:\synctest\dest1</Target>

        <Filter>*.txt</Filter>

        <ExceptionList>
            <Exception>*p234*.txt</Exception>
        </ExceptionList>
    </SyncPair>

    <SyncPair>
        <Source>C:\synctest\source2</Source>
        <Target>C:\synctest\dest2</Target>

        <Filter>*.txt</Filter>
    </SyncPair>

</Configuration>
```

## Running the Script

### Using a Configuration File

```powershell
.\FileSync.ps1 -ConfigurationFile "C:\ADM\MySyncJob.xml"
```

### Verbose Mode

Useful for troubleshooting and validation.

```powershell
.\FileSync.ps1 `
    -ConfigurationFile "C:\ADM\MySyncJob.xml" `
    -Verbose
```

### WhatIf Mode

Preview actions without making changes.

```powershell
.\FileSync.ps1 `
    -ConfigurationFile "C:\ADM\MySyncJob.xml" `
    -WhatIf
```

## Logging

The script automatically creates a log file in its working directory.

The log includes:

* Source folder
* Target folder
* Filters
* Exclusions
* Files copied
* Files skipped
* Errors
* Summary information

The log is intended to be detailed enough for troubleshooting and auditing synchronization jobs.

## Running from Command Line

Recommended:

```powershell
PowerShell -Command "& {C:\ADM\FileSync.ps1 -ConfigurationFile 'C:\ADM\MySyncJob.xml'}"
```

This method preserves PowerShell runtime behavior and correctly initializes automatic variables such as:

```powershell
$PSScriptRoot
```

## Windows Task Scheduler

Recommended program:

```text
powershell.exe
```

Recommended arguments:

```powershell
-Command "& {C:\ADM\FileSync.ps1 -ConfigurationFile 'C:\ADM\MySyncJob.xml'}"
```

This approach ensures proper script execution and correct log file creation.

## Advantages Over Traditional Batch Files

* Better security
* Structured configuration files
* Multiple jobs per configuration
* Better logging
* Native PowerShell support
* Reduced risk of accidental execution
* Easier maintenance

## Recommended Repository Layout

```text
Utilities/
└── FileSync/
    ├── FileSync.ps1
    ├── README.md
    ├── sample-config.xml
    └── examples/
```

## License

Internal / personal PowerShell toolkit.
