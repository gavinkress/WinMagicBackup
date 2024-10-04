# WinMagicBackup
 Magic Backup System for Windows11


______________________________________________________
-------------------------------------------------------
# Windows Magic Backup System
______________________________________________________
-------------------------------------------------------

- Name: WinMagicBackup
- Homepage: https://github.com/gavinkress/WinMagicBackup
- Author: Gavin Kress
- Email: gavinkress@gmail.com
- Date: 9/30/2024
- Version: 1.0.0
- Programming Language(s): powershell 
- License: MIT License
- Operating System: Windows 11


----------------------------------------------------------------
## Docs
----------------------------------------------------------------
Download the ps1 file: [BackupScript.ps1](https://github.com/gavinkress/WinMagicBackup/blob/main/BackupScript.ps1)

This is a task which is part of an automated file Backup workflow created by [gavinkress](https://github.com/gavinkress/). 
It runs At `$BackupTime` every `$Day_Interval` days to execute `$PSCommandPath`.
`$PSCommandPath` creates a file matching the naming convention of `$Unique_Backup_Name` in `$directory`.
It ensures no redundancy by only keeping the most recently created edition of a File which has others with duplicate data and limits the total number of these files to the most recent `$N_backups` written.

The behavior of the workflow is extreemly easy to implement and highly customizable. Simply modify the following inputs at the top of the script, save the script anywhere On your pc and run it once. Nothing else is needed, everything will behave as expected from then on, feel free to change any parameters at any time and the behavior will automatically update.

* BackupTaskState: On or Off (string)
* Directories: Array of locations to store Backup files of each backup item - [array[(string)]]
* Backup_Names: Array of descriptive names to prepend on backup file - [array[(string)]]
* BackupTime: Time of Day to run Backup. - (string)
* N_backups_list: Array of numbers of unique backups to keep for each backup item - [array[integer]]
* BackupTarget: Outer function which houses the custom backup data collection and extraction methods as inner functions and calls them based on the index of the backup item - [function[function]]
  * The current functions backup your Environment Variables, create a list of your Current Apps, and creates a full backup of your WSL Ubuntu OS as a .tar file

### Notes:  
* To set this in motion you must run the ps1 script by right clicking it and selecting "Run with PowerShell"
* Depending on your UAC settings, you may need to give it permission to run each time.
* You also may need sign the ps1 script to run it as a scheduled task.
  * For best practice I reccomend setting your Execution policy to AllSigned or Remote Signed rather than bypassing it.
  * `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine`
  * To add your own signature see [Microsofts Instructions](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_signing?view=powershell-7.4)

