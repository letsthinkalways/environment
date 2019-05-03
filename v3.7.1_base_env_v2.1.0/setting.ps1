<#
    ��Ҫ    ��INI�ե�������O�����h��������׷�ӣ�������g�Ф��롣
              ���ӳ��������ϡ�regist��unregist����ָ�������ܡ�
              regist�����h������׷��
              unregist���h����������
              INI�ե�����Υ��������ϡ�SYSTEM��USER����ָ�������ܡ�
              SYSTEM�������ƥ�h������
              USER������`���h������

    �����Օr��2018/11/16 V1.0����Ҏ����
    �����Օr��2018/11/25 V1.1�������ѥ������C��׷��
    �����Օr��2018/11/29 V1.2��CMD�g�ЙC��׷��
    �����Օr��2019/05/03 V1.3��CMD�ǥѥ�ȡ��ʧ���������Ϥ������򤽤Τޤޑ�����
#>

############################################################################
#                                                                          #
#   ���ӳ������� -operation <regist|unregist>                              #
#                                                                          #
############################################################################
param(
    [string]$operation
)

############################################################################
#                                                                          #
#   ��Ҫ    ���ե�ѥ���ȡ�ä��롣                                         #
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
#   ��Ҫ    �������Ф��հס����ک`���ΤߤǤ��뤫������å����롣           #
#    �������� True�����С�False�����ФǤϤʤ�                              #
#                                                                          #
############################################################################
function fun_IsNullOrWhiteSpace([string]$strString){
    #���ФǤ��뤫������å�
    if($strString -match "^$"){return $True}
    #���ک`���ΤߤǤ��뤫������å�
    if($strString -match "^\s*$"){return $True}
    return $False
}

