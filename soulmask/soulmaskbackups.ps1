#set the limit for how many days you want saved.  This will tell the server to delete anyting older than this number.  So -2 will mean it will delete any files that have not been edited in 2+ days.
$limit = (Get-Date).AddDays(-2)
#add the path to your server saves
$path1 = "D:\AMPDatastore\Instances\A1-SoulMask01\soulmask\server\WS\Saved\Worlds\Dedicated\Level01_Main"


#Path 1
#Delete files that have not been eded within the $limit.
Get-ChildItem -Path $path1 -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt $limit } | Remove-Item -Force

#Delete any empty directories left behind after deleting the old files.  Probably not needed in this instance.
Get-ChildItem -Path $path1 -Recurse -Force | Where-Object { $_.PSIsContainer -and (Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse

#backup the save files
#what files in the folder do you want backed up.
$sourceDirA = 'D:\AMPDatastore\Instances\A1-SoulMask01\soulmask\server\WS\Saved\Worlds\Dedicated\';
#where do you want them to go
$targetDirA = 'C:\backups\soulmask\'
$targetFilenameBase = 'data-';

## no changes here
$date = get-date;
$dateStr = $date.ToString("yyyy-MM-dd_HH-mm");
$targetFileA = $targetDirA+$targetFilenameBase+$dateStr+'.zip';

Add-Type -A 'System.IO.Compression.FileSystem';
[IO.Compression.ZipFile]::CreateFromDirectory($sourceDirA, $targetFileA);