
<#
.Description
__________________________________
-------------------------------------------------------
# Windows Magic Backup System
__________________________________
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
#>


try {
$BackupTaskState = "On" # On or Off  -- Choose to enable/disable backup
$directory = "$env:USERPROFILE\OneDrive\Configuration and Settings Backup\Environment Variables" # where to store Backup files

if ($BackupTaskState -eq "On"){

# Custom Definitions 
$Backup_Name = "System Environment Variables" # Descriptive Backup Prepend for Naming
$Day_Interval = 7 # Backup every M days
$BackupTime = 4pm # Time of Day to run backup
$N_backups = 50   # Keep N unique backups

# Custom Backup data Collection and extraction methods
$backupdata = env # Backup Item Data Collection
$Unique_Backup_Name = "$Backup_Name $Date_now.txt"
echo $backupdata >> "$directory\$Unique_Backup_Name.txt" # Saving Backup data

$Date_now = Get-Date -Format "MM-dd-yyyy hh_mm_ss_ff"
$TheTaskName = "$Backup_Name Backup by gavinkress"

$BackupMatchPattern = "^$Backup_Name .?\d{2}-\d{2}-\d{4} \d{2}_\d{2}_\d{2}.?.txt$" #specific against other files in directory

#Remove old task
if ($(Get-ScheduledTask -TaskName $TheTaskName -ErrorAction SilentlyContinue).TaskName -eq $TheTaskName){
    Unregister-ScheduledTask -TaskName $TheTaskName -Confirm:$False
}

# Collect and sort backup files matching Backup patten by Chosen property: LastWriteTime
$dirfiles = Get-ChildItem $directory | Where-Object {$_.Name -match $BackupMatchPattern} | Sort-Object -Property LastWriteTime -Descending 

# Add a new grouping property then group by It then select most recent
$dirfiles | Add-Member -MemberType NoteProperty -Name "Content" -Value Get-Content
$Keepfiles = Group-Object $dirfiles -Property "Content" | Sort-Object -Property LastWriteTime -Descending | %{$_[0]}

# Remove Redundant
for ($index = 0; $index -lt $dirfiles.count; $index++){
	if ($dirfiles[$index].Name -notin $Keepfiles )   {
		$dirfiles[$index] | Remove-Item -Force
	}
}

# Remove Excessive
if ($dirfiles.count -gt $N_backups){
	for ( $index = $N_backups-1; $index -lt $dirfiles.count; $index++){
		$dirfiles[$index] | Remove-Item -Force
	}
}


# Ensure Backup Event which calls this script still exists and is configured by overwriting/creating It
$TheTaskDescriptoin = @"
- name: WinMagicBackup
- Homepage: https://github.com/gavinkress/WinMagicBackup
- Author: Gavin Kress
- email: gavinkress@gmail.com
- Date: 9/30/2024
- version: 1.0.0
- readme = WinMagicBackup
- Programming Language(s): powershell 
- License: MIT License
- Operating System: Windows 11

This is a task which is part of an automated file Backup workflow created by gavinkress(https://github.com/gavinkress/WinMagicBackup). 
It runs At $BackupTime every $Day_Interval days to executre $PSCommandPath.
$PSCommandPath creates a file matching the naming convention of $Unique_Backup_Name in $directory.
It ensures no redundancy by only keeping the most recently created edition of a File which has others with duplicate data and limits the total number of these files to the most recent $N_baackups written.

The behavior of the workflow is extreemly easy to implement and highly customizable. Simply modify the following inputs at the top of the script, save the script anywhere On your pc and run it once. Nothing else is needed, everything will behave as expected from then on, feel free to change any parameters any Time and It will also change with no work needed by you.

BackupTaskState: On or Off <str>
directory: where to store Backup files <str>
Backup_Name: Descriptive <str> to Prepend for Naming
Day_Interval: Backup every <int> days
BackupTime: Time of Day: <Time> 'eg 4pm' to run Backup. No quotes needed.
N_backups: Keep <int> unique backups
backupdata: <Custom> method, can be as complex as necessary  (e.g. $backupdata = env # Backup Item Data Collection)
following line to extract Backup data follows the same logic (e.g. echo $backupdata >> "$directory\$Unique_Backup_Name.txt" # Saving Backup data)
"@

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-File "{0}"' -f $PSCommandPath)
$trigger = New-ScheduledTaskTrigger -Daily -At $BackupTime
$trigger.RepetitionInterval = (New-TimeSpan -Days $Day_Interval) 
$trigger.RepetitionDuration = [TimeSpan]::MaxValue    
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopOnIdleEnd -StartWhenAvailable

Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings -TaskName $TheTaskName -Description $TheTaskDescriptoin
}
else {
    # Backup Turned Off 
	if ($(Get-ScheduledTask -TaskName $TheTaskName -ErrorAction SilentlyContinue).TaskName -eq $TheTaskName) {
    Unregister-ScheduledTask -TaskName $TheTaskName -Confirm:$False
}

} # On/Off

} # Error Handeling

Catch {
	
$_.Exception | Out-File $directory\ERROR_TASK_FAILED.log -Append
ErrMsg = @"
Backup task $PSCommand failed with Exception $_.Exception.
Error log appended at $directory\ERROR_TASK_FAILED.log -Append
you must fix your input or manually disable or will Keep getting this popup.
"@
	
Write-Host $ErrMsg
Break

}
