## Variables for backup and purge
$sourceDir = "C:\Users\root\AppData\LocalLow\IronGate\Valheim\";
$targetDir = "C:\servers\backups\Valheim\";
$targetFilenameBase = 'valheim-';
$hours = '-24';

## Running the backup
$date = get-date;
$dateStr = $date.ToString("yyyy-MM-dd_HH-mm");
$targetFile = $targetDir+$targetFilenameBase+$dateStr+'.zip';

Add-Type -A 'System.IO.Compression.FileSystem';
[IO.Compression.ZipFile]::CreateFromDirectory($sourceDir, $targetFile);

## Purging old data
# Delete files older than the $limit.
Get-ChildItem -Path $targetDir -Recurse -Force | Where {$_.Lastwritetime -lt (date).addhours($hours)} | Remove-Item -Force
