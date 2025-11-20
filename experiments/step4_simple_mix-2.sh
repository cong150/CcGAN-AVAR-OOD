#!/bin/bash

###############################################################################
# 步骤4：训练Simple-Mix - 简单混合训练（ID充足 + OOD少量）
#
# 说明：
# - 使用完整的CcGAN-AVAR配置
# - 使用步骤2生成的混合数据集
# - 包含0-45度全部数据 + 45-90度每角度5张
# - 目的：验证"简单混合少量OOD数据"是否足够
# - 预期：比Baseline好一些，但仍不够理想
###############################################################################

export NCCL_P2P_DISABLE=1
export NCCL_IB_DISABLE=1
export CUDA_VISIBLE_DEVICES=2

# ==================== 配置区域（请修改这两行）====================
ROOT_PATH="/home/wxc/nuist-lab/CcGAN-AVAR-OOD"
DATA_PATH="experiments/data"  # 使用混合数据集的路径
# ================================================================

echo "╔══════════════════════════════════════════════════════════╗"
echo "║    步骤4：训练Simple-Mix（简单混合基线）                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ==================== 实验参数 ====================
# 🎯 手动设置项目名字 - 消融实验2：只用扰动一致性正则（L_perturb）
SETTING="simple_mix_perturb"
VISDOM_ENV="${SETTING}"
LOG_FILE="experiments/output_${SETTING}.txt"

# 使用混合数据集，文件名必须是 RC-49_64x64.h5 格式
# 我们使用符号链接或重命名
MIXED_DATA_FILE="RC-49_mixed_id_full_ood_5_64x64.h5"

# 创建符号链接（如果不存在）
if [ ! -f "${DATA_PATH}/RC-49_64x64.h5" ] && [ -f "${DATA_PATH}/${MIXED_DATA_FILE}" ]; then
    echo "创建数据集符号链接..."
    ln -s "${MIXED_DATA_FILE}" "${DATA_PATH}/RC-49_64x64.h5"
fi

DATA_NAME="RC-49"
SEED=2025

# 训练区域：0-90度（混合数据集已经包含筛选后的数据）
MIN_LABEL=0
MAX_LABEL=90
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
RESUME_ITER=0  # ⚠️ 恢复训练时改为checkpoint编号
BATCH_SIZE_G=256
BATCH_SIZE_D=256
NUM_D_STEPS=2
LR_G=8e-5
LR_D=1e-4
NUM_ACC_D=1
NUM_ACC_G=1

# Vicinal参数
SIGMA=-1
KAPPA=-2

# === OOD-增强：条件扰动和插值一致性正则参数 ===
# ⚠️ 重要：如果训练出现质量退化（如生成黑色图像），请降低权重或设为0禁用
# 当前设置：非常保守的权重，避免训练不稳定
SIGMA_Y=0.047              # 标签扰动的标准差（建议0.05-0.2）
LAMBDA_PERTURB=0.025       # 扰动一致性正则权重（已降低：从0.03降到0.01，设为0可完全禁用）
LAMBDA_INTERP=0        # 插值一致性正则权重（已降低：从0.02降到0.005，设为0可完全禁用）

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
    --use_ada_vic --ada_vic_type hybrid --min_n_per_vic 50 --use_symm_vic \
    --use_aux_reg_branch --use_aux_reg_model \
    --aux_reg_loss_type ei_hinge --weight_d_aux_reg_loss 1.0 --weight_g_aux_reg_loss 1.0 \
    --use_dre_reg --dre_lambda 1e-2 --weight_d_aux_dre_loss 1.0 --weight_g_aux_dre_loss 0.5 \
    --sigma_y "${SIGMA_Y}" \
    --lambda_perturb "${LAMBDA_PERTURB}" \
    --lambda_interp "${LAMBDA_INTERP}" \
    --use_visdom \
    --visdom_env "${VISDOM_ENV}" \
    2>&1 | tee "${LOG_FILE}"

# 清理符号链接
if [ -L "${DATA_PATH}/RC-49_64x64.h5" ]; then
    rm "${DATA_PATH}/RC-49_64x64.h5"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    ✓ 步骤4完成！                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "模型保存在:"
echo "  ${ROOT_PATH}/output/RC-49_64/simple_mix_5/"
echo ""
echo "实验说明:"
echo "  这个实验验证'简单混合少量OOD数据'的效果"
echo "  预期：比Baseline改善，但可能仍不够理想"
echo ""
echo "下一步：执行步骤5，训练Oracle（性能上界）"
echo "  bash experiments/step5_oracle_full.sh"
echo ""

