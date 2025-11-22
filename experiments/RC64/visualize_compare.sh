#!/bin/bash

###############################################################################
# 对比多个实验的评估结果
# 用法：bash visualize_compare.sh [实验1] [实验2] [实验3] ...
# 示例：bash visualize_compare.sh baseline_id_only simple_mix_baseline oracle_full
###############################################################################

ROOT_PATH="/home/wxc/nuist-lab/CcGAN-AVAR-OOD"
DATA_NAME="RC-49"

# ==================== 参数设置 ====================
# 如果提供了参数，使用参数；否则使用默认值
if [ $# -eq 0 ]; then
    echo "用法: bash visualize_compare.sh [实验1] [实验2] [实验3] ..."
    echo "示例: bash visualize_compare.sh baseline_id_only simple_mix_baseline oracle_full"
    exit 1
fi

EXPERIMENTS=("$@")

# ID/OOD区域划分（RC-49数据集）
ID_MIN=0
ID_MAX=45
OOD_MIN=45
OOD_MAX=90

echo "╔══════════════════════════════════════════════════════════╗"
echo "║          对比多个实验的评估结果                           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "将对比以下实验:"
for exp in "${EXPERIMENTS[@]}"; do
    echo "  - ${exp}"
done
echo ""

# ==================== 查找所有实验的评估结果 ====================
EVAL_DIRS=()

for SETTING in "${EXPERIMENTS[@]}"; do
    EVAL_BASE_DIR="${ROOT_PATH}/output/${DATA_NAME}_64/${SETTING}"
    
    if [ ! -d "${EVAL_BASE_DIR}" ]; then
        echo "⚠️  警告: 找不到实验目录: ${EVAL_BASE_DIR}"
        continue
    fi
    
    # 查找最新的eval目录（按时间倒序排列，取第一个即最新的）
    ALL_EVAL_DIRS=($(ls -td ${EVAL_BASE_DIR}/eval_* 2>/dev/null))
    
    if [ ${#ALL_EVAL_DIRS[@]} -eq 0 ]; then
        echo "⚠️  警告: 找不到评估结果目录: ${EVAL_BASE_DIR}/eval_*/"
        continue
    fi
    
    # 取最新的eval目录
    LATEST_EVAL_DIR="${ALL_EVAL_DIRS[0]}"
    EVAL_DIRS+=("${LATEST_EVAL_DIR}")
    
    # 显示找到的所有评估结果和使用的评估结果
    echo "✅ 找到: ${SETTING}"
    if [ ${#ALL_EVAL_DIRS[@]} -gt 1 ]; then
        echo "   共有 ${#ALL_EVAL_DIRS[@]} 个评估结果，使用最新的："
        for idx in "${!ALL_EVAL_DIRS[@]}"; do
            if [ $idx -eq 0 ]; then
                echo "   → $(basename ${ALL_EVAL_DIRS[$idx]}) [最新，将使用]"
            else
                echo "     $(basename ${ALL_EVAL_DIRS[$idx]})"
            fi
        done
    else
        echo "   → $(basename ${LATEST_EVAL_DIR}) [唯一结果]"
    fi
done

if [ ${#EVAL_DIRS[@]} -eq 0 ]; then
    echo "❌ 错误: 没有找到任何有效的评估结果！"
    exit 1
fi

echo ""
echo "将对比 ${#EVAL_DIRS[@]} 个实验的评估结果"
echo ""

# ==================== 生成对比图 ====================
OUTPUT_IMG="${ROOT_PATH}/experiments/RC64/eval_comparison.png"

cd "${ROOT_PATH}"

# 构建对比命令
COMPARE_ARGS=""
for dir in "${EVAL_DIRS[@]}"; do
    COMPARE_ARGS="${COMPARE_ARGS} ${dir}"
done

python experiments/RC64/visualize_eval_results.py \
    --compare ${COMPARE_ARGS} \
    --output_path "${OUTPUT_IMG}" \
    --id_min ${ID_MIN} \
    --id_max ${ID_MAX} \
    --ood_min ${OOD_MIN} \
    --ood_max ${OOD_MAX}

if [ $? -eq 0 ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                 ✓ 对比图生成完成！                        ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "📊 对比图已保存到:"
    echo "   ${OUTPUT_IMG}"
    echo ""
    echo "💡 提示："
    echo "   - 使用 scp 下载到本地查看："
    echo "     scp user@server:${OUTPUT_IMG} ./"
    echo ""
else
    echo ""
    echo "❌ 对比图生成失败！"
    exit 1
fi



