# 网络测试管理工具使用说明

## 程序功能
本工具是一个基于 Bash 的网络测试管理工具，主要用于：
- 后台运行网络测试（ping 测试）
- 监控网络连接质量（丢包率、网络波动）
- 检测短时间内的重复数据包（来源、IP、端口、协议）
- 检测服务器TIME_WAIT进程并自动优化
- 提供友好的交互界面
- 生成详细的测试日志

## 安装步骤
1. 确保系统已安装 `bash` 和 `ping` 命令
2. 确保系统已安装 `bc`（用于浮点数比较）：
   ```bash
   sudo apt-get install bc  # Ubuntu/Debian
   ```
3. 确保系统已安装 `tcpdump`（用于数据包捕获）：
   ```bash
   sudo apt-get install tcpdump  # Ubuntu/Debian
   ```
4. 创建配置目录（需要管理员权限）：
   ```bash
   sudo mkdir -p /etc/networkTest/
   sudo chmod 755 /etc/networkTest/
   ```
5. 给脚本执行权限：
   ```bash
   chmod +x network_test_manager.sh
   chmod +x install_network_test.sh
   ```

## 使用方法

本工具提供两种使用方式：

### 方法一：直接运行脚本（推荐临时使用）
1. 给脚本执行权限：
   ```bash
   chmod +x network_test_manager.sh
   ```
2. 直接运行：
   ```bash
   ./network_test_manager.sh
   ```

### 方法二：安装后全局使用（推荐长期使用）
1. 运行安装脚本：
   ```bash
   chmod +x install_network_test.sh
   ./install_network_test.sh
   ```
2. 安装完成后，您可以在任何位置通过以下命令运行：
   ```bash
   network-test
   ```
3. 如果提示命令未找到，请确保 `~/.local/bin` 在您的 `PATH` 环境变量中

### 主菜单
```
===== 网络测试管理工具 =====
作者：赵炳翔
说明：仅限于测试，对脚本使用不当造成的服务器异常不负责

1. 网络检测（会在后台常ping目标IP）
2. 查看网络检测结果（结束后台常ping并分析波动情况）
3. 分析网络检测结果（根据延迟阈值查找异常记录）
4. 清理历史检测进程（结束所有后台常ping进程）
5. 检测重复数据包（短时间内来源、IP、端口、协议相同的包）
6. 检测TIME_WAIT进程（超过10条自动优化sysctl.conf）
7. 退出程序
```

### 1. 开始网络测试
选择菜单选项 `1`：
1. 输入对端网络 IP 地址
2. 输入数据包大小（字节，默认 56）
3. 测试将在后台运行，生成日志文件 `/etc/networkTest/log/<IP>.log`

### 2. 查看网络检测结果
选择菜单选项 `2`：
1. 查看正在运行的测试进程列表
2. 选择要结束的测试序号
3. 程序会自动：
   - 终止对应的 ping 进程
   - 等待 2 秒让日志完全写入
   - 显示最后 4 行日志内容
   - **自动分析日志并显示结果**：
     ```
     ===== 日志分析结果 =====
     ⚠️  检测到丢包：5%
     ⚠️ 网络有轻微波动，mdev = 2.345 ms
     =========================
     ```

### 3. 分析网络检测结果
选择菜单选项 `3`：
1. 选择要分析的IP地址序号
2. 输入延迟阈值（毫秒）
3. 程序会分析日志并显示延迟超过阈值的记录及其占比

### 4. 清理所有测试进程
选择菜单选项 `4`：
1. 确认清理所有网络测试进程
2. 程序会自动终止所有 ping 进程

### 5. 检测重复数据包
选择菜单选项 `5`：
1. 输入要检测的来源IP（不输入则检测所有来源）
2. 输入检测时间（默认10秒）
3. 输入重复阈值（默认5次）
4. 程序会使用tcpdump捕获数据包，统计来源、IP、端口、协议相同的重复数据包
5. 列出超过阈值的重复包关键信息

### 6. 检测TIME_WAIT进程
选择菜单选项 `6`（需要root权限）：
1. 程序会检测当前TIME_WAIT连接数
2. 如果超过10条，会提示优化
3. 确认后自动优化sysctl.conf参数：
   ```
   net.ipv4.tcp_syncookies = 1
   net.ipv4.tcp_tw_reuse = 1
   net.ipv4.tcp_tw_recycle = 1
   net.ipv4.tcp_max_tw_buckets = 0
   net.ipv4.neigh.default.gc_stale_time = 1000
   net.ipv4.neigh.default.gc_thresh1 = 1024
   net.ipv4.neigh.default.gc_thresh2 = 2028
   net.ipv4.neigh.default.gc_thresh3 = 10240
   ```
4. 自动备份原配置文件

## 输出结果说明

### 丢包率分析
- `⚠️  检测到丢包：X%`：表示检测到丢包，X 为丢包率百分比
- `✅ 无丢包`：表示没有检测到丢包

### 网络波动分析
- `🚨 网络有很严重的波动，mdev = X ms，请及时检查`：mdev > 50ms
- `⚠️ 网络有较严重波动，mdev = X ms`：20ms < mdev ≤ 50ms
- `⚠️ 网络有轻微波动，mdev = X ms`：1ms < mdev ≤ 20ms
- `✅ 网络稳定，mdev = X ms`：mdev ≤ 1ms

## 日志文件
测试日志会保存在 `/etc/networkTest/log/<IP>.log` 文件中，包含详细的测试记录。

## 注意事项
1. 请确保有足够的权限运行此脚本
2. 测试过程中不要手动终止 ping 进程，建议使用本工具提供的清理功能
3. 检测重复数据包功能需要安装 tcpdump
4. 检测TIME_WAIT进程功能需要root权限
5. sysctl.conf优化会自动备份原配置文件