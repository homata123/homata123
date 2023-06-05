# Default special folder when Open Folder Dialog
# プログラムの修正を適応（設定ファイルを含め）するためパス


# Run as Admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}

Add-Type -AssemblyName System.Windows.Forms

# Default special folder when Open Folder Dialog
$DEFAULT_ROOT_FOLDER = "MyComputer"
# プログラムの修正を適応（設定ファイルを含め）するためパス
$DESTINATION_ROOT_PATH = "E:\THANGHM\test_folder\homata123"

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
        Write-Host "[INFO]" $openFolderDialog.SelectedPath
        return $openFolderDialog.SelectedPath
    } else {
        return ''
    }
}

# Check run admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
{    
    Write-Host "[INFO] Can not run script without administrator"
    # $arguments = "& '" +$myinvocation.mycommand.definition + "'"
    # Start-Process powershell -Verb runAs -ArgumentList $arguments
    # Break    
}
else{
    # 実環境のsys_config,contstant.py（現在の設定）から各設定を取得するパス
    # 現在動作中のフォルダを指定するフォルダ指定をできる
    Write-Host "[INFO] Please select current mnw-server folder"
    $mnw_server_path = SelectFolderBrowserDialog $DEFAULT_ROOT_FOLDER "Select current mnw-server folder"
    # Select DESTINATION_ROOT_PATH by open diaglog
    # Write-Host "[INFO] Please select deployment mnw-server folder"
    # $DESTINATION_ROOT_PATH = SelectFolderBrowserDialog $DEFAULT_ROOT_FOLDER "プログラムを適応するパスを選択してください。"
    $DESTINATION_ROOT_PATH = (get-item $PSScriptRoot ).parent.parent.FullName
    Write-Host "[INFO]" $DESTINATION_ROOT_PATH
    if($mnw_server_path -eq '' -Or $DESTINATION_ROOT_PATH -eq ''){
        Write-Host "[INFO] Cancelled"
        [System.Windows.Forms.MessageBox]::Show("Upgrade cancelled。", "Information", 'OK', 'Info')
    } 
    else {
        if($mnw_server_path -eq $DESTINATION_ROOT_PATH)
        {
            Write-Host "[ERROR] Can not versionup with itself"
            [System.Windows.Forms.MessageBox]::Show("Cannot upgrade itself", "Information", 'OK', 'Error')
        } 
        else {
            # バックアップ（mnw-serverの圧縮）ファイルの確認
            # $backup_folder = "$mnw_server_path\Util\gen_config\backup\"
            # try {
            #     # Check exist backup folder
            #     if (-not(Test-Path $backup_folder -PathType Container)) {
            #         Write-Host "[INFO] Have no zip file in $backup_folder"
            #         $backup_file_first = ''
            #     } else {
            #         $backup_file_list = Get-ChildItem $backup_folder -File | Where-Object { $_.Extension -eq ".zip" }
            #         $backup_file_first = $backup_file_list[0]
            #     }
            # }
            # catch {
            #     $backup_file_first = ''
            # }
            # if ($backup_file_first -eq '') {
            #     # 確認ダイアログを表示
            #     $msgBoxInput =  [System.Windows.Forms.MessageBox]::Show("バージョンアップ対象: $mnw_server_path`のバージョンアップを実行ますが、よろしいでしょうか ?",'Confirmation','YesNo','Info')
            # }
            # else {
            #     Write-Host "[INFO] $backup_file_first exist in backup folder"
            #     # 確認ダイアログを表示
            #     $message_content = "バージョンアップ対象: $mnw_server_path`のバージョンアップを実行ますが、よろしいでしょうか ?`n＊＊＊前回のバックアップファイルがあります。バージョンアップ処理を続行しますか？＊＊＊`n$mnw_server_path\Util\gen_config\backup\$backup_file_first"
            #     $msgBoxInput =  [System.Windows.Forms.MessageBox]::Show($message_content,'Confirmation','YesNo','Warning')
            # }
            $certain = 'Yes'
            switch($certain) {
                'Yes' {
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
                    
                    [System.Windows.Forms.MessageBox]::Show("Version upgrade has been completed. Please start the service
                    manually", "Information", 'OK', 'Info')
                    Write-Host "[INFO] VersionUp log: $DESTINATION_ROOT_PATH\Util\gen_config\result\upgrade_result.csv"

                }
                'No' {
                    # Cancel
                    [System.Windows.Forms.MessageBox]::Show($this, "Upgrade cancelled", "Information", 'OK', 'Info')
                }
            }
        }
    



# 実環境のsys_config,contstant.py（現在の設定）から各設定を取得するパス
# 現在動作中のフォルダを指定するフォルダ指定をできる
# Write-Host "Exist services: $TEST_SERVICE_NAME_1 , $TEST_SERVICE_NAME_2"

# # Stop the service if it is running
# $CHECK_SERVICE_1=ServiceExists($TEST_SERVICE_NAME_1)
# $CHECK_SERVICE_2=ServiceExists($TEST_SERVICE_NAME_2)



# if($CHECK_SERVICE_1){
#     if ((Get-Service -Name $TEST_SERVICE_NAME_1).Status -eq 'Running') {
#     Stop-Service -Name $TEST_SERVICE_NAME_1 -Force 
#     }
# }
# if($CHECK_SERVICE_2){
#     if ((Get-Service -Name $TEST_SERVICE_NAME_2).Status -eq 'Running') {
#         Stop-Service -Name $TEST_SERVICE_NAME_2 -Force 
#     }
# }

# # Get current branch name
# $current_branch = git rev-parse --abbrev-ref HEAD

# Write-Host "The current branch is: $current_branch"


# # Prompt user to select branch they wish to merge from
# Write-Host "Start merging from develop"


# # Move to the develop branch
# git checkout develop

# # Merge the current branch into the develop branch
# git merge $current_branch

# # Move back to the target branch
# git checkout $current_branch

# # Merge the target branch back into the source branch
# git merge develop

# Write-Host "Finish merging from develop"


# Start the service
# try{
#     if($CHECK_SERVICE_1){Start-Service -Name $TEST_SERVICE_NAME_1}
#     if($CHECK_SERVICE_2){Start-Service -Name $TEST_SERVICE_NAME_2}
# }
# catch{
#     Write-Host "Failed to start service"
# }


# Start-Sleep 10





