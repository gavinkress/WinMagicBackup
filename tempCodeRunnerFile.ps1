$_.Exception | Out-File $directory\ERROR_TASK_FAILED.log -Append
$ErrMsg = @"
Backup task $PSCommand failed with Exception $_.Exception.
Error log appended at $directory\ERROR_TASK_FAILED.log -Append
you must fix your input or manually disable or will Keep getting this popup.
"@
	
Write-Host $ErrMsg
Break