#!/bin/bash

###############################################################################
# 步骤1：训练辅助回归模型（必须先执行！）
#
# 说明：
# - CcGAN-AVAR需要一个预训练的ResNet18回归网络
# - 这个网络用于辅助判别器学习标签信息
# - 使用0-90度全部数据训练（确保覆盖完整范围）
###############################################################################

export CUDA_VISIBLE_DEVICES=0

# ==================== 配置区域（请修改这两行）====================
ROOT_PATH="/home/wxc/nuist-lab/CcGAN-AVAR-OOD"
DATA_PATH="/home/wxc/datasets"
# ================================================================

echo "╔══════════════════════════════════════════════════════════╗"
echo "║      步骤1：训练辅助回归模型（ResNet18）                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "配置信息："
echo "  项目路径: ${ROOT_PATH}"
echo "  数据路径: ${DATA_PATH}"
echo "  训练范围: 0-90度（全范围）"
echo "  训练轮数: 200 epochs"
echo ""

# ==================== 实验参数 ====================
DATA_NAME="RC-49"
IMG_SIZE=64
SEED=2025

# 使用全部0-90度数据训练（重要！）
MIN_LABEL=0
MAX_LABEL=90

# 辅助回归网络配置
NET_NAME="resnet18"
EPOCHS=200
BATCH_SIZE=256
BASE_LR=0.01
WEIGHT_DECAY=1e-4

# ==================== 开始训练 ====================
python auxiliary_regression.py \
    --root_path "${ROOT_PATH}" \
    --data_path "${DATA_PATH}" \
    --seed "${SEED}" \
    --data_name "${DATA_NAME}" \
    --min_label "${MIN_LABEL}" \
    --max_label "${MAX_LABEL}" \
    --img_size "${IMG_SIZE}" \
    --max_num_img_per_label 25 \
    --net_name "${NET_NAME}" \
    --epochs "${EPOCHS}" \
    --batch_size_train "${BATCH_SIZE}" \
    --base_lr "${BASE_LR}" \
    --weight_dacay "${WEIGHT_DECAY}" \
    --use_amp \
    --mixed_precision_type fp16 \
    2>&1 | tee experiments/output_step1_aux_regression.txt

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    ✓ 步骤1完成！                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "检查点保存在:"
echo "  ${ROOT_PATH}/output/RC-49_64/aux_reg_model/ckpt_resnet18_epoch_200.pth"
echo ""
echo "下一步：执行步骤2，准备混合数据集"
echo "  bash step2_prepare_data.sh"
echo ""