############################################################################
#                                                                          #
#   ��Ҫ    ������åȥ��å��O������ȡ�ä���           ������������������#
#             INI�Ǥϡ��h��;�ѥ�;�ѥ��`��������ʽ���O�����롣            #
#                                                                          #
############################################################################
function fun_GetShortcutInfo([string]$strString){
    [string]$strTempPath
    [string]$strTempParam
    [string]$strEditor
    [string[]]$aString = $strString -split ";"

    #�h��;�ѥ�;�ѥ��`��
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
        #;�ѥ�;�ѥ��`��
        if([System.IO.File]::Exists($strTempPath)){
            $strTempParam = $aString[1].Replace("""","")
            $strTempParam = fun_GetFullPath $strTempParam
            $strEditor = -join(";",$strTempPath,";",$strTempParam)
        }
        #�h��;�ѥ�;
        else{
            $strTempPath = $aString[1].Replace("""","")
            $strTempPath = fun_GetFullPath $strTempPath
            $strEditor = -join($aString[0],";",$strTempPath,";")
        }
    }
    #;�ѥ�;
    if ($aString.Length -eq 1){
        $strTempPath = $aString[0].Replace("""","")
        $strTempPath = fun_GetFullPath $strTempPath
        $strEditor = -join(";",$strTempPath,";") 
    }

    return $strEditor
}

############################################################################
#                                                                          #
#   ��Ҫ    ���h�������O������������롣                                 #
#                                                                          #
############################################################################
function fun_PrintLog([string]$strMessage){
    #��`�����Օrȡ��
    [string]$strNow = get-date -Format "yyy/MM/dd HH:mm:ss"
    #���ե�����س���
    $strMessage = -join("[",$strNow,"]",$strMessage)
    Write-Output $strMessage | Out-File $gSrLogFile -Append -Encoding UTF8
}

############################################################################
#                                                                          #
#   ��Ҫ    ���g�Х��򾎼����롣                                         #
#                                                                          #
############################################################################
function fun_FormatLog([string]$strTarget,[string]$strOperation,[string]$strStatus,[string]$strEnvName,[string]$strEnvValue){

    #�������ݥե��ޥå�
    [string]$strMessage = -join("[",$strTarget,"][",$strOperation,"][",$strStatus,"]{key:""",$strEnvName,""" value:""",$strEnvValue,"""}")
    #����
    return $strMessage
}

############################################################################
#                                                                          #
#   ��Ҫ    ���h��������׷�Ӥ��롣                                         #
#                                                                          #
############################################################################
function fun_AddEnv([System.EnvironmentVariableTarget]$enumTargt,[string]$strKey,[string]$strValue){

    if ($enumTargt -eq $null){
        return
    }

    #�O���g�ߤέh��������ȡ�ä���
    [string]$strValueEditor = [Environment]::GetEnvironmentVariable($strKey,$enumTargt)

    #���ǰ�έh����������ե�����س���
    fun_PrintLog (fun_FormatLog $enumTargt.ToString() "ADD" "BEFORE" $strKey $strValueEditor)

    #�ե�ѥ�ȡ��
    $strValue = fun_GetFullPath $strValue

    #�h�������˥��`���åȂ������Ǥ��O������Ƥ��뤫��_�J����
    if((fun_IsNullOrWhiteSpace $strValueEditor) -eq $False){
        #�ޤ��O������Ƥ��ʤ����Ϥϡ����`���åȂ����O������
        if((";" + $strValueEditor.ToLower() + ";").Contains(";"+ $strValue.ToLower()+";") -eq $False){
            #�O�����Ƥ��ʤ����Ϥϡ��������֤Ρ�;���򸶤���
            if($strValueEditor -match ";\s*$" -eq $False){
                $strValueEditor = $strValueEditor + ";"
            }
            #�O���g�߭h�����������`���åȂ��O��
            $strValueEditor = $strValueEditor + $strValue
        }
        else{
            #���`���åȂ��򥯥ꥢ����
            $strValueEditor = [string]::Empty
        }
    }
    else{
        #�Τˤ��O�����Ƥ��ʤ����Ϥϡ����`���åȂ��򤽤Τޤ��O��
        $strValueEditor = $strValue
    }
    #�h�������O��
    if((fun_IsNullOrWhiteSpace $strValueEditor) -eq $False){
        [Environment]::SetEnvironmentVariable($strKey,$strValueEditor,$enumTargt)
    }

    #�����έh����������ե�����س���
    $strValueEditor = [Environment]::GetEnvironmentVariable($strKey,$enumTargt)
    fun_PrintLog (fun_FormatLog $enumTargt.ToString() "ADD" "AFTER" $strKey $strValueEditor)
}

############################################################################
#                                                                          #
#   ��Ҫ    ���h���������������롣                                         #
#                                                                          #
############################################################################
function fun_DelEnv([System.EnvironmentVariableTarget]$enumTargt,[string]$strKey,[string]$strValue){

    if ($enumTargt -eq $null){
        return
    }

    #�O���g�ߤέh��������ȡ�ä��롣
    [string]$strValueEditor = [Environment]::GetEnvironmentVariable($strKey,$enumTargt)

    #���ǰ�έh����������ե�����س���
    fun_PrintLog (fun_FormatLog $enumTargt.ToString() "DEL" "BEFORE" $strKey $strValueEditor)

    #�ե�ѥ�ȡ��
    $strValue = fun_GetFullPath $strValue

    #�O���g�ߤέh��������;���Ƿָ��
    #�������`���åȤ΂��ȱ��^���ơ�ԓ��������Ϥό�����ˤ���
    [string[]]$aryValues = $strValueEditor.Split(";")
    $strValueEditor = ""
    for($cnt = 0;$cnt -lt $aryValues.Length;$cnt++){
        #�հפ��O�����ό�����ˤ���
        if((fun_IsNullOrWhiteSpace $aryValues[$cnt]) -eq $False){
            #���`���åȂ��Έ��Ϥό�����ˤ���
            if($aryValues[$cnt].Trim() -ne $strValue){
                #�������֤Ρ�;��׷��
                if((fun_IsNullOrWhiteSpace $strValueEditor) -eq $False){
                    $strValueEditor = $strValueEditor + ";"
                }
                #�O��������O������ȡ��
                $strValueEditor = $strValueEditor + $aryValues[$cnt].Trim()
            }
        }
    }
    #�h�������O��
    [Environment]::SetEnvironmentVariable($strKey,$strValueEditor,$enumTargt)

    #�����έh����������ե�����س���
    $strValueEditor = [Environment]::GetEnvironmentVariable($strKey,$enumTargt)    
    fun_PrintLog (fun_FormatLog $enumTargt.ToString() "DEL" "AFTER" $strKey $strValueEditor)
}

############################################################################
#                                                                          #
#   ��Ҫ    ������åȥ��åȤ����ɤ��롣                                   #
#                                                                          #
############################################################################
function fun_AddShortcut([string]$strSection,[string]$strKey,[string]$strValue){
    #����åȥ��åȥǥ��쥯�ȥ�
    $strShortcutPath = [System.IO.Path]::Combine($gCurrentPath,"shortcut")
    #����åȥ��åȥե�����
    $shortcutFile = [System.IO.Path]::Combine($strShortcutPath,$strKey+".lnk")

    #����åȥ��åȥ��������Τߌ���
    if($strSection -ne "SHORTCUT"){
        return
    }

    #������
    if([System.IO.File]::Exists($shortcutFile) -eq $true){ 
        fun_PrintLog (fun_FormatLog $strSection "ADD" "BEFORE" $strKey $shortcutFile)
    }
    else{
        fun_PrintLog (fun_FormatLog $strSection "ADD" "BEFORE" $strKey "")
    }

    #�ǥ��쥯�ȥ꤬���ڤ��ʤ����Ϥϡ���Ҏ����
    if([System.IO.Directory]::Exists($strShortcutPath) -eq $false){
        New-Item -Path $gCurrentPath -Name "shortcut" -ItemType directory
    }
    #����åȥ��å�����
    $strValue = (fun_GetShortcutInfo $strValue)
    [string[]]$aShortcutInfo = $strValue -split ";"
    $shell = New-Object -ComObject Wscript.shell
    $shortcut = $shell.CreateShortcut( $shortcutFile)
    $shortcut.Description = $aShortcutInfo[0]
    $shortcut.TargetPath = $aShortcutInfo[1]
    $shortcut.Arguments = $aShortcutInfo[2]
    $shortcut.Save()

    #������
    if([System.IO.File]::Exists($shortcutFile) -eq $true){ 
        fun_PrintLog (fun_FormatLog $strSection "ADD" "AFTER" $strKey $shortcutFile)
    }
    else{
        fun_PrintLog (fun_FormatLog $strSection "ADD" "AFTER" $strKey "")
    }
}

############################################################################
#                                                                          #
#   ��Ҫ    ������åȥ��åȤ��������롣                                   #
#                                                                          #
############################################################################
function fun_DelShortcut([string]$strSection,[string]$strKey,[string]$strValue){
    #����åȥ��åȥǥ��쥯�ȥ�
    $strShortcutPath = [System.IO.Path]::Combine($gCurrentPath,"shortcut")
    #����åȥ��åȥե�����
    $shortcutFile = [System.IO.Path]::Combine($strShortcutPath,$strKey+".lnk")

    #����åȥ��åȥ��������Τߌ���
    if($strSection -ne "SHORTCUT"){
        return
    }

    #������
    if([System.IO.File]::Exists($shortcutFile) -eq $true){ 
        fun_PrintLog (fun_FormatLog $strSection "DEL" "BEFORE" $strKey $shortcutFile)
    }
    else{
        fun_PrintLog (fun_FormatLog $strSection "DEL" "BEFORE" $strKey "")
    }

    #����åȥ��åȥե���������
    if([System.IO.File]::Exists($shortcutFile) -eq $true){ 
        [System.IO.File]::Delete($shortcutFile)
    }

    #������
    if([System.IO.File]::Exists($shortcutFile) -eq $false){ 
        fun_PrintLog (fun_FormatLog $strSection "DEL" "AFTER" $strKey "")
    }
    else{
        fun_PrintLog (fun_FormatLog $strSection "DEL" "AFTER" $strKey $shortcutFile)
    }
}

############################################################################
#                                                                          #
#   ��Ҫ    ��CMD��g�Ф��롣                                              #
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

    #������
    $strTemp = -join("Execute cmd:",$strEdit)
    Write-Host $strTemp
    fun_PrintLog $strTemp
    #CMD�g��
    cmd /C $strEdit
}

############################################################################
#                                                                          #
#   ��Ҫ    ���h���������O����g�Ф��롣                                   #
#                                                                          #
############################################################################
function fun_SettingEnv([string]$strOperation){
    if((fun_IsNullOrWhiteSpace $strOperation) -eq $True){
        fun_PrintLog "Operation parameter is null."
        return
    }

    #INI�ե������O����`��
    [string]$strMatchRule = "[_]*[a-zA-Z]+[_a-zA-Z0-9]*"
    #INI�ե������ȡ��
    $lines = Get-Content $gStrIniFile -Encoding UTF8

    #INI�ե�������ФĤť�`�פ���
    [string]$strSection = [string]::Empty
    [string]$strKey = [string]::Empty
    [string]$strValue = [string]::Empty
    foreach($line in $lines){
        #���ФΈ��Ϥϥ�`�פ�A����
        if($line -match "^$"){continue}
        #���ک`�����ФΈ��Ϥϥ�`�פ�A����
        if($line -match "^\s*$"){continue}
        #���^�ˡ�;���������Фϥ����ȥ����Ȥ��ФΤ��ᡢ��`�פ�A����
        if($line -match "^\s*;"){continue}

        #���������ȡ��
        if($line -match "^\s*\[\s*(" + $strMatchRule + ")\s*\]\s*$"){
             if($Matches.Count -eq 2){
                $strSection = $Matches.item(1)
                $strSection = $strSection.ToUpper()
                continue
             }
        }

        #���������ȡ�ó����ʤ��ä����Ϥϥ�`�פ�A����
        if((fun_IsNullOrWhiteSpace $strSection) -eq $True){continue}

        #INI�ե�������O������Key��Value��ȡ�ä���
        #�����������h���������O�����Ф�
        $strKey = [string]::Empty
        $strValue = [string]::Empty
        #Key��Value���������O������Ƥ������
        if($line -match "^(.*)=(.*)$"){
            if($Matches.Count -eq 3){
                #keyȡ��
                $strKey = $Matches.item(1)
                $strKey = $strKey.Trim()
                #Valueȡ��
                $strValue = $Matches.item(2)
                $strValue = $strValue.Trim()

                #key�հ��O�������å�
                if((fun_IsNullOrWhiteSpace $strKey) -eq $True){
                    fun_PrintLog (fun_FormatLog $strSection "ERROR" "DONOTHING" $strKey $strValue)
                    fun_PrintLog "Key is null."
                    continue
                }
                #value�հ��O�������å�
                if((fun_IsNullOrWhiteSpace $strKey) -eq $True){
                    fun_PrintLog (fun_FormatLog $strSection "ERROR" "DONOTHING" $strKey $strValue)
                     fun_PrintLog "Value is null."
                    continue
                }
                #�ѥ��O�������å�
                if($strValue -match "[%]+"){
                    fun_PrintLog (fun_FormatLog $strSection "ERROR" "DONOTHING" $strKey $strValue)
                    fun_PrintLog (-join("Can not analaze """,$strValue,""""))
                    continue
                }

                #��������󂎤���O�����țQ��
                switch($strSection.ToUpper()){
                    "SYSTEM"  {$enumTargt = [System.EnvironmentVariableTarget]::Machine}
                    "USER"{$enumTargt = [System.EnvironmentVariableTarget]::User}
                    default {$enumTargt = $null}
                }
                #���ӳ�����������������Q��
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
                    "UNREGIST"��{
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
#   ������ץȥ����`�ɥ��å�                                               #
#                                                                          #
############################################################################
#������ץ��ä��ѥ�
#[string]$gCurrentPath = $PSScriptRoot    #PowerShell 3+ 
[string]$gCurrentPath = Split-Path -Parent $MyInvocation.MyCommand.Path #PowerShell 2
#INI�ե�����Υե�ѥ�ȡ��
[string]$gStrIniFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path,".ini")   
#���ե�����Υե�ѥ�ȡ��
[string]$gSrLogFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path,".log")

#���޴_�J
#Get-ExecutionPolicy -list
#powershell ������ץȌg�И���׷��
#Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine
#powershell ������ץȌg�И��ޏ;�
#Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope LocalMachine

#$operation="regist"
fun_SettingEnv $operation