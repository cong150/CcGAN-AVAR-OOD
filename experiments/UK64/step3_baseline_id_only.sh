#!/bin/bash

###############################################################################
# 步骤3：训练Baseline - 只使用ID区域（1-30岁）数据
#
# 说明：
# - 使用完整的CcGAN-AVAR配置
# - 只用1-30岁数据训练
# - 用于验证OOD问题的存在
###############################################################################

export NCCL_P2P_DISABLE=1
export NCCL_IB_DISABLE=1
export CUDA_VISIBLE_DEVICES=0

# ==================== 配置区域（请修改这两行）====================
ROOT_PATH="/home/wxc/nuist-lab/CcGAN-AVAR-OOD"
DATA_PATH="/home/wxc/datasets"
# ================================================================

echo "╔══════════════════════════════════════════════════════════╗"
echo "║      步骤3：训练Baseline（只用1-30岁）- UTKFace           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ==================== 实验参数 ====================
DATA_NAME="UTKFace"
SETTING="baseline_id_only"
VISDOM_ENV="${SETTING}"
SEED=2025

# 训练区域：只用1-30岁
MIN_LABEL=1
MAX_LABEL=30
IMG_SIZE=64

# 模型配置
NET_NAME="SNGAN"
LOSS_TYPE="hinge"
THRESH_TYPE="soft"
DIM_GAN=256
DIM_Y=128
GENE_CH=64
DISC_CH=48

# 训练参数
NITERS=30000
RESUME_ITER=0

# Batch Size设置
BATCH_SIZE_G=64
BATCH_SIZE_D=64
NUM_D_STEPS=2
LR_G=1e-4
LR_D=1e-4
NUM_ACC_D=1
NUM_ACC_G=1

# Vicinal参数
SIGMA=-1
KAPPA=-1

# OOD正则化参数（Baseline不使用）
SIGMA_Y=0.04
LAMBDA_PERTURB=0
LAMBDA_INTERP=0

# ==================== 开始训练 ====================
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
    --niters "${NITERS}" \
    --resume_iter "${RESUME_ITER}" \
    --loss_type "${LOSS_TYPE}" \
    --num_D_steps "${NUM_D_STEPS}" \
    --save_freq 10000 \
    --sample_freq 5000 \
    --batch_size_disc "${BATCH_SIZE_D}" \
    --batch_size_gene "${BATCH_SIZE_G}" \
    --lr_g "${LR_G}" \
    --lr_d "${LR_D}" \
    --num_grad_acc_d "${NUM_ACC_D}" \
    --num_grad_acc_g "${NUM_ACC_G}" \
    --kernel_sigma "${SIGMA}" \
    --threshold_type "${THRESH_TYPE}" \
    --kappa "${KAPPA}" \
    --use_diffaug --diffaug_policy color,translation,cutout \
    --use_ema --use_amp --max_grad_norm 1.0 \
    --use_ada_vic --ada_vic_type hybrid --min_n_per_vic 400 --use_symm_vic \
    --use_aux_reg_branch --use_aux_reg_model \
    --aux_reg_loss_type ei_hinge --weight_d_aux_reg_loss 1.0 --weight_g_aux_reg_loss 1.0 \
    --use_dre_reg --dre_lambda 1e-2 --weight_d_aux_dre_loss 0.5 --weight_g_aux_dre_loss 0.5 \
    --sigma_y "${SIGMA_Y}" \
    --lambda_perturb "${LAMBDA_PERTURB}" \
    --lambda_interp "${LAMBDA_INTERP}" \
    --use_visdom \
    --visdom_port 8098 \
    --visdom_env "${VISDOM_ENV}" \
    2>&1 | tee experiments/UK64/output_${SETTING}.txt

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    ✓ 步骤3完成！                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "模型保存在:"
echo "  ${ROOT_PATH}/output/UTKFace_64/${SETTING}/"
echo ""
echo "实验说明:"
echo "  这个实验验证'纯ID训练'在OOD区域的失败"
echo "  预期：1-30岁生成好，30-60岁生成差"
echo ""
echo "下一步：执行步骤4，训练Simple-Mix实验"
echo "  bash experiments/UK64/step4_simple_mix_baseline.sh"
echo ""

