# 设置错误日志路径
$logPath = "c:\wortools\auto_GT\logs"
$logFile = Join-Path $logPath "sikuli_error.log"

# 创建日志目录（如果不存在）
if (-not (Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath | Out-Null
}

function Write-ErrorLog {
    param(
        [string]$errorMessage
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $errorMessage"
    
    Add-Content -Path $logFile -Value $logEntry
    Write-Host "Error: $errorMessage" -ForegroundColor Red
}

# 监控系统事件日志中的错误
function Monitor-SystemErrors {
    $startTime = Get-Date
    
    while ($true) {
        try {
            # 获取最近的应用程序错误事件
            $events = Get-WinEvent -FilterHashtable @{
                LogName = 'Application'
                Level = 2  # Error级别
                StartTime = $startTime
            } -ErrorAction SilentlyContinue

            foreach ($event in $events) {
                if ($event.Message -match "Sikuli|Java|IDE") {
                    Write-ErrorLog "System Event: $($event.Message)"
                }
            }

            # 检查Java进程
            $javaProcess = Get-Process | Where-Object { $_.ProcessName -like "*java*" }
            if (-not $javaProcess) {
                Write-ErrorLog "SikuliX IDE process not found or terminated"
                break
            }

            Start-Sleep -Seconds 5
        }
        catch {
            Write-ErrorLog "Monitoring Error: $($_.Exception.Message)"
        }
    }
}

# 开始监控
try {
    Write-Host "Starting SikuliX monitoring..." -ForegroundColor Green
    Monitor-SystemErrors
}
catch {
    Write-ErrorLog "Fatal Error: $($_.Exception.Message)"
}