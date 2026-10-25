param(
    [Parameter(Mandatory = $true)][string]$Apk,
    [Parameter(Mandatory = $true)][string]$Serial,
    [Parameter(Mandatory = $true)][string]$OutputDirectory,
    [string]$Sdk = "$env:LOCALAPPDATA/Android/Sdk"
)
$ErrorActionPreference = 'Stop'
$adb = Join-Path $Sdk 'platform-tools/adb.exe'
$analyzer = Join-Path $Sdk 'cmdline-tools/latest/bin/apkanalyzer.bat'
$apkPath = (Resolve-Path -LiteralPath $Apk).Path
if ((& $adb -s $Serial shell getprop ro.kernel.qemu).Trim() -ne '1') {
    throw 'Use a test emulator. This check never installs on a physical phone.'
}
$databaseCode = & $analyzer dex code --class androidx.work.impl.WorkDatabase_Impl $apkPath
if ($LASTEXITCODE -ne 0 -or
    -not ($databaseCode | Select-String -SimpleMatch '.method public constructor <init>()V')) {
    throw 'Release is missing the reflective WorkDatabase_Impl constructor.'
}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
& $adb -s $Serial shell am force-stop com.thinkheim.app
& $adb -s $Serial install -r $apkPath
if ($LASTEXITCODE -ne 0) { throw 'APK installation failed; existing emulator data was preserved.' }
& $adb -s $Serial logcat -c
& $adb -s $Serial shell am start -n com.thinkheim.app/com.thinkheim.app.MainActivity
if ($LASTEXITCODE -ne 0) { throw 'Activity launch failed.' }
Start-Sleep -Seconds 10
$appPid = (& $adb -s $Serial shell pidof com.thinkheim.app).Trim()
$logs = & $adb -s $Serial logcat -d
$logs | Set-Content -LiteralPath (Join-Path $OutputDirectory 'logcat.txt')
$activities = & $adb -s $Serial shell dumpsys activity activities
$activities | Set-Content -LiteralPath (Join-Path $OutputDirectory 'activities.txt')
if (-not $appPid -or ($logs | Select-String 'FATAL EXCEPTION')) {
    throw 'Release crashed. Inspect logcat.txt.'
}
if (-not ($activities | Select-String '(mResumedActivity|topResumedActivity).*com.thinkheim.app/.MainActivity')) {
    throw 'MainActivity is not resumed. Inspect activities.txt.'
}
& $adb -s $Serial shell screencap -p /sdcard/thinkheim-release-smoke.png
& $adb -s $Serial pull /sdcard/thinkheim-release-smoke.png (Join-Path $OutputDirectory 'screen.png')
Write-Output "Release remained running (PID $appPid). Inspect screen.png to verify Flutter rendered the home screen."
