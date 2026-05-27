# Network Test Management Tool User Guide

## Features

This is a Bash-based network test management tool designed for:

- Running network tests (ping tests) in the background
- Monitoring network connection quality (packet loss, network fluctuation)
- Providing a user-friendly interactive interface
- Generating detailed test logs

## Installation Steps

1. Ensure `bash` and `ping` commands are installed on your system
2. Ensure `bc` is installed (required for floating-point comparison):
   ```bash
   sudo apt-get install bc  # Ubuntu/Debian
   ```
3. Create configuration directory (requires admin privileges):
   ```bash
   sudo mkdir -p /etc/networkTest/
   sudo chmod 755 /etc/networkTest/
   ```
4. Grant execute permissions to scripts:
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

1. Start background network test (configurable packet size)
2. Stop process and display results
3. Clean up all network test processes
4. Exit
```

### 3. Start Network Test

Select menu option `1`:

1. Enter the target network IP address
2. Enter packet size (bytes, default 32)
3. The test will run in the background, generating log file `<IP>.log`

### 4. Stop Test and View Results

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

### 5. Clean Up All Test Processes

Select menu option `3`:

1. Confirm to clean up all network test processes
2. The program will automatically terminate all ping processes

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

Test logs are saved in `<IP>.log` file, containing detailed test records.

## Notes

1. Ensure you have sufficient permissions to run this script
2. Do not manually terminate ping processes during testing. Use the cleanup function provided by this tool
3. Log files are saved in the current directory

