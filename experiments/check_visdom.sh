#!/bin/bash

###############################################################################
# Visdom 快速诊断脚本
# 
# 用途：检查 Visdom 的安装和配置状态
# 使用：bash experiments/check_visdom.sh
###############################################################################

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           Visdom 配置诊断工具                                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SUCCESS="${GREEN}✓${NC}"
FAIL="${RED}✗${NC}"
WARN="${YELLOW}⚠${NC}"

# 计数器
PASS_COUNT=0
FAIL_COUNT=0
TOTAL_CHECKS=6

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 1. 检查 Visdom 是否安装"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if python -c "import visdom" 2>/dev/null; then
    VERSION=$(python -c "import visdom; print(visdom.__version__)" 2>/dev/null)
    echo -e "${SUCCESS} Visdom 已安装，版本: ${VERSION}"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${FAIL} Visdom 未安装"
    echo ""
    echo "   安装方法："
    echo "   pip install visdom"
    echo ""
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 2. 检查 Visdom 服务器是否运行"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ps aux | grep "[p]ython -m visdom.server" > /dev/null 2>&1; then
    PID=$(ps aux | grep "[p]ython -m visdom.server" | awk '{print $2}')
    echo -e "${SUCCESS} Visdom 服务器正在运行 (PID: ${PID})"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${FAIL} Visdom 服务器未运行"
    echo ""
    echo "   启动方法："
    echo "   # 方法1: 使用 screen（推荐）"
    echo "   screen -S visdom"
    echo "   python -m visdom.server"
    echo "   # 按 Ctrl+A, 然后按 D 退出"
    echo ""
    echo "   # 方法2: 使用 nohup（后台运行）"
    echo "   nohup python -m visdom.server > visdom.log 2>&1 &"
    echo ""
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 3. 检查默认端口 (8098) 是否监听"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if netstat -tuln 2>/dev/null | grep ":8098 " > /dev/null 2>&1 || \
   ss -tuln 2>/dev/null | grep ":8098 " > /dev/null 2>&1; then
    echo -e "${SUCCESS} 端口 8098 正在监听"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${FAIL} 端口 8098 未监听"
    echo ""
    echo "   可能原因："
    echo "   1. Visdom 服务器未启动"
    echo "   2. Visdom 使用了其他端口"
    echo ""
    echo "   检查其他端口："
    if command -v netstat &> /dev/null; then
        netstat -tuln | grep -E "809[0-9]|810[0-9]" | head -5
    elif command -v ss &> /dev/null; then
        ss -tuln | grep -E "809[0-9]|810[0-9]" | head -5
    fi
    echo ""
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 4. 检查训练脚本配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
SCRIPT_COUNT=0
SCRIPT_OK=0

for script in experiments/step4_simple_mix-*.sh; do
    if [ -f "$script" ]; then
        SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
        if grep -q "\-\-use_visdom" "$script"; then
            echo -e "${SUCCESS} $(basename $script) 已配置 Visdom"
            SCRIPT_OK=$((SCRIPT_OK + 1))
        else
            echo -e "${WARN} $(basename $script) 未配置 Visdom"
            echo "       需要添加: --use_visdom \\"
        fi
    fi
done

if [ $SCRIPT_OK -eq $SCRIPT_COUNT ] && [ $SCRIPT_COUNT -gt 0 ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
else
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 5. 检查 opts.py 配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if grep -q "use_visdom" opts.py && grep -q "visdom_port" opts.py; then
    PORT=$(grep "visdom_port.*default" opts.py | grep -oP 'default=\K[0-9]+' | head -1)
    echo -e "${SUCCESS} opts.py 配置正确，默认端口: ${PORT}"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${FAIL} opts.py 配置缺失"
    echo ""
    echo "   需要确保 opts.py 中有："
    echo "   parser.add_argument('--use_visdom', action='store_true', ...)"
    echo "   parser.add_argument('--visdom_port', type=int, default=8098, ...)"
    echo ""
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 6. 检查 trainer.py 配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if grep -q "from visdom import Visdom" trainer.py || grep -q "import visdom" trainer.py; then
    if grep -q "use_visdom" trainer.py; then
        echo -e "${SUCCESS} trainer.py 配置正确"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e "${WARN} trainer.py 中 Visdom 代码可能不完整"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
else
    echo -e "${FAIL} trainer.py 中缺少 Visdom 导入"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                      诊断结果汇总                               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "   通过: ${PASS_COUNT}/${TOTAL_CHECKS}"
echo "   失败: ${FAIL_COUNT}/${TOTAL_CHECKS}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ 所有检查通过！Visdom 应该可以正常工作。${NC}"
    echo ""
    echo "下一步："
    echo "  1. 确保你在本地电脑配置了 SSH 端口转发："
    echo "     ssh -L 8098:localhost:8098 用户名@服务器地址"
    echo ""
    echo "  2. 在本地浏览器访问："
    echo "     http://localhost:8098"
    echo ""
    echo "  3. 启动训练："
    echo "     bash experiments/step4_simple_mix-1.sh"
    echo ""
    echo "  4. 在 Visdom 界面左上角选择对应的环境名称"
    echo ""
else
    echo -e "${RED}✗ 发现 ${FAIL_COUNT} 个问题，请根据上述提示进行修复。${NC}"
    echo ""
    echo "常见解决方案："
    echo "  1. 安装 Visdom:"
    echo "     pip install visdom"
    echo ""
    echo "  2. 启动 Visdom 服务器:"
    echo "     screen -S visdom"
    echo "     python -m visdom.server"
    echo "     # Ctrl+A, D 退出"
    echo ""
    echo "  3. 查看详细指南:"
    echo "     cat experiments/documents/Visdom配置和使用指南.md"
    echo ""
fi

echo "════════════════════════════════════════════════════════════════"
echo ""

# 额外信息
echo "💡 额外信息："
echo ""

# 检查是否有正在运行的训练
if ps aux | grep "[p]ython main.py" > /dev/null 2>&1; then
    echo "   • 检测到正在运行的训练进程"
    ps aux | grep "[p]ython main.py" | awk '{print "     PID: " $2}'
fi

# 检查最近的日志文件
if ls experiments/output_*.txt 1> /dev/null 2>&1; then
    echo "   • 最近的训练日志:"
    ls -lt experiments/output_*.txt | head -3 | awk '{print "     " $9 " (" $6 " " $7 " " $8 ")"}'
fi

echo ""
echo "如需帮助，请查看："
echo "  experiments/documents/Visdom配置和使用指南.md"
echo ""

