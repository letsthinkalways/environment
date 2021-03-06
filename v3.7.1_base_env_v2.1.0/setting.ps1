<#
    古勣    ��INIファイルの�O協より�h廠�篳�の弖紗����茅を�g佩する。
              柵び竃し哈方は仝regist、unregist々の峺協が辛嬬。
              regist　�梱h廠�篳�弖紗
              unregist�梱h廠�篳���茅
              INIファイルのセクションは仝SYSTEM、USER々の峺協が辛嬬。
              SYSTEM�坤轡好謄爿h廠�篳�
              USER　�坤罘`ザ�h廠�篳�

    厚仟晩�r��2018/11/16 V1.0　仟�ﾗ�撹
    厚仟晩�r��2018/11/25 V1.1　����パス盾裂�C嬬弖紗
    厚仟晩�r��2018/11/29 V1.2　CMD�g佩�C嬬弖紗
    厚仟晩�r��2019/05/03 V1.3　CMDでパス函誼払�，靴���栽は哈方をそのまま��す。
#>

############################################################################
#                                                                          #
#   柵び竃し哈方 -operation <regist|unregist>                              #
#                                                                          #
############################################################################
param(
    [string]$operation
)

############################################################################
#                                                                          #
#   古勣    �坤侫襯僖垢鯣ゝ辰垢襦�                                         #
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
#   古勣    �採鍔崛个�腎易、スペ�`スのみであるかをチェックする。           #
#    　　　　 True�鎖孃弌�False�鎖孃个任呂覆�                              #
#                                                                          #
############################################################################
function fun_IsNullOrWhiteSpace([string]$strString){
    #腎佩であるかをチェック
    if($strString -match "^$"){return $True}
    #スペ�`スのみであるかをチェック
    if($strString -match "^\s*$"){return $True}
    return $False
}

