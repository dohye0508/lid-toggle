# 노트북 덮개 닫기 동작 토글
# 0 = 아무 것도 안 함 (닫아도 켜짐) / 1 = 절전

$sub  = '4f971e89-eebd-4455-a8de-9e59040e7347'
$set  = '5ca83367-6e45-459f-a27b-476b1d01c936'

# 현재 활성 전원 구성표 GUID 확인
$active = (powercfg /getactivescheme) -replace '^.*?([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}).*$', '$1'
$key = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$active\$sub\$set"

$cur = 1
try { $cur = (Get-ItemProperty -Path $key -ErrorAction Stop).ACSettingIndex } catch { }

if ($cur -eq 0) { $new = 1 } else { $new = 0 }

powercfg /setacvalueindex $active $sub $set $new | Out-Null
powercfg /setdcvalueindex $active $sub $set $new | Out-Null
powercfg /setactive $active | Out-Null

if ($new -eq 0) {
    $title = '덮개 닫아도 켜짐'
    $body  = '노트북을 닫아도 절전으로 가지 않습니다.'
} else {
    $title = '덮개 닫으면 절전'
    $body  = '기본 동작으로 돌아갔습니다.'
}

# 풍선 알림
Add-Type -AssemblyName System.Windows.Forms
$ni = New-Object System.Windows.Forms.NotifyIcon
$ni.Icon = [System.Drawing.SystemIcons]::Information
$ni.Visible = $true
$ni.ShowBalloonTip(4000, $title, $body, [System.Windows.Forms.ToolTipIcon]::Info)
Start-Sleep -Seconds 4
$ni.Dispose()
