param(
    [int]$Port = 8080
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent (Split-Path -Parent `
    $MyInvocation.MyCommand.Path)
$jenkinsHome = Join-Path $repositoryRoot ".jenkins-home"
$jenkinsWar = Join-Path $repositoryRoot ".tools\jenkins\jenkins.war"
$gitFolder = "C:\Program Files\Git\cmd"
$java = Get-ChildItem -LiteralPath "C:\Program Files\Eclipse Adoptium" `
    -Recurse -Filter "java.exe" |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $java) {
    throw "Java 21 was not found."
}
if (-not (Test-Path -LiteralPath $jenkinsWar)) {
    throw "Jenkins WAR was not found at $jenkinsWar."
}
if (-not (Test-Path -LiteralPath (Join-Path $gitFolder "git.exe"))) {
    throw "Git for Windows was not found."
}
if (-not (Test-Path -LiteralPath $jenkinsHome)) {
    New-Item -ItemType Directory -Path $jenkinsHome | Out-Null
}

$env:JENKINS_HOME = $jenkinsHome
$env:Path = "$gitFolder;$env:Path"
$env:GIT_SSL_BACKEND = "openssl"
Start-Process -FilePath $java `
    -ArgumentList @("-jar", $jenkinsWar, "--httpPort=$Port") `
    -WorkingDirectory $repositoryRoot `
    -WindowStyle Hidden

Write-Host "Jenkins is starting at http://localhost:$Port"
Write-Host "JENKINS_HOME: $jenkinsHome"
Write-Host "Initial password: $jenkinsHome\secrets\initialAdminPassword"
