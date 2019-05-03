<#
    概要    ：INIファイルの設定より環境変数の追加／削除を実行する。
              呼び出し引数は「regist、unregist」の指定が可能。
              regist　：環境変数追加
              unregist：環境変数削除
              INIファイルのセクションは「SYSTEM、USER」の指定が可能。
              SYSTEM：システム環境変数
              USER　：ユーザ環境変数

    更新日時：2018/11/16 V1.0　新規作成
    更新日時：2018/11/25 V1.1　相対パス解析機能追加
    更新日時：2018/11/29 V1.2　CMD実行機能追加
    更新日時：2019/05/03 V1.3　CMDでパス取得失敗した場合は引数をそのまま戻す。
#>

############################################################################
#                                                                          #
#   呼び出し引数 -operation <regist|unregist>                              #
#                                                                          #
############################################################################
param(
    [string]$operation
)

############################################################################
#                                                                          #
#   概要    ：フルパスを取得する。                                         #
#                                                                          #
############################################################################
function fun_GetFullPath([string]$strPath){
    [string]$strPathTemp = $strPath
    if([System.IO.Directory]::Exists($strPath)){
        $strPathTemp = [System.IO.Directory]::GetDirectories($strPath)[0]
    }
    if ($strPathTemp -match "^[\s]*\.[\s]*$"){
        $strPathTemp = $gCurrentPath
    }
    if ($strPathTemp -match "^[\s]*\.\\(.*)$"){
        if($Matches.Count -eq 2){
            $strPathTemp = [System.IO.Path]::Combine($gCurrentPath,$Matches[1])
        }
    }
    #if(([System.IO.File]::Exists($strPathTemp) -eq $false) -and ([System.IO.Directory]::Exists($strPathTemp) -eq $false)){
    #    $strPathTemp = $strPath
    #}
    if((fun_IsNullOrWhiteSpace $strPathTemp) -eq $True){
        $strPathTemp = $strPath
    }
    return $strPathTemp.Trim()
}

############################################################################
#                                                                          #
#   概要    ：文字列が空白、スペースのみであるかをチェックする。           #
#    　　　　 True：空行、False：空行ではない                              #
#                                                                          #
############################################################################
function fun_IsNullOrWhiteSpace([string]$strString){
    #空行であるかをチェック
    if($strString -match "^$"){return $True}
    #スペースのみであるかをチェック
    if($strString -match "^\s*$"){return $True}
    return $False
}

