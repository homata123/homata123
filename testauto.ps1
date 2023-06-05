
$DESTINATION_ROOT_PATH = (get-item $PSScriptRoot ).parent.FullName
Write-Host "[INFO ] $DESTINATION_ROOT_PATH"

Add-Type -AssemblyName System.Windows.Forms

# Default special folder when Open Folder Dialog
# プログラムの修正を適応（設定ファイルを含め）するためパス
$DESTINATION_ROOT_PATH = "E:\ThangHM\test_folder\homata123"
# Service name
$TEST_SERVICE_NAME_1 = "Service1"
$TEST_SERVICE_NAME_2 = "Service2"

# Determines if a Service exists with a name as defined in $ServiceName.
# Returns a boolean $True or $False.
Function ServiceExists([string] $ServiceName) {
    [bool] $Return = $False
    # If you use just "Get-Service $ServiceName", it will return an error if 
    # the service didn't exist.  Trick Get-Service to return an array of 
    # Services, but only if the name exactly matches the $ServiceName.  
    # This way you can test if the array is emply.
    if ( Get-Service "$ServiceName*" -Include $ServiceName ) {
        $Return = $True
    }
    Return $Return
}

# Deletes a Service with a name as defined in $ServiceName.
# Returns a boolean $True or $False.  $True if the Service didn't exist or was 
# successfully deleted after execution.
Function DeleteService([string] $ServiceName) {
    [bool] $Return = $False
    $Service = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'" 
    if ( $Service ) {
        $Service.Delete()
        if ( -Not ( ServiceExists $ServiceName ) ) {
            $Return = $True
        }
    } else {
        $Return = $True
    }
    Return $Return
}

# Show an Open Folder Dialog and return the directory selected by the user.
# [Note] Parameters in calls to functions in PowerShell (all versions) are space-separated, not comma separated
function SelectFolderBrowserDialog([string]$InitialDirectory, [string]$description)
{
    Add-Type -AssemblyName System.Windows.Forms
    $openFolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
        Description = $description
    }
    $openFolderDialog.ShowNewFolderButton = $true
    $openFolderDialog.RootFolder = $InitialDirectory
    if($openFolderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){
        Write-Host "[INFO ]" $openFolderDialog.SelectedPath
        return $openFolderDialog.SelectedPath
    } else {
        return ''
    }
}

# Check run admin

# 実環境のsys_config,contstant.py（現在の設定）から各設定を取得するパス
# 現在動作中のフォルダを指定するフォルダ指定をできる
Write-Host "[INFO ] Please select current mnw-server folder"

# Stop the service if it is running
$serviceName1 = $TEST_SERVICE_NAME_1
$serviceName2 = $TEST_SERVICE_NAME_2
if ((Get-Service -Name $serviceName1).Status -eq 'Running') {
    Stop-Service -Name $serviceName1
}
if ((Get-Service -Name $serviceName2).Status -eq 'Running') {
    Stop-Service -Name $serviceName2
}


    # Get current branch name
$current_branch = git rev-parse --abbrev-ref HEAD

Write-Host "The current branch is: $current_branch"


# Prompt user to select branch they wish to merge from
Write-Host "Start merging from develop"


# Move to the develop branch
git checkout develop

# Merge the current branch into the develop branch
git merge $current_branch

# Move back to the target branch
git checkout $current_branch

# Merge the target branch back into the source branch
git merge develop

Write-Host "Finish merging from develop"


# Start the service
Start- -Name $serviceName1
Start- -Name $serviceName2


Start-Sleep 10





