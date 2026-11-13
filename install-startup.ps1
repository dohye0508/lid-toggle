# 시작프로그램 등록 / 해제
# 그냥 실행하면 등록, -Remove 를 붙이면 해제

param([switch]$Remove)

$dir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$startup = [Environment]::GetFolderPath('Startup')
$link    = Join-Path $startup '덮개 닫기 토글.lnk'

if ($Remove) {
    if (Test-Path $link) {
        Remove-Item $link -Force
        Write-Host '시작프로그램에서 제거했습니다.'
    } else {
        Write-Host '등록되어 있지 않습니다.'
    }
} else {
    $w = New-Object -ComObject WScript.Shell
    $s = $w.CreateShortcut($link)
    $s.TargetPath       = "$env:WINDIR\System32\wscript.exe"
    $s.Arguments        = "`"$dir\run-lid-tray.vbs`""
    $s.WorkingDirectory = $dir
    $s.Description      = '노트북 덮개 닫기 동작 트레이 아이콘'
    $s.Save()
    Write-Host "등록했습니다: $link"
}
