#!/bin/bash

###############################################################################
# Visdom 服务器启动脚本
# 
# 用途：快速启动 Visdom 服务器
# 使用：bash experiments/start_visdom.sh [端口号]
# 默认端口：8098
###############################################################################

# 默认端口
DEFAULT_PORT=8098
PORT=${1:-$DEFAULT_PORT}

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                 启动 Visdom 服务器                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# 检查 Visdom 是否安装
if ! python -c "import visdom" 2>/dev/null; then
    echo "❌ 错误: Visdom 未安装"
    echo ""
    echo "请先安装 Visdom:"
    echo "  pip install visdom"
    echo ""
    exit 1
fi

# 检查端口是否被占用
if netstat -tuln 2>/dev/null | grep ":${PORT} " > /dev/null 2>&1 || \
   ss -tuln 2>/dev/null | grep ":${PORT} " > /dev/null 2>&1; then
    echo "⚠️  警告: 端口 ${PORT} 已被占用"
    echo ""
    
    # 尝试找到 Visdom 进程
    if ps aux | grep "[p]ython -m visdom.server" > /dev/null 2>&1; then
        PID=$(ps aux | grep "[p]ython -m visdom.server" | awk '{print $2}')
        echo "检测到已有 Visdom 服务器正在运行 (PID: ${PID})"
        echo ""
        read -p "是否杀死现有进程并重启? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "正在停止现有 Visdom 服务器..."
            kill -9 $PID 2>/dev/null
            sleep 2
        else
            echo "取消启动。"
            exit 0
        fi
    else
        echo "端口被其他进程占用，请使用其他端口："
        echo "  bash experiments/start_visdom.sh 8098"
        echo ""
        exit 1
    fi
fi

echo "正在启动 Visdom 服务器..."
echo "  端口: ${PORT}"
echo "  访问地址: http://localhost:${PORT}"
echo ""

# 询问启动方式
echo "请选择启动方式:"
echo "  1) screen (推荐，可以后台运行并随时查看)"
echo "  2) nohup (后台运行，日志写入文件)"
echo "  3) 前台运行 (终端关闭则服务器停止)"
echo ""
read -p "请输入选项 (1/2/3) [默认:1]: " -n 1 -r
echo ""
CHOICE=${REPLY:-1}

case $CHOICE in
    1)
        # 使用 screen
        if ! command -v screen &> /dev/null; then
            echo "❌ 错误: screen 未安装"
            echo "请安装 screen: sudo apt-get install screen"
            exit 1
        fi
        
        echo "使用 screen 启动..."
        screen -dmS visdom bash -c "python -m visdom.server -port ${PORT}"
        sleep 2
        
        if ps aux | grep "[p]ython -m visdom.server" > /dev/null 2>&1; then
            PID=$(ps aux | grep "[p]ython -m visdom.server" | awk '{print $2}')
            echo ""
            echo "✅ Visdom 服务器已启动成功！"
            echo ""
            echo "   PID: ${PID}"
            echo "   访问地址: http://localhost:${PORT}"
            echo ""
            echo "常用命令:"
            echo "  • 查看服务器输出: screen -r visdom"
            echo "  • 退出 screen 但保持运行: Ctrl+A, 然后按 D"
            echo "  • 停止服务器: screen -X -S visdom quit"
            echo ""
        else
            echo "❌ 启动失败，请检查错误信息"
        fi
        ;;
    
    2)
        # 使用 nohup
        echo "使用 nohup 启动..."
        nohup python -m visdom.server -port ${PORT} > visdom.log 2>&1 &
        sleep 2
        
        if ps aux | grep "[p]ython -m visdom.server" > /dev/null 2>&1; then
            PID=$(ps aux | grep "[p]ython -m visdom.server" | awk '{print $2}')
            echo ""
            echo "✅ Visdom 服务器已启动成功！"
            echo ""
            echo "   PID: ${PID}"
            echo "   访问地址: http://localhost:${PORT}"
            echo "   日志文件: $(pwd)/visdom.log"
            echo ""
            echo "常用命令:"
            echo "  • 查看日志: tail -f visdom.log"
            echo "  • 停止服务器: kill ${PID}"
            echo ""
        else
            echo "❌ 启动失败，请查看日志: cat visdom.log"
        fi
        ;;
    
    3)
        # 前台运行
        echo "前台运行 Visdom 服务器..."
        echo "提示: 按 Ctrl+C 停止服务器"
        echo ""
        python -m visdom.server -port ${PORT}
        ;;
    
    *)
        echo "❌ 无效的选项"
        exit 1
        ;;
esac

echo "════════════════════════════════════════════════════════════════"
echo ""
echo "下一步："
echo "  1. 在本地电脑配置 SSH 端口转发:"
echo "     ssh -L ${PORT}:localhost:${PORT} 用户名@服务器地址"
echo ""
echo "  2. 在本地浏览器访问:"
echo "     http://localhost:${PORT}"
echo ""
echo "  3. 启动训练，确保脚本中有:"
echo "     --use_visdom \\"
echo "     --visdom_port ${PORT} \\"
echo ""

