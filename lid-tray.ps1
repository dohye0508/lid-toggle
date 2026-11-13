# 노트북 덮개 닫기 동작 - 트레이 아이콘
# 초록색 = 닫아도 켜짐 / 회색 = 닫으면 절전

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$sub = '4f971e89-eebd-4455-a8de-9e59040e7347'
$set = '5ca83367-6e45-459f-a27b-476b1d01c936'

function Get-ActiveScheme {
    (powercfg /getactivescheme) -replace '^.*?([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}).*$', '$1'
}

function Get-LidState {
    $active = Get-ActiveScheme
    $key = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$active\$sub\$set"
    try { return [int](Get-ItemProperty -Path $key -ErrorAction Stop).ACSettingIndex } catch { return 1 }
}

function Set-LidState([int]$v) {
    $active = Get-ActiveScheme
    powercfg /setacvalueindex $active $sub $set $v | Out-Null
    powercfg /setdcvalueindex $active $sub $set $v | Out-Null
    powercfg /setactive $active | Out-Null
}

# 16x16 원형 아이콘을 직접 그린다
function New-DotIcon([System.Drawing.Color]$fill) {
    $bmp = New-Object System.Drawing.Bitmap 16, 16
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.Clear([System.Drawing.Color]::Transparent)
    $brush = New-Object System.Drawing.SolidBrush $fill
    $g.FillEllipse($brush, 1, 1, 13, 13)
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(120, 0, 0, 0)), 1
    $g.DrawEllipse($pen, 1, 1, 13, 13)
    $g.Dispose(); $brush.Dispose(); $pen.Dispose()
    $icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
    $bmp.Dispose()
    return $icon
}

$iconOn  = New-DotIcon ([System.Drawing.Color]::FromArgb(60, 190, 90))
$iconOff = New-DotIcon ([System.Drawing.Color]::FromArgb(130, 130, 130))

$ni = New-Object System.Windows.Forms.NotifyIcon
$menu = New-Object System.Windows.Forms.ContextMenuStrip

$miToggle = $menu.Items.Add('덮개 닫아도 켜짐')
$miToggle.CheckOnClick = $false
$menu.Items.Add('-') | Out-Null
$miExit = $menu.Items.Add('종료')

$ni.ContextMenuStrip = $menu

function Sync-Ui {
    $s = Get-LidState
    if ($s -eq 0) {
        $ni.Icon = $iconOn
        $ni.Text = '덮개 닫아도 켜짐'
        $script:miToggle.Checked = $true
    } else {
        $ni.Icon = $iconOff
        $ni.Text = '덮개 닫으면 절전'
        $script:miToggle.Checked = $false
    }
}

function Toggle-Lid {
    $s = Get-LidState
    if ($s -eq 0) { Set-LidState 1 } else { Set-LidState 0 }
    Sync-Ui
    if ((Get-LidState) -eq 0) {
        $ni.ShowBalloonTip(2500, '덮개 닫아도 켜짐', '노트북을 닫아도 절전으로 가지 않습니다.', 'Info')
    } else {
        $ni.ShowBalloonTip(2500, '덮개 닫으면 절전', '기본 동작으로 돌아갔습니다.', 'Info')
    }
}

$miToggle.Add_Click({ Toggle-Lid })
$ni.Add_MouseClick({ if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) { Toggle-Lid } })
$miExit.Add_Click({
    $ni.Visible = $false
    $ni.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

# 전원 구성표가 밖에서 바뀌었을 때도 따라가도록 주기적으로 갱신
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000
$timer.Add_Tick({ Sync-Ui })
$timer.Start()

$ni.Visible = $true
Sync-Ui
[System.Windows.Forms.Application]::Run()
