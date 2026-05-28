# Network Test Management Tool User Guide

## Features
This is a Bash-based network test management tool designed for:
- Running network tests (ping tests) in the background
- Monitoring network connection quality (packet loss, network fluctuation)
- Detecting duplicate packets within a short period (source IP, destination IP, port, protocol)
- Detecting TIME_WAIT processes on server and automatic optimization
- Providing a user-friendly interactive interface
- Generating detailed test logs

## Installation Steps
1. Ensure `bash` and `ping` commands are installed on your system
2. Ensure `bc` is installed (required for floating-point comparison):
   ```bash
   sudo apt-get install bc  # Ubuntu/Debian
   ```
3. Ensure `tcpdump` is installed (required for packet capture):
   ```bash
   sudo apt-get install tcpdump  # Ubuntu/Debian
   ```
4. Create configuration directory (requires admin privileges):
   ```bash
   sudo mkdir -p /etc/networkTest/
   sudo chmod 755 /etc/networkTest/
   ```
5. Grant execute permissions to scripts:
   ```bash
   chmod +x network_test_manager.sh
   chmod +x install_network_test.sh
   ```

## Usage

This tool provides two ways to use:

### Method 1: Run Script Directly (Recommended for temporary use)
1. Grant execute permission:
   ```bash
   chmod +x network_test_manager.sh
   ```
2. Run directly:
   ```bash
   ./network_test_manager.sh
   ```

### Method 2: Install for Global Use (Recommended for long-term use)
1. Run the installation script:
   ```bash
   chmod +x install_network_test.sh
   ./install_network_test.sh
   ```
2. After installation, you can run the tool from anywhere using:
   ```bash
   network-test
   ```
3. If command not found, ensure `~/.local/bin` is in your `PATH` environment variable

### Main Menu
```
===== Network Test Management Tool =====
Author: Zhao Bingxiang
Note: For testing purposes only. Not responsible for server issues caused by improper use.

1. Network detection (ping target IP in background)
2. View detection results (stop background ping and analyze fluctuation)
3. Analyze detection results (find abnormal records by latency threshold)
4. Cleanup history processes (stop all background ping processes)
5. Detect duplicate packets (same source, IP, port, protocol in short time)
6. Detect TIME_WAIT processes (optimize sysctl.conf if over 10)
7. Exit
```

### 1. Start Network Test
Select menu option `1`:
1. Enter the target network IP address
2. Enter packet size (bytes, default 56)
3. The test will run in the background, generating log file `/etc/networkTest/log/<IP>.log`

### 2. View Detection Results
Select menu option `2`:
1. View the list of running test processes
2. Select the test number to stop
3. The program will automatically:
   - Terminate the corresponding ping process
   - Wait 2 seconds for log to be fully written
   - Display the last 4 lines of log content
   - **Automatically analyze logs and display results**:
     ```
     ===== Log Analysis Results =====
     ⚠️  Packet loss detected: 5%
     ⚠️  Minor network fluctuation detected, mdev = 2.345 ms
     =========================
     ```

### 3. Analyze Detection Results
Select menu option `3`:
1. Select the IP address number to analyze
2. Enter latency threshold (milliseconds)
3. The program will analyze logs and display records exceeding the threshold

### 4. Clean Up All Test Processes
Select menu option `4`:
1. Confirm to clean up all network test processes
2. The program will automatically terminate all ping processes

### 5. Detect Duplicate Packets
Select menu option `5`:
1. Enter source IP to detect (leave empty for all sources)
2. Enter detection time (default 10 seconds)
3. Enter duplicate threshold (default 5 times)
4. The program uses tcpdump to capture packets and count duplicates with same source, IP, port, and protocol
5. Lists key information of packets exceeding the threshold

### 6. Detect TIME_WAIT Processes
Select menu option `6` (requires root privileges):
1. The program detects current TIME_WAIT connection count
2. If over 10 connections, prompts for optimization
3. After confirmation, automatically optimizes sysctl.conf parameters:
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
4. Automatically backs up the original configuration file

## Output Explanation

### Packet Loss Analysis
- `⚠️  Packet loss detected: X%`: Indicates packet loss detected, X is the percentage
- `✅ No packet loss`: Indicates no packet loss detected

### Network Fluctuation Analysis
- `🚨 Severe network fluctuation detected, mdev = X ms, please check immediately`: mdev > 50ms
- `⚠️ Moderate network fluctuation detected, mdev = X ms`: 20ms < mdev ≤ 50ms
- `⚠️ Minor network fluctuation detected, mdev = X ms`: 1ms < mdev ≤ 20ms
- `✅ Network stable, mdev = X ms`: mdev ≤ 1ms

## Log Files
Test logs are saved in `/etc/networkTest/log/<IP>.log` file, containing detailed test records.

## Notes
1. Ensure you have sufficient permissions to run this script
2. Do not manually terminate ping processes during testing. Use the cleanup function provided by this tool
3. Duplicate packet detection requires tcpdump to be installed
4. TIME_WAIT detection requires root privileges
5. sysctl.conf optimization automatically backs up the original configuration file