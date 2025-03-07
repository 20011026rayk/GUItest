# 修改进程检测部分
Write-Host "正在等待demo.exe进程启动..."

# 持续监控直到找到demo.exe进程
while ($true) {
    $demoProcess = Get-Process | Where-Object { $_.ProcessName -eq "demo" }
    if ($demoProcess) {
        Write-Host "检测到demo.exe进程" -ForegroundColor Green
        break
    }
    Write-Host "等待demo.exe进程启动..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
}

# 获取所有窗口标题包含"加速度传感器采集"的进程
$processes = Get-Process | Where-Object { 
    $_.MainWindowTitle -like "*加速度传感器采集*" 
}

if ($processes.Count -eq 0) {
    Write-Host "未找到加速度传感器采集应用程序" -ForegroundColor Red
    exit
}

$process = $processes[0]
$processName = $process.ProcessName
$targetPID = $process.Id
$cores = (Get-WmiObject Win32_ComputerSystem).NumberOfLogicalProcessors

Write-Host "已检测到应用: $($process.MainWindowTitle) (PID: $targetPID)" -ForegroundColor Green

$cpuData = @()
$memData = @()

try {
    while ($true) {
        $currentProcess = Get-Process -Id $targetPID -ErrorAction SilentlyContinue
        if (-not $currentProcess) {
            Write-Host "`n目标进程已终止，停止监控..."
            break
        }

        # 通过性能计数器获取精确CPU数据
        $cpuUsage = (Get-Counter "\Process($($processName))\% Processor Time" -ErrorAction SilentlyContinue).CounterSamples.CookedValue
        $cpuPercent = [math]::Round($cpuUsage/$cores, 2)

        # 获取内存数据（MB）
        $memUsage = [math]::Round($currentProcess.WorkingSet64/1MB, 2)

        $cpuData += $cpuPercent
        $memData += $memUsage

        Write-Host "当前 CPU: ${cpuPercent}% | 内存: ${memUsage}MB" -ForegroundColor Cyan
        Start-Sleep -Seconds 10  # 采样时间间隔10秒
    }
}
finally
{
    if ($cpuData.Count -gt 0)
    {
        $avgCPU = [math]::Round(($cpuData | Measure-Object -Average).Average, 2)
        $avgMem = [math]::Round(($memData | Measure-Object -Average).Average, 2)
        $maxCPU = [math]::Round(($cpuData | Measure-Object -Maximum).Maximum, 2)
        $maxMem = [math]::Round(($memData | Measure-Object -Maximum).Maximum, 2)

        # 控制台输出
        Write-Host "`n===== 监控报告 =====" -ForegroundColor Green
        Write-Host "监控时长  : $( $cpuData.Count ) 秒"
        Write-Host "平均CPU   : ${avgCPU}%"
        Write-Host "平均内存  : ${avgMem}MB"
        Write-Host "峰值CPU   : ${maxCPU}%"
        Write-Host "峰值内存  : ${maxMem}MB"

        # 创建报告保存目录
        $reportPath = "c:\wortools\auto_GT\reports"
        if (-not (Test-Path $reportPath)) {
            New-Item -ItemType Directory -Path $reportPath | Out-Null
        }

        # 生成报告文件名（使用时间戳）
        $timestamp = Get-Date -Format "yyyyMMdd"
        $appName = $process.MainWindowTitle -replace '[\\/:*?"<>|]', '_'  # 移除文件名中的非法字符
        $reportFile = Join-Path $reportPath "${appName}_${timestamp}_report.txt"

        # 保存报告到文件
        @"
===== 进程监控报告 =====
进程名称  : $processName
监控时间  : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
监控时长  : $($cpuData.Count) 秒
平均CPU   : ${avgCPU}%
平均内存  : ${avgMem}MB
峰值CPU   : ${maxCPU}%
峰值内存  : ${maxMem}MB
"@ | Out-File -FilePath $reportFile -Encoding UTF8

        Write-Host "`n报告已保存至: $reportFile" -ForegroundColor Green
    }
}

