# Automated-Logs-Archiving
This repo will tech you how to automate logs archiving with powershell and Windows task scheduler

I found this tutorial helpfull for basic archiving [Automated clean up and archive of log files with PowerShell 5](https://dejanstojanovic.net/powershell/2018/january/automated-clean-up-and-archive-of-log-files-with-powershell-5/)

***I'm new to powershell scripting, and i'm not an expert, this what i came with***

PowerShell Script content:

# Basic Archiving
Basic archiving script, archive logs that olds than 7 days and put them on the same logs directory, without parameters, predefind values:

```
$logFolder = "C:\Application\LogsFolder" #Logs folder path
$fileAge = 7

#Get All files older than 7 days
$logFiles = Get-ChildItem $logFolder -Filter *.log.* | Where LastWriteTime -lt  (Get-Date).AddDays(-1 * $fileAge)

#Create ZIP file on the same directory
$destinationPath = $logFolder + (Get-Date -format "yyyyMMdd-HHmm") + ".zip"

#Define an array to put all selected files inside it
$logFilePaths = @()

#loop on all files and put them inside array
foreach($logFile in $logFiles){
    $logFilePaths += $logFile.FullName  
    }
    
#Compressing part of the script, it will take the array, and destination path.  For compression Level, you choose between these values: (Optimal, Fastest)
Compress-Archive -Path $logFilePaths -DestinationPath $destinationPath -CompressionLevel Optimal

#check if ZIP file created, if so, delete the archived log files
if (Test-Path -Path $destinationPath -PathType Leaf){
        Remove-Item -Path $logFilePaths
    }
else{
#Throw an error to notify the Task Scheduler to re-run the script again
throw "Zipped file not created, please check the configuration"
}
```

In Addtion **If you want to automate the deletion of archived filles** put the following script:

```
$archiveAge = 60
#Get All ZIPed files that are older than 60 days
$archiveFiles = Get-ChildItem $destinationPath -Filter *.zip | Where LastWriteTime -lt  (Get-Date).AddDays(-1 * $archiveAge)
    foreach($archiveFile in $archiveFiles){  
        Remove-Item –path $archiveFile.FullName  
    }
```

# Advanced Script
Lets make every variable to be parameterized:
We need the following parameters: 
- LogName ***//String - Archived Initial Name***
- LogFolder ***//String - Where log files are located***
- fileAge ***//int - Age of log files to be archived***
- DestinationPath ***//String - Where you want to put ZIP files***
- DeleteArchivedFiles ***//bool - do you want to delete the archived files?***
- archiveAge ***//int - if you choose $true in the previous parameter, what is the archive file age***

Script Content:
```
#First we need to have parameters
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

#Allowed Characters for the logName variable
$pat = '[^a-zA-Z0-9]'

#Check if LogName have Special Characters, this will make sure that no error while creating the ZIP file
if ($appName -match $pat)
{
    throw "Please send a valid string without \ / : * ?"" < > |"
}

#Get All files older than 7 days
$logFiles = Get-ChildItem $logFolder -Filter *.log.* | Where LastWriteTime -lt  (Get-Date).AddDays(-1 * $fileAge)  

#If you want to see the selected files
echo $logFiles

#Create ZIP file on the same directory
$destinationPath = $DestinationPath + $LogName + (Get-Date -format "yyyyMMdd-HHmm") + ".zip"

#Define an array to put all selected files inside it
$logFilePaths = @()

#loop on all files and put them inside array
foreach($logFile in $logFiles){
    $logFilePaths += $logFile.FullName  
    }
if there is no files, exit from the script
if ($logFilePaths -ne $null){
    Compress-Archive -Path $logFilePaths -DestinationPath $destinationPath -CompressionLevel Optimal 

    #check if ZIP file created, if so, delete the archived log files
    if (Test-Path -Path $destinationPath -PathType Leaf){
        Remove-Item -Path $logFilePaths
    }
    else{
    #Throw an error to notify the Task Scheduler to re-run the script again
    throw "Zipped file not created, please check the configuration"
    }
    
    #if $DeleteArchivedFiles is $true, and $archiveAge != $null and $archiveAge > 1, you can run the deletion process
    if ($DeleteArchivedFiles -and !$archiveAge -and $archiveAge > 1){
        echo "--------------------------"
        echo "Archive Files will be deleted"
        $archiveFiles = Get-ChildItem $destinationPath -Filter *.zip | Where LastWriteTime -lt  (Get-Date).AddDays(-1 * $archiveAge)

        foreach($archiveFile in $archiveFiles){  
            Remove-Item –path $archiveFile.FullName  
        }
    }
}
```

# Sechdule the Archiving Process
First of all we will use Bulit in Windows Task Scheduler to automate this task

Please follow these instructions:


1. Find and start new Task:

![Task Scheduler](https://user-images.githubusercontent.com/15194656/117161898-f75d0680-adca-11eb-8db2-d04508486b2f.png)

![Task Library](https://user-images.githubusercontent.com/15194656/117162218-43a84680-adcb-11eb-9e77-e9b27b7dc2b5.png)

![Create Task](https://user-images.githubusercontent.com/15194656/117162237-46a33700-adcb-11eb-8e30-b3b5e460cb2b.png)

![Empty Task](https://user-images.githubusercontent.com/15194656/117162402-676b8c80-adcb-11eb-9a43-f3362878d53f.png)


2. Create New Task and fill the needed information:

**Note:**

- You need to choose this option: "Run Whether user is logged on or not" to run this task even if no one is logged on.
- Check "Run with highest privleges" to elimentate any file locking from application, you must enable it or you can't delete the archived logs.

![Fill General Info](https://user-images.githubusercontent.com/15194656/117162440-705c5e00-adcb-11eb-815c-f1f9a5a4e7fa.png)


3. Triggers:

This section will Schedule the task to run (Daliy, Weekly, Monthly, etc..)
Here i choose to run weekly on Friday at 03:00 AM in the morning, you can choose whatever you want.

![Triggers](https://user-images.githubusercontent.com/15194656/117163912-c67dd100-adcc-11eb-8c46-40cec444fc3c.png)


4. Actions:

In this section we will configure the task to run PowerShell script

![Actions](https://user-images.githubusercontent.com/15194656/117165415-25901580-adce-11eb-8563-45b26ae7e78a.png)

Choose the program: PowerShell.exe

Fill the argument as follow:

C:\Users\intadmin\Documents\ArchiveLogs.ps1 -LogName 'ApiBankArchivedLogs_' -logFolder 'D:\ApplicationLogs\BankAPIsLogs\' -fileAge 3 -DestinationPath 'D:\ApplicationLogs\Archived_APIBank_Logs\' -DeleteArchivedFiles $false -archiveAge 0

Arguments Description:

![Arguments](https://user-images.githubusercontent.com/15194656/117166306-ea421680-adce-11eb-96d1-aeef63955e49.png)

**Notes:**

<ul>
  If you want script to not exit after task finished, Pass this argument before script path, at the first

  -NoExit
</ul>

<ul>
Any string argument should be wrapped with single quotation especially the argument that accept paths like $logFolder, it will throw an excption because the Two vertical points (:).
</ul>

<ul>
The boolean arguments accept ($true, $false), like $DeleteArchivedFiles.
</ul>

<ul>
In this script, if you send $false for $DeleteArchivedFiles, any number send in $archiveAge will be ignored and no ZIP file will be deleted.
</ul>

<ul>
In the $DestinationPath argument, if you choose another folder path, this path must be exist, the script will not create folder he not found it. it will throw NotFound exception.
</ul>


5. "Optional" settings:

if you want to have other settings like below. i did't use any settings here but i highlight what you can do

![Task Settings](https://user-images.githubusercontent.com/15194656/117168419-caabed80-add0-11eb-999c-3c60ddf3e044.png)
