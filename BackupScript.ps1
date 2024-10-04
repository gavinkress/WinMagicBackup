param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}


try {
	$BackupTaskState = "On" # On or Off  -- Choose to enable/disable backup
	$directories = @( # where to store Backup files for each backup item
		"$env:USERPROFILE\OneDrive\Configuration and Settings Backup\Environment Variables", 
		"$env:USERPROFILE\OneDrive\Configuration and Settings Backup\AppList"
		"$env:USERPROFILE\OneDrive\Configuration and Settings Backup\WSL\Ubuntu" 
	) 
	$Backup_Names = @( # Descriptive Backup Prepend for Naming
		"System Environment Variables", 
		"Current Apps",
		"WSL_Ubuntu"
	)
	$N_backups_list = @( # Keep N unique backups
		50,
		50, 
		3
	)

	# Custom Backup data Collection and extraction methods
	function Backup-Target {
		param (
			$out_directory,
			$out_filename,
			$k
		)

		function Backup-EnvironmentVariables {
			param (
				$out_directory,
				$out_filename
			)
			$backupdata = env # Backup Item Data Collection
			echo $backupdata >> "$out_directory\$out_filename.txt" # Saving Backup data
		}
		function Backup-AppList {
			param (
				$out_directory,
				$out_filename
			)
			$backupdata = Get-WMIObject Win32_InstalledWin32Program | select Name, Version  # Backup Item Data Collection
			echo $backupdata >> "$out_directory\$out_filename.txt" # Saving Backup data
		}
		function Backup-WSLUbuntu {
			param (
				$out_directory,
				$out_filename
			)
			wsl --export Ubuntu "$out_directory\$out_filename.tar" 
		}
		
		if ($k -eq 0) {
			Backup-EnvironmentVariables -out_directory $out_directory -out_filename $out_filename
		}
		if ($k -eq 1) {
			Backup-AppList -out_directory $out_directory -out_filename $out_filename
		}
		if ($k -eq 2) {
			Backup-WSLUbuntu -out_directory $out_directory -out_filename $out_filename
		}

	}

	for ($i = 0; $i -$Backup_Names.Count; $i++){
		try {
			if ($BackupTaskState -eq "On"){

				# Custom Definitions 

				$BackupTime = "16:00" # Time of Day to run backup
				$Backup_Name = $Backup_Names[$i] # Descriptive Backup Prepend for Naming
				$N_backups = $N_backups_list[$i]   # Keep N unique backups
				$directory = $directories[$i] # where to store Backup files
				$Unique_Backup_Name = "$Backup_Name $Date_now"
				$Date_now = Get-Date -Format "MM-dd-yyyy hh_mm_ss_ff"
				$TheTaskName = "WinMagicBackup by Gavinkress at $Date_now"
				$BackupMatchPattern = "^$Backup_Name .?\d{2}-\d{2}-\d{4} \d{2}_\d{2}_\d{2}_\d{2}\.?.txt$" 
				$BackupTaskMatchPattern = "^WinMagicBackup by Gavinkress at .?\d{2}-\d{2}-\d{4} \d{2}_\d{2}_\d{2}_\d{2}\.?$"
				Backup-Target -out_directory $directory -out_filename $Unique_Backup_Name -k $i # Custom Backup data Collection and extraction methods


				# Collect and sort backup files matching the Backup pattern by LastWriteTime
				$dirfiles = Get-ChildItem $directory | Where-Object { $_.Name -match $BackupMatchPattern } | Sort-Object -Property LastWriteTime -Descending

				# Add a new property for the file content and group by it
				$dirfiles | ForEach-Object {
					# Add content as a property
					$_ | Add-Member -MemberType NoteProperty -Name "Content" -Value (Get-Content $_.FullName -Raw)
					$_ | Out-Null
				}

				# Group by the Content property and select the most recent based on LastWriteTime
				$Keepfiles = $dirfiles | Group-Object -Property Content | ForEach-Object {
					$_.Group | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
				}
				
				$Keepfiles = $Keepfiles | Select-Object -First $N_backups
				$RemoveFiles = $dirfiles | Where-Object { $_ -notin $Keepfiles }

				# Remove Redundant and Excessive
				for ($index = 0; $index -lt $RemoveFiles.count; $index++){
					$RemoveFiles[$index] | Remove-Item -Force
				}

				# Ensure Backup Event which calls this script still exists and is configured by overwriting/creating It
				$arg = '-File "{0}"' -f $PSCommandPath
				$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ($arg )
				$trigger = New-ScheduledTaskTrigger -Daily -At $BackupTime 
				$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive -RunLevel Highest
				$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopOnIdleEnd -StartWhenAvailable

				$TheTaskDescription = @"
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
				- readme: WinMagicBackup
				- Programming Language(s): powershell 
				- License: MIT License
				- Operating System: Windows 11


				----------------------------------------------------------------
				## Docs
				----------------------------------------------------------------
				Download the ps1 file: [BackupScript.ps1](https://github.com/gavinkress/WinMagicBackup/BackupScript.ps1)

				This is a task which is part of an automated file Backup workflow created by [gavinkress](https://github.com/gavinkress/). 
				It runs At $BackupTime every $Day_Interval days to execute $PSCommandPath.
				$PSCommandPath creates a file matching the naming convention of $Unique_Backup_Name in $directory.
				It ensures no redundancy by only keeping the most recently created edition of a File which has others with duplicate data and limits the total number of these files to the most recent $N_backups written.

				The behavior of the workflow is extreemly easy to implement and highly customizable. Simply modify the following inputs at the top of the script, save the script anywhere On your pc and run it once. Nothing else is needed, everything will behave as expected from then on, feel free to change any parameters at any time and the behavior will automatically update.

				* BackupTaskState: On or Off <str>
				* directories: Array of locations to store Backup files of each backup item - [<arr>[<str>]]
				* Backup_Names: Array of descriptive names to prepend on backup file - [<arr>[<str>]]
				* BackupTime: Time of Day to run Backup. - <str>
				* N_backups_list: Array of numbers of unique backups to keep for each backup item - [<arr>[<int>]]
				* BackupTarget: Outer function which houses the custom backup data collection and extraction methods as inner functions and calls them based on the index of the backup item - [<func>[<func>]]
				  * The current functions backup Environment Variables, List of Current Apps, and a WSL Ubuntu .tar file

				### Notes:  
				* To set this in motion you must run the ps1 script by right clicking it and selecting "Run with PowerShell"
				* Depending on your UAC settings, you may need to give it permission to run each time.
				* You also may need sign the ps1 script to run it as a scheduled task.
				  * For best practice I reccomend setting your Execution policy to AllSigned or Remote Signed rather than bypassing it.
				  * `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine`
				  * To add your own signature see [Microsofts Instructions](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_signing?view=powershell-7.4)

"@
				
				
				#Remove old tasks
				$allTasks = Get-ScheduledTask
				$matchedTasks = $allTasks | Where-Object { $_.TaskName -match $BackupTaskMatchPattern }
				# If any tasks match, loop through them
				if ($matchedTasks) {
					foreach ($task in $matchedTasks) {
						Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$False
					}
				}
				
				#Register new task
				Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings -TaskName $TheTaskName -Description $TheTaskDescription
				echo "$($Backup_Names[$i]) Backup Successful"
			}
			if ($BackupTaskState -ne "On") {
				# Backup Turned Off 
				if ($(Get-ScheduledTask -TaskName $TheTaskName -ErrorAction SilentlyContinue).TaskName -eq $TheTaskName) {
				Unregister-ScheduledTask -TaskName $TheTaskName -Confirm:$False}
			}
		} # Error Handeling
		catch {
			echo $_.Exception >> "$directory\ERROR_TASK_FAILED $Date_now.log"
			$ErrMsg = "Backup task $PSCommand failed with Exception $_.Exception. Error log appended at $directory\ERROR_TASK_FAILED.log You must fix your input or manually disable or will Keep getting this popup."
			Write-Host $ErrMsg
			continue
		}
	}
} # Error Handeling
catch {
	$root_cwd = (Get-Item .).FullName
	$errpath = "$root_cwd/WinMagicBackup_Error_Logs/"
	If(!(test-path -PathType container $errpath))
	{
		New-Item -ItemType Directory -Path $errpath
	}
	echo $_.Exception >> "$errpath/ERROR_TASK_FAILED $Date_now.log"
	$ErrMsg = "Backup task $PSCommand failed with Exception $_.Exception. Error log appended at $errpath\ERROR_TASK_FAILED.log You must fix your input or manually disable or will Keep getting this popup."
	Write-Host $ErrMsg
	Break
}
