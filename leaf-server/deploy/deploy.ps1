$currentScriptLocation = Split-Path -Parent $MyInvocation.MyCommand.Path

$mvnPath = $currentScriptLocation + "\..\.."
# 远程服务器的密码
$username = "gepeng"
$password = "root"
$remoteIp = "192.168.112.129"
$remoteJarDir = "/home/gepeng/app/jar/"
$remoteJavaPath = "/home/gepeng/app/package/jdk1.8.0_371/bin/java"



$localJarDir = $currentScriptLocation + "\..\target\"

function initValue {
    $jarFiles = Get-ChildItem -Path $localJarDir -Filter "*.jar" -File
    if ($jarFiles.Count -gt 0) {
        $global:jarFileName = $jarFiles[0].Name
        $global:localJarPath = $localJarDir + $jarFileName
        $global:remoteJarPath = $remoteJarDir + $jarFileName
        Write-Host "Jar file found: $jarFileName"
    } else {
        Write-Host "No jar files found in the specified directory."
        Exit
    }
}

# 第一步：使用 mvn clean install 打包代码
function mvnInstall {
    Set-Location $mvnPath
    mvn clean install -DskipTests
}


# 第二步：复制生成的 jar 包到远程服务器
function copyFileToRemote {
    pscp -pw $password $localJarPath $username@${remoteIp}:$remoteJarPath
}


function KillJavaProcess {
    $sshCommand = "ps -ef | grep java"
    $result = & "plink" -pw $password $username@${remoteIp} $sshCommand

    $processId = ($result -split '\s+')[1]
    Write-Host $processId
    if ($processId) {
        $killCommand = "kill -9 $processId"
        & "plink" -pw $password $username@$remoteIp $killCommand
        Write-Host "process $processId killed."
    } else {
        Write-Host "not find need to kill process."
    }
}

# 第三步：登录远程服务器并执行 java -jar 命令
function executeJar {
    $command = "nohup $remoteJavaPath -jar $remoteJarPath &"
    & "plink" -pw $password $username@$remoteIp $command
}

mvnInstall
initValue
copyFileToRemote
KillJavaProcess
executeJar





