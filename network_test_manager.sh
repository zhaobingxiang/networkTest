#!/bin/bash

# 脚本名称：network_test_manager.sh
# 功能：网络检测管理脚本
# 作者：赵炳翔
# 日期：2025-01-01
# 说明：本脚本仅做测试使用，不对因脚本使用不当造成的服务器等异常负责

# 颜色定义
RED='\033[0;31m'
GREEN='\033[1;32m' # 更亮的绿色
YELLOW='\033[1;33m'
ORANGE='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 配置目录和日志目录
CONFIG_DIR="/etc/networkTest"
LOG_DIR="$CONFIG_DIR/log"

# 初始化：创建必要的目录
init_directories() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
    fi
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
    fi
}

# 验证IP地址格式
validate_ip() {
    local ip="$1"
    if grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' <<< "$ip"; then
        local IFS="."
        local -a octets=($ip)
        for octet in "${octets[@]}"; do
            if (( octet < 0 || octet > 255 )); then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# 获取当前日期时间（用于日志文件名）
get_current_datetime() {
    date +"%Y%m%d%H%M"
}

# 获取当前时间（用于日志内容）
get_current_time() {
    date +"%y年%m月%d日%H:%M:%S"
}

# 功能1：网络检测
network_detection() {
    echo -e "${GREEN}=== 功能1：网络检测 ===${NC}"
    
    # 提示用户输入IP地址，直到输入正确
    while true; do
        read -p "请输入要检测的IP地址: " ip
        
        # 验证IP地址
        if validate_ip "$ip"; then
            break
        else
            echo -e "${RED}错误：无效的IP地址格式！请重新输入${NC}"
        fi
    done
    
    # 提示用户输入包大小（可选），直到输入正确
    while true; do
        read -p "请输入ping包大小(默认字节64，范围：1-65507): " packet_size
        
        # 验证包大小，如果为空则使用默认值64
        if [ -z "$packet_size" ]; then
            packet_size=56
            break
        elif grep -qE '^[0-9]+$' <<< "$packet_size" && [ "$packet_size" -ge 1 ] && [ "$packet_size" -le 65507 ]; then
            break
        else
            echo -e "${RED}错误：无效的包大小！包大小必须是1-65507之间的整数。请重新输入${NC}"
        fi
    done
    
    # 检查后台是否已有ping该IP的进程
    existing_pid=$(pgrep -f "ping.*$ip")
    if [ -n "$existing_pid" ]; then
        echo -e "${YELLOW}警告：已存在ping $ip的进程 (PID: $existing_pid)${NC}"
        read -p "是否继续？(y/n): " choice
        if [ "$choice" != "y" ] && [ "$choice" != "Y" ]; then
            echo -e "${RED}已取消操作${NC}"
            return 1
        fi
        
        # 结束旧进程
        echo -e "${YELLOW}正在结束旧进程...${NC}"
        kill -SIGINT "$existing_pid" 2>/dev/null
        sleep 1
        
        # 处理历史日志文件
        if [ -f "$LOG_DIR/$ip.log" ]; then
            old_log_name="$LOG_DIR/$ip.log.old.$(get_current_datetime)"
            mv "$LOG_DIR/$ip.log" "$old_log_name"
            echo -e "${GREEN}历史日志已备份为：$old_log_name${NC}"
        fi
    fi
    
    # 在后台启动ping进程
    echo -e "${YELLOW}正在启动后台ping进程...${NC}"
    nohup ping -s "$packet_size" "$ip" | awk '{print $0"\t"strftime("%y年%m月%d日%H:%M:%S",systime()); fflush()}' > "$LOG_DIR/$ip.log" 2>&1 &
    
    # 检查进程是否成功启动
    sleep 1
    new_pid=$(pgrep -f "ping.*$ip")
    if [ -n "$new_pid" ]; then
        echo -e "${GREEN}ping进程已成功启动 (PID: $new_pid)${NC}"
        echo -e "${GREEN}使用包大小：${packet_size}字节${NC}"
        echo -e "${GREEN}日志文件：$LOG_DIR/$ip.log${NC}"
    else
        echo -e "${RED}ping进程启动失败！${NC}"
        return 1
    fi
    

}

# 功能2：查看网络检测结果
view_detection_result() {
    echo -e "${GREEN}=== 功能2：查看网络检测结果 ===${NC}"
    
    # 列出所有后台运行的ping进程
    echo -e "${YELLOW}当前运行的ping进程：${NC}"
    running_ips=$(pgrep -f ping | xargs -I {} ps -p {} -o cmd --no-heading | awk '/ping/ {if ($2 == "-s") print $4; else print $2}')
    
    if [ -z "$running_ips" ]; then
        echo -e "${RED}没有正在运行的ping进程${NC}"
        return 1
    fi
    
    # 将运行的IP转换为数组
    IFS=$'\n' read -r -d '' -a ips_array <<< "$running_ips"
    
    # 显示序号和对应的IP地址
    for i in "${!ips_array[@]}"; do
        echo -e "${YELLOW}$((i+1)). ${ips_array[$i]}${NC}"
    done
    
    # 提示用户输入序号，直到输入正确
    while true; do
        read -p "请选择要查看的IP地址序号: " choice
        
        # 验证选择是否有效
        if grep -qE '^[0-9]+$' <<< "$choice" && [ "$choice" -ge 1 ] && [ "$choice" -le "${#ips_array[@]}" ]; then
            break
        else
            echo -e "${RED}错误：无效的序号选择！请重新输入${NC}"
        fi
    done
    
    # 获取对应的IP地址
    ip=${ips_array[$((choice-1))]}
    
    # 验证IP地址
    if ! validate_ip "$ip"; then
        echo -e "${RED}错误：无效的IP地址格式！${NC}"
        return 1
    fi
    
    # 检查是否有ping该IP的进程
    pid=$(pgrep -f "ping.*$ip")
    if [ -z "$pid" ]; then
        echo -e "${RED}错误：没有ping $ip的进程${NC}"
        return 1
    fi
    
    # 确认结束进程
    read -p "确定要结束ping $ip的进程并查看结果吗？(y/n): " choice
    if [ "$choice" != "y" ] && [ "$choice" != "Y" ]; then
        echo -e "${RED}已取消操作${NC}"
        return 1
    fi
    
    # 结束进程
    echo -e "${YELLOW}正在结束进程...${NC}"
    kill -SIGINT "$pid" 2>/dev/null
    sleep 1
    
    # 显示日志文件的最后四行
    if [ -f "$LOG_DIR/$ip.log" ]; then
        echo -e "${GREEN}Ping检测结果如下：${NC}"
        tail -n 4 "$LOG_DIR/$ip.log"
        
        # 分析最后两行
        log_content=$(tail -n 4 "$LOG_DIR/$ip.log")
        
        # 分析丢包率（倒数第二行）
        loss_line=$(echo "$log_content" | sed -n '3p')
        if grep -qE '[0-9]+%' <<< "$loss_line"; then
            loss_rate=$(echo "$loss_line" | grep -oE '[0-9]+%' | grep -oE '[0-9]+')
            if [ "$loss_rate" -eq 0 ]; then
                echo -e "${GREEN}丢包率：${loss_rate}% - 无丢包${NC}"
            else
                echo -e "${RED}丢包率：${loss_rate}% - 有丢包${NC}"
            fi
        fi
        
        # 分析延迟情况（倒数第一行）
        rtt_line=$(echo "$log_content" | sed -n '4p')
        
        # 提取延迟数据（使用grep和cut，避免正则表达式语法问题）
        delay_data=$(echo "$rtt_line" | grep -oE '[0-9.]+/[0-9.]+/[0-9.]+/[0-9.]+')
        if [ -n "$delay_data" ]; then
            min_rtt=$(echo "$delay_data" | cut -d'/' -f1)
            avg_rtt=$(echo "$delay_data" | cut -d'/' -f2)
            max_rtt=$(echo "$delay_data" | cut -d'/' -f3)
            mdev_rtt=$(echo "$delay_data" | cut -d'/' -f4)
            
            echo -e "${GREEN}延迟分析：${NC}"
            echo -e "  最小延迟：${min_rtt} ms"
            echo -e "  平均延迟：${avg_rtt} ms"
            echo -e "  最大延迟：${max_rtt} ms"
            echo -e "  波动情况：${mdev_rtt} ms"
            
            # 判断波动情况
            mdev_float=$(printf "%.2f" "$mdev_rtt")
            if (( $(echo "$mdev_float < 1" | bc -l) )); then
                echo -e "${GREEN}  网络稳定${NC}"
            elif (( $(echo "$mdev_float >= 1 && $mdev_float < 20" | bc -l) )); then
                echo -e "${YELLOW}  网络有异常波动${NC}"
            elif (( $(echo "$mdev_float >= 20 && $mdev_float < 50" | bc -l) )); then
                echo -e "${ORANGE}  网络波动较大${NC}"
            else
                echo -e "${RED}  网络波动严重${NC}"
            fi
        fi
    else
        echo -e "${RED}错误：找不到日志文件 $LOG_DIR/$ip.log${NC}"
        return 1
    fi
}

# 功能3：分析网络检测结果
analyze_detection_result() {
    echo -e "${GREEN}=== 功能3：分析网络检测结果 ===${NC}"
    
    # 列出所有可用的日志文件IP
    echo -e "${YELLOW}可用的日志文件IP：${NC}"
    log_files=$(find "$LOG_DIR" -name "*.log" | sort)
    
    if [ -z "$log_files" ]; then
        echo -e "${RED}没有找到日志文件${NC}"
        return 1
    fi
    
    # 提取日志文件名中的IP地址
    ips_array=()
    for file in $log_files; do
        ip=$(basename "$file" .log)
        if validate_ip "$ip"; then
            ips_array+=($ip)
        fi
    done
    
    if [ ${#ips_array[@]} -eq 0 ]; then
        echo -e "${RED}没有有效的日志文件IP${NC}"
        return 1
    fi
    
    # 显示序号和对应的IP地址
    for i in "${!ips_array[@]}"; do
        echo -e "${YELLOW}$((i+1)). ${ips_array[$i]}${NC}"
    done
    
    # 提示用户输入序号，直到输入正确
    while true; do
        read -p "请选择要分析的IP地址序号: " choice
        
        # 验证选择是否有效
        if grep -qE '^[0-9]+$' <<< "$choice" && [ "$choice" -ge 1 ] && [ "$choice" -le "${#ips_array[@]}" ]; then
            # 获取对应的IP地址
            ip=${ips_array[$((choice-1))]}
            # 设置日志文件路径
            log_file="$LOG_DIR/$ip.log"
            break
        else
            echo -e "${RED}错误：无效的序号选择！请重新输入${NC}"
        fi
    done
    
    # 提示用户输入延迟阈值，直到输入正确
    while true; do
        read -p "请输入延迟阈值（毫秒）: " threshold
        if grep -qE '^[0-9]+(\.[0-9]+)?$' <<< "$threshold"; then
            break
        else
            echo -e "${RED}错误：无效的阈值格式！请重新输入${NC}"
        fi
    done
    
    # 分析日志文件（除最后四行外）
    total_lines=$(wc -l < "$log_file")
    if [ "$total_lines" -le 4 ]; then
        echo -e "${YELLOW}警告：日志文件内容不足，无法进行分析${NC}"
        return 1
    fi
    
    analyze_lines=$((total_lines - 4))
    
    # 检索延迟大于阈值的行（使用正确的数字比较）
    high_latency_lines=$(head -n "$analyze_lines" "$log_file" | grep -E "时间=|time=" | awk -v threshold="$threshold" '{
        found=0;
        # 提取中文格式的延迟值
        if ($0 ~ /时间=([0-9.]+)/) {
            latency_val=$0;
            gsub(/.*时间=/, "", latency_val);
            gsub(/毫秒.*/, "", latency_val);
            found=1;
        # 提取英文格式的延迟值
        } else if ($0 ~ /time=([0-9.]+)/) {
            latency_val=$0;
            gsub(/.*time=/, "", latency_val);
            gsub(/ms.*/, "", latency_val);
            found=1;
        }
        # 使用 bc 进行精确的数字比较
        if (found && latency_val+0 > threshold+0) {
            print $0;
        }
    }')
    
    # 统计数量和占比
    high_latency_count=$(echo "$high_latency_lines" | wc -l)
    if [ "$high_latency_count" -eq 0 ]; then
        echo -e "${GREEN}未发现延迟大于 $threshold 毫秒的记录${NC}"
        return 0
    fi
    
    percentage=$(echo "scale=2; $high_latency_count / $analyze_lines * 100" | bc)
    
    # 获取最后一条记录的时间
    last_time=$(echo "$high_latency_lines" | tail -n 1 | awk '{print $NF}')
    
    # 显示结果
    echo -e "${GREEN}分析结果：${NC}"
    echo -e "  总分析记录数：${analyze_lines}"
    echo -e "  延迟超过 $threshold 毫秒的记录数：${high_latency_count}"
    echo -e "  占比：${percentage}%"
    
    # 显示所有超过阈值的记录
    echo -e "${GREEN}超过阈值的所有记录：${NC}"
    echo "$high_latency_lines"
}

# 功能4：清理历史检测进程
cleanup_processes() {
    echo -e "${GREEN}=== 功能4：清理历史检测进程 ===${NC}"
    
    # 列出所有后台运行的ping进程
    running_pids=$(pgrep -f ping)
    if [ -z "$running_pids" ]; then
        echo -e "${GREEN}没有需要清理的进程${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}以下ping进程将被结束：${NC}"
    for pid in $running_pids; do
        cmd=$(ps -p "$pid" -o cmd --no-heading)
        echo -e "  PID: $pid - $cmd"
    done
    
    # 确认清理
    read -p "确定要结束所有ping进程吗？(y/n): " choice
    if [ "$choice" != "y" ] && [ "$choice" != "Y" ]; then
        echo -e "${RED}已取消操作${NC}"
        return 1
    fi
    
    # 结束所有进程
    echo -e "${YELLOW}正在结束所有ping进程...${NC}"
    for pid in $running_pids; do
        kill -SIGINT "$pid" 2>/dev/null
    done
    
    sleep 1
    
    # 检查是否还有剩余进程
    remaining_pids=$(pgrep -f ping)
    if [ -n "$remaining_pids" ]; then
        echo -e "${YELLOW}部分进程无法正常结束，正在强制结束...${NC}"
        for pid in $remaining_pids; do
            kill -SIGKILL "$pid" 2>/dev/null
        done
    fi
    
    echo -e "${GREEN}所有ping进程已清理完毕${NC}"
    

}

# 显示主菜单
display_menu() {
    echo -e "${PURPLE}=====================================${NC}"
    echo -e "${GREEN}         网络检测管理系统         ${NC}"
    echo -e "${PURPLE}=====================================${NC}"
    echo -e "${YELLOW}1. 网络检测（会在后台常ping目标IP）${NC}"
    echo -e "${YELLOW}2. 查看网络检测结果（结束后台常ping并分析波动情况）${NC}"
    echo -e "${YELLOW}3. 分析网络检测结果（根据延迟阈值查找异常记录）${NC}"
    echo -e "${YELLOW}4. 清理历史检测进程（结束所有后台常ping进程）${NC}"
    echo -e "${YELLOW}5. 退出程序（配置好后台常ping后请按5结束哦）${NC}"
    echo -e "${PURPLE}=====================================${NC}"
    echo -e "${ORANGE}使用遇到问题请联系赵炳翔${NC}"
    echo -e "${ORANGE}说明：本工具适用于需要长期监测网络的情况，如在半夜或者偶尔掉线的设备，你不用再半夜或者盯着电脑屏幕去测试网络了，让我在后台帮你看着，你醒来我告诉你结果${NC}"
}

# 主函数
main() {
    # 初始化目录
    init_directories
    
    while true; do
        display_menu
        
        # 读取用户选择
        read -p "请输入功能编号 (1-5): " choice
        
        case "$choice" in
            1)
                network_detection
                ;;
            2)
                view_detection_result
                ;;
            3)
                analyze_detection_result
                ;;
            4)
                cleanup_processes
                ;;
            5)
                echo -e "${GREEN}感谢使用网络检测管理系统，再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}错误：无效的功能编号！请输入1-5之间的数字${NC}"
                ;;
        esac
        
        echo -e "${PURPLE}=====================================${NC}"
        read -p "按回车键返回主菜单..." -n 1 -r
        echo
    done
}

# 执行主函数
main