#!/bin/bash

###############################################################################
# 评估：Baseline ID-Only（只用1-30岁训练）
###############################################################################

export NCCL_P2P_DISABLE=1
export NCCL_IB_DISABLE=1
export CUDA_VISIBLE_DEVICES=0

# ==================== 配置区域（请修改这两行）====================
ROOT_PATH="/home/wxc/nuist-lab/CcGAN-AVAR-OOD"
DATA_PATH="/home/wxc/datasets"
# ================================================================

echo "╔══════════════════════════════════════════════════════════╗"
echo "║          评估：Baseline ID-Only - UTKFace                 ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ==================== 实验参数 ====================
DATA_NAME="UTKFace"
SETTING="baseline_id_only"
SEED=2025

# 评估区域：1-60岁（包括ID和OOD）
MIN_LABEL=1
MAX_LABEL=60
IMG_SIZE=64

# 模型配置
NET_NAME="SNGAN"
LOSS_TYPE="hinge"
THRESH_TYPE="soft"
DIM_GAN=256
DIM_Y=128
GENE_CH=64
DISC_CH=48

# 评估参数
RESUME_ITER=30000  # 评估最终模型

# ==================== 开始评估 ====================
python main.py \
    --setting_name "${SETTING}" \
    --data_name "${DATA_NAME}" \
    --root_path "${ROOT_PATH}" \
    --data_path "${DATA_PATH}" \
    --seed "${SEED}" \
    --min_label "${MIN_LABEL}" \
    --max_label "${MAX_LABEL}" \
    --img_size "${IMG_SIZE}" \
    --max_num_img_per_label 25 \
    --net_name "${NET_NAME}" \
    --dim_z "${DIM_GAN}" \
    --dim_y "${DIM_Y}" \
    --gene_ch "${GENE_CH}" \
    --disc_ch "${DISC_CH}" \
    --niters 0 \
    --resume_iter "${RESUME_ITER}" \
    --loss_type "${LOSS_TYPE}" \
    --kernel_sigma -1 \
    --threshold_type "${THRESH_TYPE}" \
    --kappa -1 \
    --use_ema \
    --use_ada_vic --ada_vic_type hybrid --min_n_per_vic 400 --use_symm_vic \
    --do_eval \
    --dump_fake_for_h5 \
    --samp_batch_size 500 \
    --eval_batch_size 500 \
    2>&1 | tee experiments/UK64/output_step6_eval_${SETTING}.txt

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    ✓ 评估完成！                           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "评估结果保存在:"
echo "  ${ROOT_PATH}/output/UTKFace_64/${SETTING}/eval_results/"
echo ""

