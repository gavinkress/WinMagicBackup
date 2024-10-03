
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
- email: gavinkress@gmail.com
- Date: 9/30/2024
- version: 1.0.0
- readme = WinMagicBackup
- Programming Language(s): powershell 
- License: MIT License
- Operating System: Windows 11


----------------------------------------------------------------
## Docs
----------------------------------------------------------------

This is a task which is part of an automated file Backup workflow created by [gavinkress](https://github.com/gavinkress/). 
It runs At $BackupTime every $Day_Interval days to execute $PSCommandPath.
$PSCommandPath creates a file matching the naming convention of $Unique_Backup_Name in $directory.
It ensures no redundancy by only keeping the most recently created edition of a File which has others with duplicate data and limits the total number of these files to the most recent $N_baackups written.

The behavior of the workflow is extreemly easy to implement and highly customizable. Simply modify the following inputs at the top of the script, save the script anywhere On your pc and run it once. Nothing else is needed, everything will behave as expected from then on, feel free to change any parameters at any time and the behavior will automatically update.

* BackupTaskState: On or Off <str>
* directory: where to store Backup files <str>
* Backup_Name: Descriptive <str> to Prepend for Naming
* Day_Interval: Backup every <int> days
* BackupTime: Time of Day: <Time> 'eg 4pm' to run Backup. No quotes needed.
* N_backups: Keep <int> unique backups
* backupdata: <Custom> method, can be as complex as necessary  (e.g. $backupdata = env # Backup Item Data Collection)
  * following line to extract Backup data follows the same logic (e.g. echo $backupdata >> "$directory\$Unique_Backup_Name.txt" # Saving Backup data)
