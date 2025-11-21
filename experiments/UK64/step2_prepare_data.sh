#!/bin/bash

###############################################################################
# 步骤2：准备混合训练数据
#
# 说明：
# - 准备混合数据集用于对比实验
# - 这一步是可选的，主要用于分析和可视化
###############################################################################

# ==================== 配置区域（请修改）====================
DATA_PATH="/home/wxc/datasets/UTKFace_64x64.h5"
# ==========================================================

echo "╔══════════════════════════════════════════════════════════╗"
echo "║        步骤2：准备混合训练数据（可选）- UTKFace           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# 创建数据目录
mkdir -p experiments/data

echo "创建混合训练集（1-30岁全部 + 30-60岁每年龄5张）..."
python experiments/UK64/prepare_ood_data.py \
    --mode mixed \
    --data_path "${DATA_PATH}" \
    --output_path experiments/data/UTKFace_mixed_id_full_ood_5_64x64.h5 \
    --id_min 1.0 \
    --id_max 30.0 \
    --ood_min 30.0 \
    --ood_max 60.0 \
    --ood_samples_per_label 5 \
    --seed 2025

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    ✓ 步骤2完成！                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "生成的文件："
echo "  experiments/data/UTKFace_mixed_id_full_ood_5_64x64.h5"
echo ""
echo "数据集说明："
echo "  - ID区域（1-30岁）：全部训练数据"
echo "  - OOD区域（30-60岁）：每个年龄5张"
echo "  - 这个混合数据集用于步骤4的Simple-Mix实验"
echo ""
echo "实验设计："
echo "  Step 3: Baseline（只用1-30岁）→ 验证OOD问题"
echo "  Step 4: Simple-Mix（混合数据）→ 测试OOD正则化"
echo "  Step 5: Oracle（全部数据）→ 性能上界"
echo ""
echo "下一步：执行步骤3，训练Baseline模型"
echo "  bash experiments/UK64/step3_baseline_id_only.sh"
echo ""

