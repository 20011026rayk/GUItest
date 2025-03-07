# 设置网络接口名称，根据实际情况修改
$interfaceName = "以太网"

# 定义目标测试网站，用于测试网络响应时间
$exePath = 'C:\workfiles\ACC\software\V3.5_beta_20250116\demo.exe'

# 记录初始 IP 配置
$initialIpConfig = Get-NetIPAddress -InterfaceAlias $interfaceName -AddressFamily IPv4
$initialDefaultGateway = Get-NetRoute -InterfaceAlias $interfaceName -DestinationPrefix 0.0.0.0/0
$initialDnsServers = Get-DnsClientServerAddress -InterfaceAlias $interfaceName -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses

# 获取系统资源占用情况
# CPU 使用率
$cpuCounter = New-Object System.Diagnostics.PerformanceCounter("Processor", "% Processor Time", "_Total")
$cpuUsageBefore = $cpuCounter.NextValue()
Start-Sleep -Seconds 1
$cpuUsageBefore = $cpuCounter.NextValue()

# 内存使用率
$memoryCounter = Get-Counter -Counter "\Memory\% Committed Bytes In Use"
$memoryUsageBefore = $memoryCounter.CounterSamples.CookedValue

# 测试网络平均响应时间
$pingResults = ping -n 5 $exePath
$averageResponseTimeBefore = ($pingResults | Where-Object { $_ -match "Average = (\d+)ms" } | ForEach-Object { [int]($matches[1]) } | Measure-Object -Average).Average

# 输出资源占用和响应时间信息
Write-Host "修改 IP 前的资源占用和网络响应情况："
Write-Host "CPU 使用率: $($cpuUsageBefore)%"
Write-Host "内存使用率: $($memoryUsageBefore)%"
Write-Host "对 $exePath 的平均响应时间: $($averageResponseTimeBefore) 毫秒"

# 定义待修改的 IP 列表，可根据需要添加更多配置
$ipConfigurations = @(
    @{
        IPAddress = "192.168.1.100"
        SubnetMask = "255.255.255.0"
        DefaultGateway = "192.168.1.1"
        DnsServers = "8.8.8.8", "8.8.4.4"
    },
    @{
        IPAddress = "192.168.1.101"
        SubnetMask = "255.255.255.0"
        DefaultGateway = "192.168.1.1"
        DnsServers = "8.8.8.8", "8.8.4.4"
    },
    @{
        IPAddress = "192.168.1.102"
        SubnetMask = "255.255.255.0"
        DefaultGateway = "192.168.1.1"
        DnsServers = "8.8.8.8", "8.8.4.4"
    },
    @{
        IPAddress = "192.168.1.103"
        SubnetMask = "255.255.255.0"
        DefaultGateway = "192.168.1.1"
        DnsServers = "8.8.8.8", "8.8.4.4"
    },
    @{
        IPAddress = "192.168.1.104"
        SubnetMask = "255.255.255.0"
        DefaultGateway = "192.168.1.1"
        DnsServers = "8.8.8.8", "8.8.4.4"
    }
)

# 循环修改 IP 地址
foreach ($config in $ipConfigurations) {
    # 删除现有的 IP 地址和网关
    Remove-NetIPAddress -InterfaceAlias $interfaceName -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceAlias $interfaceName -DestinationPrefix 0.0.0.0/0 -Confirm:$false -ErrorAction SilentlyContinue

    # 设置新的 IP 地址和子网掩码
    New-NetIPAddress -InterfaceAlias $interfaceName -IPAddress $config.IPAddress -PrefixLength ($config.SubnetMask -split '\.' | ForEach-Object { [Convert]::ToString($_, 2) -replace '0', '' } | Measure-Object -Sum).Sum

    # 设置新的默认网关
    New-NetRoute -InterfaceAlias $interfaceName -DestinationPrefix 0.0.0.0/0 -NextHop $config.DefaultGateway

    # 设置新的 DNS 服务器
    Set-DnsClientServerAddress -InterfaceAlias $interfaceName -ServerAddresses $config.DnsServers

    Write-Host "已将 IP 地址修改为 $($config.IPAddress)"
    Start-Sleep -Seconds 20
}

# 恢复初始 IP 配置
# 删除现有的 IP 地址和网关
Remove-NetIPAddress -InterfaceAlias $interfaceName -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceAlias $interfaceName -DestinationPrefix 0.0.0.0/0 -Confirm:$false -ErrorAction SilentlyContinue

# 设置初始 IP 地址和子网掩码
New-NetIPAddress -InterfaceAlias $interfaceName -IPAddress $initialIpConfig.IPAddress -PrefixLength $initialIpConfig.PrefixLength

# 设置初始默认网关
if ($initialDefaultGateway) {
    New-NetRoute -InterfaceAlias $interfaceName -DestinationPrefix 0.0.0.0/0 -NextHop $initialDefaultGateway.NextHop
}

# 设置初始 DNS 服务器
Set-DnsClientServerAddress -InterfaceAlias $interfaceName -ServerAddresses $initialDnsServers

Write-Host "已将 IP 地址恢复为初始配置"

# 获取修改 IP 后的系统资源占用情况
$cpuUsageAfter = $cpuCounter.NextValue()
Start-Sleep -Seconds 1
$cpuUsageAfter = $cpuCounter.NextValue()

$memoryUsageAfter = (Get-Counter -Counter "\Memory\% Committed Bytes In Use").CounterSamples.CookedValue

$bytesSentInitial = $networkCounterSent.NextValue()
$bytesReceivedInitial = $networkCounterReceived.NextValue()
Start-Sleep -Seconds 1
$bytesSentFinal = $networkCounterSent.NextValue()
$bytesReceivedFinal = $networkCounterReceived.NextValue()
$networkSendRateAfter = $bytesSentFinal
$networkReceiveRateAfter = $bytesReceivedFinal

$pingResults = ping -n 5 $exePath
$averageResponseTimeAfter = ($pingResults | Where-Object { $_ -match "Average = (\d+)ms" } | ForEach-Object { [int]($matches[1]) } | Measure-Object -Average).Average

# 输出修改 IP 后的资源占用和响应时间信息
Write-Host "修改 IP 后的资源占用和网络响应情况："
Write-Host "CPU 使用率: $($cpuUsageAfter)%"
Write-Host "内存使用率: $($memoryUsageAfter)%"
Write-Host "网络发送速率: $($networkSendRateAfter) 字节/秒"
Write-Host "网络接收速率: $($networkReceiveRateAfter) 字节/秒"
Write-Host "对 $exePath 的平均响应时间: $($averageResponseTimeAfter) 毫秒"

# 生成报告并保存到文件
$reportFilePath = ".\IPChangeReport.txt"
$reportContent = @"
IP 修改操作报告

修改 IP 前的资源占用和网络响应情况：
CPU 使用率: $($cpuUsageBefore) %
内存使用率: $($memoryUsageBefore) %
网络发送速率: $($networkSendRateBefore) 字节/秒
网络接收速率: $($networkReceiveRateBefore) 字节/秒
对 $exePath 的平均响应时间: $($averageResponseTimeBefore) 毫秒

修改 IP 后的资源占用和网络响应情况：
CPU 使用率: $($cpuUsageAfter) %
内存使用率: $($memoryUsageAfter) %
网络发送速率: $($networkSendRateAfter) 字节/秒
网络接收速率: $($networkReceiveRateAfter) 字节/秒
对 $exePath 的平均响应时间: $($averageResponseTimeAfter) 毫秒
"@

$reportContent | Out-File -FilePath $reportFilePath -Encoding UTF8

Write-Host "报告已保存到 $reportFilePath"