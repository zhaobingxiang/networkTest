#!/bin/bash

# 网络测试工具安装脚本
# 作者：赵炳翔

# 检查是否有sudo权限
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：需要管理员权限才能执行安装"
    echo "请使用 sudo $0 命令运行"
    exit 1
fi

# 检查是否有network_test_manager.sh文件
if [ ! -f "network_test_manager.sh" ]; then
    echo "错误：network_test_manager.sh文件不存在"
    echo "请确保在脚本所在目录运行此安装程序"
    exit 1
fi

# 检查目标文件是否已存在
TARGET_FILE="/bin/networkTest"
if [ -f "$TARGET_FILE" ]; then
    echo "警告：$TARGET_FILE 已存在"
    read -p "是否覆盖现有文件？(y/n): " confirm
    if [ "$confirm" != "y" ]; then
        echo "安装已取消"
        exit 0
    fi
fi

# 赋予777权限
echo "正在设置文件权限..."
chmod 777 network_test_manager.sh

# 复制到/bin目录并重命名为networkTest
echo "正在安装网络测试工具..."
cp network_test_manager.sh "$TARGET_FILE"

# 检查安装是否成功
if [ $? -eq 0 ]; then
    echo "安装成功！"
    echo "现在您可以通过输入 'networkTest' 命令来使用网络测试工具"
    echo "使用方法：networkTest"
else
    echo "安装失败，请检查错误信息"
    exit 1
fi

echo "安装完成！"