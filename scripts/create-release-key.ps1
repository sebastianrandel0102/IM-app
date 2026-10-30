$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskKeyPath = Join-Path $taskRoot 'android\keystores\bear-with-me-upload.jks'
$taskPropertiesPath = Join-Path $taskRoot 'android\key.properties'
if ((Test-Path -LiteralPath $taskKeyPath) -or (Test-Path -LiteralPath $taskPropertiesPath)) {
    throw 'A signing file already exists. Reuse it; this script never replaces signing material.'
}
$taskKeytool = if ($env:JAVA_HOME -and (Test-Path -LiteralPath (Join-Path $env:JAVA_HOME 'bin\keytool.exe'))) {
    Join-Path $env:JAVA_HOME 'bin\keytool.exe'
} elseif (Test-Path -LiteralPath 'D:\Program Files\Android\Android Studio\jbr\bin\keytool.exe') {
    'D:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
} else { (Get-Command keytool -ErrorAction Stop).Source }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $taskKeyPath) | Out-Null
$taskBytes = New-Object byte[] 32
$taskRng = [Security.Cryptography.RandomNumberGenerator]::Create()
try { $taskRng.GetBytes($taskBytes) } finally { $taskRng.Dispose() }
$taskPassword = [Convert]::ToBase64String($taskBytes)
$env:BEAR_UPLOAD_STORE_PASSWORD = $taskPassword
try {
    & $taskKeytool -genkeypair -keystore $taskKeyPath -storetype PKCS12 -alias upload -keyalg RSA -keysize 3072 -validity 10000 -dname 'CN=Bear With Me, O=Bear With Me, C=PH' -storepass:env BEAR_UPLOAD_STORE_PASSWORD -keypass:env BEAR_UPLOAD_STORE_PASSWORD
    if ($LASTEXITCODE -ne 0) { throw 'Signing key generation failed.' }
    @("storePassword=$taskPassword", "keyPassword=$taskPassword", 'keyAlias=upload', 'storeFile=keystores/bear-with-me-upload.jks') | Set-Content -LiteralPath $taskPropertiesPath -Encoding ASCII
} finally { Remove-Item Env:\BEAR_UPLOAD_STORE_PASSWORD -ErrorAction SilentlyContinue }
Write-Output 'Release signing key created. Back up android/keystores/bear-with-me-upload.jks and android/key.properties securely; neither is tracked by Git.'