############################################################################
#                                                                          #
#   概要    ：ショットカット設定情報を取得する           　　　　　　　　　#
#             INIでは「説明;パス;パラメータ」の形式で設定する。            #
#                                                                          #
############################################################################
function fun_GetShortcutInfo([string]$strString){
    [string]$strTempPath
    [string]$strTempParam
    [string]$strEditor
    [string[]]$aString = $strString -split ";"

    #説明;パス;パラメータ
    if ($aString.Length -ge 3){
        $strTempPath = $aString[1].Replace("""","")
        $strTempPath = fun_GetFullPath $strTempPath
        $strTempParam = $aString[2].Replace("""","")
        $strTempParam = fun_GetFullPath $strTempParam
        $strEditor = -join($aString[0],";",$strTempPath,";",$strTempParam)
    }

    if ($aString.Length -eq 2){
        $strTempPath = $aString[0].Replace("""","")
        $strTempPath = fun_GetFullPath $strTempPath
        #;パス;パラメータ
        if([System.IO.File]::Exists($strTempPath)){
            $strTempParam = $aString[1].Replace("""","")
            $strTempParam = fun_GetFullPath $strTempParam
            $strEditor = -join(";",$strTempPath,";",$strTempParam)
        }
        #説明;パス;
        else{
            $strTempPath = $aString[1].Replace("""","")
            $strTempPath = fun_GetFullPath $strTempPath
            $strEditor = -join($aString[0],";",$strTempPath,";")
        }
    }
    #;パス;
    if ($aString.Length -eq 1){
        $strTempPath = $aString[0].Replace("""","")
        $strTempPath = fun_GetFullPath $strTempPath
        $strEditor = -join(";",$strTempPath,";") 
    }

    return $strEditor
}

############################################################################
#                                                                          #
#   概要    ：環境変数設定ログを出力する。                                 #
#                                                                          #
############################################################################
function fun_PrintLog([string]$strMessage){
    #ローカル日時取得
    [string]$strNow = get-date -Format "yyy/MM/dd HH:mm:ss"
    #ログファイルへ出力
    $strMessage = -join("[",$strNow,"]",$strMessage)
    Write-Output $strMessage | Out-File $gSrLogFile -Append -Encoding UTF8
}

############################################################################
#                                                                          #
#   概要    ：実行ログを編集する。                                         #
#                                                                          #
############################################################################
function fun_FormatLog([string]$strTarget,[string]$strOperation,[string]$strStatus,[string]$strEnvName,[string]$strEnvValue){

    #出力内容フォマット
    [string]$strMessage = -join("[",$strTarget,"][",$strOperation,"][",$strStatus,"]{key:""",$strEnvName,""" value:""",$strEnvValue,"""}")
    #戻す
    return $strMessage
}

############################################################################
#                                                                          #
#   概要    ：環境変数を追加する。                                         #
#                                                                          #
############################################################################
function fun_AddEnv([System.EnvironmentVariableTarget]$enumTargt,[string]$strKey,[string]$strValue){

    if ($enumTargt -eq $null){
        return
    }

    #設定済みの環境変数を取得する
    [string]$strValueEditor = [Environment]::GetEnvironmentVariable($strKey,$enumTargt)

    #変更前の環境変数をログファイルへ出力
    fun_PrintLog (fun_FormatLog $enumTargt.ToString() "ADD" "BEFORE" $strKey $strValueEditor)

    #フルパス取得
    $strValue = fun_GetFullPath $strValue

    #環境変数にターゲット値がすでに設定されているかを確認する
    if((fun_IsNullOrWhiteSpace $strValueEditor) -eq $False){
        #まだ設定されていない場合は、ターゲット値を設定する
        if((";" + $strValueEditor.ToLower() + ";").Contains(";"+ $strValue.ToLower()+";") -eq $False){
            #設定していない場合は、区切文字の「;」を付ける
            if($strValueEditor -match ";\s*$" -eq $False){
                $strValueEditor = $strValueEditor + ";"
            }
            #設定済み環境変数＋ターゲット値設定
            $strValueEditor = $strValueEditor + $strValue
        }
        else{
            #ターゲット値をクリアする
            $strValueEditor = [string]::Empty
        }
    }
    else{
        #何にも設定していない場合は、ターゲット値をそのまま設定
        $strValueEditor = $strValue
    }
    #環境変数設定
    if((fun_IsNullOrWhiteSpace $strValueEditor) -eq $False){
        [Environment]::SetEnvironmentVariable($strKey,$strValueEditor,$enumTargt)
    }

    #変更後の環境変数をログファイルへ出力
    $strValueEditor = [Environment]::GetEnvironmentVariable($strKey,$enumTargt)
    fun_PrintLog (fun_FormatLog $enumTargt.ToString() "ADD" "AFTER" $strKey $strValueEditor)
}

############################################################################
#                                                                          #
#   概要    ：環境変数を削除する。                                         #
#                                                                          #
############################################################################
function fun_DelEnv([System.EnvironmentVariableTarget]$enumTargt,[string]$strKey,[string]$strValue){

    if ($enumTargt -eq $null){
        return
    }

    #設定済みの環境変数を取得する。
    [string]$strValueEditor = [Environment]::GetEnvironmentVariable($strKey,$enumTargt)

    #変更前の環境変数をログファイルへ出力
    fun_PrintLog (fun_FormatLog $enumTargt.ToString() "DEL" "BEFORE" $strKey $strValueEditor)

    #フルパス取得
    $strValue = fun_GetFullPath $strValue

    #設定済みの環境変数を「;」で分割し、
    #削除ターゲットの値と比較して、該当する場合は対象外にする
    [string[]]$aryValues = $strValueEditor.Split(";")
    $strValueEditor = ""
    for($cnt = 0;$cnt -lt $aryValues.Length;$cnt++){
        #空白の設定値は対象外にする
        if((fun_IsNullOrWhiteSpace $aryValues[$cnt]) -eq $False){
            #ターゲット値の場合は対象外にする
            if($aryValues[$cnt].Trim() -ne $strValue){
                #区切文字の「;」追加
                if((fun_IsNullOrWhiteSpace $strValueEditor) -eq $False){
                    $strValueEditor = $strValueEditor + ";"
                }
                #設定対象の設定値を取得
                $strValueEditor = $strValueEditor + $aryValues[$cnt].Trim()
            }
        }
    }
    #環境変数設定
    [Environment]::SetEnvironmentVariable($strKey,$strValueEditor,$enumTargt)

    #変更後の環境変数をログファイルへ出力
    $strValueEditor = [Environment]::GetEnvironmentVariable($strKey,$enumTargt)    
    fun_PrintLog (fun_FormatLog $enumTargt.ToString() "DEL" "AFTER" $strKey $strValueEditor)
}

############################################################################
#                                                                          #
#   概要    ：ショットカットを作成する。                                   #
#                                                                          #
############################################################################
function fun_AddShortcut([string]$strSection,[string]$strKey,[string]$strValue){
    #ショットカットディレクトリ
    $strShortcutPath = [System.IO.Path]::Combine($gCurrentPath,"shortcut")
    #ショットカットファイル
    $shortcutFile = [System.IO.Path]::Combine($strShortcutPath,$strKey+".lnk")

    #ショットカットセクションのみ対象
    if($strSection -ne "SHORTCUT"){
        return
    }

    #ログ出力
    if([System.IO.File]::Exists($shortcutFile) -eq $true){ 
        fun_PrintLog (fun_FormatLog $strSection "ADD" "BEFORE" $strKey $shortcutFile)
    }
    else{
        fun_PrintLog (fun_FormatLog $strSection "ADD" "BEFORE" $strKey "")
    }

    #ディレクトリが存在しない場合は、新規作成
    if([System.IO.Directory]::Exists($strShortcutPath) -eq $false){
        New-Item -Path $gCurrentPath -Name "shortcut" -ItemType directory
    }
    #ショットカット作成
    $strValue = (fun_GetShortcutInfo $strValue)
    [string[]]$aShortcutInfo = $strValue -split ";"
    $shell = New-Object -ComObject Wscript.shell
    $shortcut = $shell.CreateShortcut( $shortcutFile)
    $shortcut.Description = $aShortcutInfo[0]
    $shortcut.TargetPath = $aShortcutInfo[1]
    $shortcut.Arguments = $aShortcutInfo[2]
    $shortcut.Save()

    #ログ出力
    if([System.IO.File]::Exists($shortcutFile) -eq $true){ 
        fun_PrintLog (fun_FormatLog $strSection "ADD" "AFTER" $strKey $shortcutFile)
    }
    else{
        fun_PrintLog (fun_FormatLog $strSection "ADD" "AFTER" $strKey "")
    }
}

############################################################################
#                                                                          #
#   概要    ：ショットカットを削除する。                                   #
#                                                                          #
############################################################################
function fun_DelShortcut([string]$strSection,[string]$strKey,[string]$strValue){
    #ショットカットディレクトリ
    $strShortcutPath = [System.IO.Path]::Combine($gCurrentPath,"shortcut")
    #ショットカットファイル
    $shortcutFile = [System.IO.Path]::Combine($strShortcutPath,$strKey+".lnk")

    #ショットカットセクションのみ対象
    if($strSection -ne "SHORTCUT"){
        return
    }

    #ログ出力
    if([System.IO.File]::Exists($shortcutFile) -eq $true){ 
        fun_PrintLog (fun_FormatLog $strSection "DEL" "BEFORE" $strKey $shortcutFile)
    }
    else{
        fun_PrintLog (fun_FormatLog $strSection "DEL" "BEFORE" $strKey "")
    }

    #ショットカットファイル削除
    if([System.IO.File]::Exists($shortcutFile) -eq $true){ 
        [System.IO.File]::Delete($shortcutFile)
    }

    #ログ出力
    if([System.IO.File]::Exists($shortcutFile) -eq $false){ 
        fun_PrintLog (fun_FormatLog $strSection "DEL" "AFTER" $strKey "")
    }
    else{
        fun_PrintLog (fun_FormatLog $strSection "DEL" "AFTER" $strKey $shortcutFile)
    }
}

############################################################################
#                                                                          #
#   概要    ：CMDを実行する。                                              #
#                                                                          #
############################################################################
function fun_ExecCmd([string]$strKey,[string]$strValue){
    if($strKey -ne "CMD"){
        return 
    }

    [string]$strEdit = [String]::Empty
    [string]$strTemp = [String]::Empty
    [string[]]$aCmd = $strValue -split " "
    
    foreach($strTemp in $aCmd){
        if((fun_IsNullOrWhiteSpace $strTemp) -eq $true){
            continue
        }
        if((fun_IsNullOrWhiteSpace $strEdit) -eq $false){
            $strEdit = -join($strEdit," ")
        }
        $strTemp = fun_GetFullPath $strTemp
        $strEdit = -join($strEdit,$strTemp)
    }

    #ログ出力
    $strTemp = -join("Execute cmd:",$strEdit)
    Write-Host $strTemp
    fun_PrintLog $strTemp
    #CMD実行
    cmd /C $strEdit
}

############################################################################
#                                                                          #
#   概要    ：環境変数の設定を実行する。                                   #
#                                                                          #
############################################################################
function fun_SettingEnv([string]$strOperation){
    if((fun_IsNullOrWhiteSpace $strOperation) -eq $True){
        fun_PrintLog "Operation parameter is null."
        return
    }

    #INIファイル設定ルール
    [string]$strMatchRule = "[_]*[a-zA-Z]+[_a-zA-Z0-9]*"
    #INIファイルを取得
    $lines = Get-Content $gStrIniFile -Encoding UTF8

    #INIファイルを１行つづロープする
    [string]$strSection = [string]::Empty
    [string]$strKey = [string]::Empty
    [string]$strValue = [string]::Empty
    foreach($line in $lines){
        #空行の場合はループを続ける
        if($line -match "^$"){continue}
        #スペースの行の場合はループを続ける
        if($line -match "^\s*$"){continue}
        #先頭に「;」がある行はコメントアウトの行のため、ループを続ける
        if($line -match "^\s*;"){continue}

        #セクション取得
        if($line -match "^\s*\[\s*(" + $strMatchRule + ")\s*\]\s*$"){
             if($Matches.Count -eq 2){
                $strSection = $Matches.item(1)
                $strSection = $strSection.ToUpper()
                continue
             }
        }

        #セクション取得出来なかった場合はループを続ける
        if((fun_IsNullOrWhiteSpace $strSection) -eq $True){continue}

        #INIファイルで設定したKey、Valueを取得して
        #セクションより環境変数の設定を行う
        $strKey = [string]::Empty
        $strValue = [string]::Empty
        #Key、Valueが正しく設定されている場合
        if($line -match "^(.*)=(.*)$"){
            if($Matches.Count -eq 3){
                #key取得
                $strKey = $Matches.item(1)
                $strKey = $strKey.Trim()
                #Value取得
                $strValue = $Matches.item(2)
                $strValue = $strValue.Trim()

                #key空白設定チェック
                if((fun_IsNullOrWhiteSpace $strKey) -eq $True){
                    fun_PrintLog (fun_FormatLog $strSection "ERROR" "DONOTHING" $strKey $strValue)
                    fun_PrintLog "Key is null."
                    continue
                }
                #value空白設定チェック
                if((fun_IsNullOrWhiteSpace $strKey) -eq $True){
                    fun_PrintLog (fun_FormatLog $strSection "ERROR" "DONOTHING" $strKey $strValue)
                     fun_PrintLog "Value is null."
                    continue
                }
                #パス設定チェック
                if($strValue -match "[%]+"){
                    fun_PrintLog (fun_FormatLog $strSection "ERROR" "DONOTHING" $strKey $strValue)
                    fun_PrintLog (-join("Can not analaze """,$strValue,""""))
                    continue
                }

                #セクション値より設定宛先決定
                switch($strSection.ToUpper()){
                    "SYSTEM"  {$enumTargt = [System.EnvironmentVariableTarget]::Machine}
                    "USER"{$enumTargt = [System.EnvironmentVariableTarget]::User}
                    default {$enumTargt = $null}
                }
                #呼び出し引数より変更操作決定
                switch($strOperation){
                    "REGIST"    {
                                    switch($strSection.ToUpper()){
                                        "SYSTEM" {fun_AddEnv $enumTargt $strKey $strValue}
                                        "USER" {fun_AddEnv $enumTargt $strKey $strValue}
                                        "SHORTCUT"  {fun_AddShortcut $strSection.ToUpper() $strKey $strValue}
                                        "INSTALL"{fun_ExecCmd $strKey $strValue}
                                        "UNINSTALL"{}
                                        default {fun_PrintLog "Unknown section """ + $strSection + """."}
                                    }
                                    
                                }
                    "UNREGIST"　{
                                    switch($strSection.ToUpper()){
                                        "SYSTEM"{fun_DelEnv $enumTargt $strKey $strValue}
                                        "USER"{fun_DelEnv $enumTargt $strKey $strValue}
                                        "SHORTCUT"  {fun_DelShortcut $strSection.ToUpper() $strKey $strValue}
                                        "INSTALL"{}
                                        "UNINSTALL"{fun_ExecCmd $strKey $strValue}
                                        default {fun_PrintLog "Unknown section """ + $strSection + """."}
                                    }
                                    
                                }
                    default { return}
                }
            }
        }
    }
}

############################################################################
#                                                                          #
#   スクリプトスタードアップ                                               #
#                                                                          #
############################################################################
#スクリプト置きパス
#[string]$gCurrentPath = $PSScriptRoot    #PowerShell 3+ 
[string]$gCurrentPath = Split-Path -Parent $MyInvocation.MyCommand.Path #PowerShell 2
#INIファイルのフルパス取得
[string]$gStrIniFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path,".ini")   
#ログファイルのフルパス取得
[string]$gSrLogFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path,".log")

#権限確認
#Get-ExecutionPolicy -list
#powershell スクリプト実行権限追加
#Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine
#powershell スクリプト実行権限復旧
#Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope LocalMachine

#$operation="regist"
fun_SettingEnv $operation