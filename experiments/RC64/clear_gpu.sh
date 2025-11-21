#!/bin/bash

# GPU内存清理脚本
# 用于清理残留的GPU进程，释放GPU内存

echo "╔══════════════════════════════════════════════════════════╗"
echo "║               GPU内存清理工具                            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# 显示清理前的GPU状态
echo "清理前的GPU状态："
nvidia-smi
echo ""

# 获取占用GPU的进程PID
PIDS=$(nvidia-smi --query-compute-apps=pid --format=csv,noheader 2>/dev/null)

if [ -z "$PIDS" ]; then
    echo "✓ 没有发现占用GPU的进程"
else
    echo "发现以下进程占用GPU："
    echo "$PIDS"
    echo ""
    echo "正在清理..."
    
    # 杀死所有占用GPU的进程
    for PID in $PIDS; do
        if kill -9 "$PID" 2>/dev/null; then
            echo "  ✓ 已杀死进程 $PID"
        else
            echo "  ⚠ 无法杀死进程 $PID（可能已退出）"
        fi
    done
    
    # 等待进程完全退出
    sleep 2
fi

# 清理PyTorch缓存（如果可能）
echo ""
echo "清理PyTorch缓存..."
python3 -c "import torch; torch.cuda.empty_cache(); print('  ✓ PyTorch缓存已清理')" 2>/dev/null || echo "  ⚠ 无法清理PyTorch缓存（可能未安装或没有Python进程）"

echo ""
echo "清理后的GPU状态："
nvidia-smi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    ✓ 清理完成！                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "现在可以重新运行训练脚本："
echo "  bash experiments/step4_simple_mix.sh"








