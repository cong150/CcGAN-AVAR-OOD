#!/bin/bash

###############################################################################
# 步骤1：训练辅助回归模型（必须先执行！）
#
# 说明：
# - CcGAN-AVAR需要一个预训练的ResNet18回归网络
# - 这个网络用于辅助判别器学习标签信息
# - 使用0-90度全部数据训练（确保覆盖完整范围）
###############################################################################

# 指定使用哪块GPU（0表示第一块GPU）
export CUDA_VISIBLE_DEVICES=0

# ==================== 配置区域（请修改这两行）====================
ROOT_PATH="/home/wxc/nuist-lab/CcGAN-AVAR-OOD"  # 项目根目录
DATA_PATH="/home/wxc/datasets"                   # 数据集存放目录
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
DATA_NAME="RC-49"     # 数据集名称（对应 RC-49_64x64.h5 文件）
IMG_SIZE=64           # 图像分辨率（64x64）
SEED=2025             # 随机种子（保证可复现性）

# 使用全部0-90度数据训练（重要！覆盖完整标签空间）
MIN_LABEL=0           # 最小标签值（0度）
MAX_LABEL=90          # 最大标签值（90度）

# 辅助回归网络配置
NET_NAME="resnet18"   # 使用ResNet18作为回归网络
EPOCHS=200            # 训练轮数（200个epoch通常足够收敛）
BATCH_SIZE=256        # 批量大小（256适合大多数GPU）
BASE_LR=0.01          # 初始学习率（ResNet18的典型值）
WEIGHT_DECAY=1e-4     # 权重衰减（L2正则化，防止过拟合）

# ==================== 开始训练 ====================
# Python命令行参数说明：
# --root_path: 项目根目录（保存模型的位置）
# --data_path: 数据集所在目录
# --seed: 随机种子
# --data_name: 数据集名称（RC-49）
# --min_label/max_label: 训练数据的标签范围（0-90度）
# --img_size: 图像大小（64x64）
# --max_num_img_per_label: 每个标签最多使用25张图片（控制数据量）
# --net_name: 回归网络类型（resnet18）
# --epochs: 训练轮数（200）
# --batch_size_train: 训练批量大小（256）
# --base_lr: 基础学习率（0.01）
# --weight_dacay: 权重衰减（L2正则化系数）
# --use_amp: 使用自动混合精度（加速训练，节省显存）
# --mixed_precision_type: 混合精度类型（fp16=半精度浮点数）

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