############################################################################
#                                                                          #
#   古勣    �坤轡腑奪肇�ット�O協秤�鵑鯣ゝ辰垢�           　　　　　　　　　#
#             INIでは仝�h苧;パス;パラメ�`タ々の侘塀で�O協する。            #
#                                                                          #
############################################################################
function fun_GetShortcutInfo([string]$strString){
    [string]$strTempPath
    [string]$strTempParam
    [string]$strEditor
    [string[]]$aString = $strString -split ";"

    #�h苧;パス;パラメ�`タ
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
        #;パス;パラメ�`タ
        if([System.IO.File]::Exists($strTempPath)){
            $strTempParam = $aString[1].Replace("""","")
            $strTempParam = fun_GetFullPath $strTempParam
            $strEditor = -join(";",$strTempPath,";",$strTempParam)
        }
        #�h苧;パス;
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
#   古勣    �梱h廠�篳��O協ログを竃薦する。                                 #
#                                                                          #
############################################################################
function fun_PrintLog([string]$strMessage){
    #ロ�`カル晩�r函誼
    [string]$strNow = get-date -Format "yyy/MM/dd HH:mm:ss"
    #ログファイルへ竃薦
    $strMessage = -join("[",$strNow,"]",$strMessage)
    Write-Output $strMessage | Out-File $gSrLogFile -Append -Encoding UTF8
}

############################################################################
#                                                                          #
#   古勣    ���g佩ログを�ｼ�する。                                         #
#                                                                          #
############################################################################
function fun_FormatLog([string]$strTarget,[string]$strOperation,[string]$strStatus,[string]$strEnvName,[string]$strEnvValue){

    #竃薦坪否フォマット
    [string]$strMessage = -join("[",$strTarget,"][",$strOperation,"][",$strStatus,"]{key:""",$strEnvName,""" value:""",$strEnvValue,"""}")
    #��す
    return $strMessage
}

############################################################################
#                                                                          #
#   古勣    �梱h廠�篳�を弖紗する。                                         #
#                                                                          #
############################################################################
function fun_AddEnv([System.EnvironmentVariableTarget]$enumTargt,[string]$strKey,[string]$strValue){

    if ($enumTargt -eq $null){
        return
    }

    #�O協�gみの�h廠�篳�を函誼する
    [string]$strValueEditor = [Environment]::GetEnvironmentVariable($strKey,$enumTargt)

    #�筝�念の�h廠�篳�をログファイルへ竃薦
    fun_PrintLog (fun_FormatLog $enumTargt.ToString() "ADD" "BEFORE" $strKey $strValueEditor)

    #フルパス函誼
    $strValue = fun_GetFullPath $strValue

    #�h廠�篳�にタ�`ゲット�､�すでに�O協されているかを�_�Jする
    if((fun_IsNullOrWhiteSpace $strValueEditor) -eq $False){
        #まだ�O協されていない��栽は、タ�`ゲット�､鰓O協する
        if((";" + $strValueEditor.ToLower() + ";").Contains(";"+ $strValue.ToLower()+";") -eq $False){
            #�O協していない��栽は、曝俳猟忖の仝;々を原ける
            if($strValueEditor -match ";\s*$" -eq $False){
                $strValueEditor = $strValueEditor + ";"
            }
            #�O協�gみ�h廠�篳���タ�`ゲット�ﾔO協
            $strValueEditor = $strValueEditor + $strValue
        }
        else{
            #タ�`ゲット�､鬟�リアする
            $strValueEditor = [string]::Empty
        }
    }
    else{
        #採にも�O協していない��栽は、タ�`ゲット�､鬚修里泙湟O協
        $strValueEditor = $strValue
    }
    #�h廠�篳��O協
    if((fun_IsNullOrWhiteSpace $strValueEditor) -eq $False){
        [Environment]::SetEnvironmentVariable($strKey,$strValueEditor,$enumTargt)
    }

    #�筝�瘁の�h廠�篳�をログファイルへ竃薦
    $strValueEditor = [Environment]::GetEnvironmentVariable($strKey,$enumTargt)
    fun_PrintLog (fun_FormatLog $enumTargt.ToString() "ADD" "AFTER" $strKey $strValueEditor)
}

############################################################################
#                                                                          #
#   古勣    �梱h廠�篳�を��茅する。                                         #
#                                                                          #
############################################################################
function fun_DelEnv([System.EnvironmentVariableTarget]$enumTargt,[string]$strKey,[string]$strValue){

    if ($enumTargt -eq $null){
        return
    }

    #�O協�gみの�h廠�篳�を函誼する。
    [string]$strValueEditor = [Environment]::GetEnvironmentVariable($strKey,$enumTargt)

    #�筝�念の�h廠�篳�をログファイルへ竃薦
    fun_PrintLog (fun_FormatLog $enumTargt.ToString() "DEL" "BEFORE" $strKey $strValueEditor)

    #フルパス函誼
    $strValue = fun_GetFullPath $strValue

    #�O協�gみの�h廠�篳�を仝;々で蛍護し、
    #��茅タ�`ゲットの�､髪否^して、��輝する��栽は���麝發砲垢�
    [string[]]$aryValues = $strValueEditor.Split(";")
    $strValueEditor = ""
    for($cnt = 0;$cnt -lt $aryValues.Length;$cnt++){
        #腎易の�O協�､����麝發砲垢�
        if((fun_IsNullOrWhiteSpace $aryValues[$cnt]) -eq $False){
            #タ�`ゲット�､���栽は���麝發砲垢�
            if($aryValues[$cnt].Trim() -ne $strValue){
                #曝俳猟忖の仝;々弖紗
                if((fun_IsNullOrWhiteSpace $strValueEditor) -eq $False){
                    $strValueEditor = $strValueEditor + ";"
                }
                #�O協���鵑淋O協�､鯣ゝ�
                $strValueEditor = $strValueEditor + $aryValues[$cnt].Trim()
            }
        }
    }
    #�h廠�篳��O協
    [Environment]::SetEnvironmentVariable($strKey,$strValueEditor,$enumTargt)

    #�筝�瘁の�h廠�篳�をログファイルへ竃薦
    $strValueEditor = [Environment]::GetEnvironmentVariable($strKey,$enumTargt)    
    fun_PrintLog (fun_FormatLog $enumTargt.ToString() "DEL" "AFTER" $strKey $strValueEditor)
}

############################################################################
#                                                                          #
#   古勣    �坤轡腑奪肇�ットを恬撹する。                                   #
#                                                                          #
############################################################################
function fun_AddShortcut([string]$strSection,[string]$strKey,[string]$strValue){
    #ショットカットディレクトリ
    $strShortcutPath = [System.IO.Path]::Combine($gCurrentPath,"shortcut")
    #ショットカットファイル
    $shortcutFile = [System.IO.Path]::Combine($strShortcutPath,$strKey+".lnk")

    #ショットカットセクションのみ����
    if($strSection -ne "SHORTCUT"){
        return
    }

    #ログ竃薦
    if([System.IO.File]::Exists($shortcutFile) -eq $true){ 
        fun_PrintLog (fun_FormatLog $strSection "ADD" "BEFORE" $strKey $shortcutFile)
    }
    else{
        fun_PrintLog (fun_FormatLog $strSection "ADD" "BEFORE" $strKey "")
    }

    #ディレクトリが贋壓しない��栽は、仟�ﾗ�撹
    if([System.IO.Directory]::Exists($strShortcutPath) -eq $false){
        New-Item -Path $gCurrentPath -Name "shortcut" -ItemType directory
    }
    #ショットカット恬撹
    $strValue = (fun_GetShortcutInfo $strValue)
    [string[]]$aShortcutInfo = $strValue -split ";"
    $shell = New-Object -ComObject Wscript.shell
    $shortcut = $shell.CreateShortcut( $shortcutFile)
    $shortcut.Description = $aShortcutInfo[0]
    $shortcut.TargetPath = $aShortcutInfo[1]
    $shortcut.Arguments = $aShortcutInfo[2]
    $shortcut.Save()

    #ログ竃薦
    if([System.IO.File]::Exists($shortcutFile) -eq $true){ 
        fun_PrintLog (fun_FormatLog $strSection "ADD" "AFTER" $strKey $shortcutFile)
    }
    else{
        fun_PrintLog (fun_FormatLog $strSection "ADD" "AFTER" $strKey "")
    }
}

############################################################################
#                                                                          #
#   古勣    �坤轡腑奪肇�ットを��茅する。                                   #
#                                                                          #
############################################################################
function fun_DelShortcut([string]$strSection,[string]$strKey,[string]$strValue){
    #ショットカットディレクトリ
    $strShortcutPath = [System.IO.Path]::Combine($gCurrentPath,"shortcut")
    #ショットカットファイル
    $shortcutFile = [System.IO.Path]::Combine($strShortcutPath,$strKey+".lnk")

    #ショットカットセクションのみ����
    if($strSection -ne "SHORTCUT"){
        return
    }

    #ログ竃薦
    if([System.IO.File]::Exists($shortcutFile) -eq $true){ 
        fun_PrintLog (fun_FormatLog $strSection "DEL" "BEFORE" $strKey $shortcutFile)
    }
    else{
        fun_PrintLog (fun_FormatLog $strSection "DEL" "BEFORE" $strKey "")
    }

    #ショットカットファイル��茅
    if([System.IO.File]::Exists($shortcutFile) -eq $true){ 
        [System.IO.File]::Delete($shortcutFile)
    }

    #ログ竃薦
    if([System.IO.File]::Exists($shortcutFile) -eq $false){ 
        fun_PrintLog (fun_FormatLog $strSection "DEL" "AFTER" $strKey "")
    }
    else{
        fun_PrintLog (fun_FormatLog $strSection "DEL" "AFTER" $strKey $shortcutFile)
    }
}

############################################################################
#                                                                          #
#   古勣    ��CMDを�g佩する。                                              #
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

    #ログ竃薦
    $strTemp = -join("Execute cmd:",$strEdit)
    Write-Host $strTemp
    fun_PrintLog $strTemp
    #CMD�g佩
    cmd /C $strEdit
}

############################################################################
#                                                                          #
#   古勣    �梱h廠�篳�の�O協を�g佩する。                                   #
#                                                                          #
############################################################################
function fun_SettingEnv([string]$strOperation){
    if((fun_IsNullOrWhiteSpace $strOperation) -eq $True){
        fun_PrintLog "Operation parameter is null."
        return
    }

    #INIファイル�O協ル�`ル
    [string]$strMatchRule = "[_]*[a-zA-Z]+[_a-zA-Z0-9]*"
    #INIファイルを函誼
    $lines = Get-Content $gStrIniFile -Encoding UTF8

    #INIファイルを１佩つづロ�`プする
    [string]$strSection = [string]::Empty
    [string]$strKey = [string]::Empty
    [string]$strValue = [string]::Empty
    foreach($line in $lines){
        #腎佩の��栽はル�`プを�Aける
        if($line -match "^$"){continue}
        #スペ�`スの佩の��栽はル�`プを�Aける
        if($line -match "^\s*$"){continue}
        #枠�^に仝;々がある佩はコメントアウトの佩のため、ル�`プを�Aける
        if($line -match "^\s*;"){continue}

        #セクション函誼
        if($line -match "^\s*\[\s*(" + $strMatchRule + ")\s*\]\s*$"){
             if($Matches.Count -eq 2){
                $strSection = $Matches.item(1)
                $strSection = $strSection.ToUpper()
                continue
             }
        }

        #セクション函誼竃栖なかった��栽はル�`プを�Aける
        if((fun_IsNullOrWhiteSpace $strSection) -eq $True){continue}

        #INIファイルで�O協したKey、Valueを函誼して
        #セクションより�h廠�篳�の�O協を佩う
        $strKey = [string]::Empty
        $strValue = [string]::Empty
        #Key、Valueが屎しく�O協されている��栽
        if($line -match "^(.*)=(.*)$"){
            if($Matches.Count -eq 3){
                #key函誼
                $strKey = $Matches.item(1)
                $strKey = $strKey.Trim()
                #Value函誼
                $strValue = $Matches.item(2)
                $strValue = $strValue.Trim()

                #key腎易�O協チェック
                if((fun_IsNullOrWhiteSpace $strKey) -eq $True){
                    fun_PrintLog (fun_FormatLog $strSection "ERROR" "DONOTHING" $strKey $strValue)
                    fun_PrintLog "Key is null."
                    continue
                }
                #value腎易�O協チェック
                if((fun_IsNullOrWhiteSpace $strKey) -eq $True){
                    fun_PrintLog (fun_FormatLog $strSection "ERROR" "DONOTHING" $strKey $strValue)
                     fun_PrintLog "Value is null."
                    continue
                }
                #パス�O協チェック
                if($strValue -match "[%]+"){
                    fun_PrintLog (fun_FormatLog $strSection "ERROR" "DONOTHING" $strKey $strValue)
                    fun_PrintLog (-join("Can not analaze """,$strValue,""""))
                    continue
                }

                #セクション�､茲袵O協乱枠�Q協
                switch($strSection.ToUpper()){
                    "SYSTEM"  {$enumTargt = [System.EnvironmentVariableTarget]::Machine}
                    "USER"{$enumTargt = [System.EnvironmentVariableTarget]::User}
                    default {$enumTargt = $null}
                }
                #柵び竃し哈方より�筝�荷恬�Q協
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
#   スクリプトスタ�`ドアップ                                               #
#                                                                          #
############################################################################
#スクリプト崔きパス
#[string]$gCurrentPath = $PSScriptRoot    #PowerShell 3+ 
[string]$gCurrentPath = Split-Path -Parent $MyInvocation.MyCommand.Path #PowerShell 2
#INIファイルのフルパス函誼
[string]$gStrIniFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path,".ini")   
#ログファイルのフルパス函誼
[string]$gSrLogFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path,".log")

#�慙浚_�J
#Get-ExecutionPolicy -list
#powershell スクリプト�g佩�慙湫啓�
#Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine
#powershell スクリプト�g佩�慙�畺�
#Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope LocalMachine

#$operation="regist"
fun_SettingEnv $operation