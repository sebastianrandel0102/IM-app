param([switch]$RulesOnly)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskNode = Join-Path $taskRoot '.tools\node.exe'
if (-not (Test-Path -LiteralPath $taskNode)) { $taskNode = (Get-Command node -ErrorAction Stop).Source }
$env:Path = (Split-Path -Parent $taskNode) + ';' + $env:Path
$taskJbr = 'D:\Program Files\Android\Android Studio\jbr\bin'
if (Test-Path -LiteralPath $taskJbr) { $env:Path = $taskJbr + ';' + $env:Path }
$env:DEBUG = ''
$taskCli = Join-Path $taskRoot 'node_modules\firebase-tools\lib\bin\firebase.js'
Push-Location -LiteralPath $taskRoot
try {
    & $taskNode $taskCli emulators:exec --project demo-bear-with-me --only firestore 'node --test firebase/tests/*.test.mjs'
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    if (-not $RulesOnly) {
        & $taskNode $taskCli emulators:exec --project demo-bear-with-me --only auth,firestore 'node firebase/tests/two-client.mjs'
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
} finally { Pop-Location }
