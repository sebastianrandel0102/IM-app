$ErrorActionPreference = 'Stop'
$env:DEBUG = ''
$env:FIREBASE_CLI_DISABLE_UPDATE_CHECK = 'true'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskNode = Join-Path $taskRoot '.tools\node.exe'
$taskCli = Join-Path $taskRoot 'node_modules\firebase-tools\lib\bin\firebase.js'
if (-not (Test-Path -LiteralPath $taskNode)) {
    $taskNode = (Get-Command node -ErrorAction Stop).Source
}
if (-not (Test-Path -LiteralPath $taskCli)) {
    throw 'Run npm install from the project folder first.'
}
& $taskNode $taskCli @args
exit $LASTEXITCODE
