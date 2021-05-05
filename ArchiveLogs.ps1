Param(
[Parameter(Mandatory=$true)]  
[string]$LogName,
[Parameter(Mandatory=$true)]  
[string]$logFolder,  
[Parameter(Mandatory=$true)]  
[int]$fileAge,
[Parameter(Mandatory=$true)]
[string]$DestinationPath,
[Parameter(Mandatory=$true)]
[bool]$DeleteArchivedFiles,
[Parameter(Mandatory=$true)]
[int]$archiveAge
)

$pat = '[^a-zA-Z0-9]'

if ($appName -match $pat)
{
    throw "Please send a valid string without \ / : * ?"" < > |"
}
$logFiles = Get-ChildItem $logFolder -Filter *.log.* | Where LastWriteTime -lt  (Get-Date).AddDays(-1 * $fileAge)  

echo $logFiles

$destinationPath = $DestinationPath + $LogName + (Get-Date -format "yyyyMMdd-HHmm") + ".zip"

$logFilePaths = @()

foreach($logFile in $logFiles){
    $logFilePaths += $logFile.FullName  
    }

if ($logFilePaths -ne $null){
    Compress-Archive -Path $logFilePaths -DestinationPath $destinationPath -CompressionLevel Optimal  

    echo "--------------------------"
    echo $destinationPath

    if (Test-Path -Path $destinationPath -PathType Leaf){
        Remove-Item -Path $logFilePaths
    }
    else{
    throw "Zipped file not created, please check the configuration"
    }

    if ($DeleteArchivedFiles -and !$archiveAge -and $archiveAge > 1){
        echo "--------------------------"
        echo "Archive Files will be deleted"
        $archiveFiles = Get-ChildItem $destinationPath -Filter *.zip | Where LastWriteTime -lt  (Get-Date).AddDays(-1 * $archiveAge)

        foreach($archiveFile in $archiveFiles){  
            Remove-Item –path $archiveFile.FullName  
        }
    }
}