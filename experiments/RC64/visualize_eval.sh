#!/bin/bash

###############################################################################
# 可视化评估结果脚本
# 用法：bash visualize_eval.sh [实验名称]
# 示例：bash visualize_eval.sh simple_mix_baseline
###############################################################################

ROOT_PATH="/home/wxc/nuist-lab/CcGAN-AVAR-OOD"
DATA_NAME="RC-49"

# ==================== 参数设置 ====================
# 如果提供了参数，使用参数；否则使用默认值
SETTING="${1:-simple_mix_baseline}"  # 默认实验名称

# ID/OOD区域划分（RC-49数据集）
ID_MIN=0
ID_MAX=45
OOD_MIN=45
OOD_MAX=90

echo "╔══════════════════════════════════════════════════════════╗"
echo "║          可视化评估结果                                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "实验名称: ${SETTING}"
echo ""

# ==================== 查找最新的评估结果 ====================
EVAL_BASE_DIR="${ROOT_PATH}/output/${DATA_NAME}_64/${SETTING}"

if [ ! -d "${EVAL_BASE_DIR}" ]; then
    echo "❌ 错误: 找不到实验目录: ${EVAL_BASE_DIR}"
    exit 1
fi

# 查找最新的eval目录（按时间倒序排列，取第一个即最新的）
ALL_EVAL_DIRS=($(ls -td ${EVAL_BASE_DIR}/eval_* 2>/dev/null))

if [ ${#ALL_EVAL_DIRS[@]} -eq 0 ]; then
    echo "❌ 错误: 找不到评估结果目录"
    echo "   请检查: ${EVAL_BASE_DIR}/eval_*/"
    exit 1
fi

# 取最新的eval目录
LATEST_EVAL_DIR="${ALL_EVAL_DIRS[0]}"
NPZ_FILE="${LATEST_EVAL_DIR}/fid_ls_entropy_over_centers.npz"

if [ ! -f "${NPZ_FILE}" ]; then
    echo "❌ 错误: 找不到评估数据文件"
    echo "   路径: ${NPZ_FILE}"
    exit 1
fi

echo "✅ 找到评估结果:"
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
echo "   文件: ${NPZ_FILE}"
echo ""

# ==================== 生成可视化 ====================
OUTPUT_IMG="${LATEST_EVAL_DIR}/eval_visualization.png"

cd "${ROOT_PATH}"

python experiments/RC64/visualize_eval_results.py \
    --npz_path "${NPZ_FILE}" \
    --output_path "${OUTPUT_IMG}" \
    --id_min ${ID_MIN} \
    --id_max ${ID_MAX} \
    --ood_min ${OOD_MIN} \
    --ood_max ${OOD_MAX} \
    --experiment_name "${SETTING}"

if [ $? -eq 0 ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                 ✓ 可视化完成！                            ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "📊 可视化图片已保存到:"
    echo "   ${OUTPUT_IMG}"
    echo ""
    echo "💡 提示："
    echo "   - 如果服务器有图形界面，可以直接查看"
    echo "   - 或者使用 scp 下载到本地查看："
    echo "     scp user@server:${OUTPUT_IMG} ./"
    echo ""
else
    echo ""
    echo "❌ 可视化失败！"
    exit 1
fi



