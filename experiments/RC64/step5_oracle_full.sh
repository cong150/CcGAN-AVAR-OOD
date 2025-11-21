#!/bin/bash

###############################################################################
# 步骤5：训练Oracle - 使用0-90度全部数据（性能上界）
#
# 说明：
# - 使用完整的CcGAN-AVAR配置
# - 使用0-90度全部训练数据
# - 作为性能上界对比
###############################################################################

export NCCL_P2P_DISABLE=1
export NCCL_IB_DISABLE=1
export CUDA_VISIBLE_DEVICES=3

# ==================== 配置区域（请修改这两行）====================
ROOT_PATH="/home/wxc/nuist-lab/CcGAN-AVAR-OOD"
DATA_PATH="/home/wxc/datasets"
# ================================================================

echo "╔══════════════════════════════════════════════════════════╗"
echo "║      步骤5：训练Oracle（0-90度全部，性能上界）             ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ==================== 实验参数 ====================
DATA_NAME="RC-49"
SETTING="oracle_full"
SEED=2025

# 训练区域：全部0-90度
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
RESUME_ITER=10000  # ⚠️ 恢复训练时改为checkpoint编号

# Batch Size设置
# ⚠️ 注意：如果出现GPU内存不足，请减少batch size
# 建议值：
#   - 32GB GPU: 64（推荐）或 32（如果64仍不够）
#   - 16GB GPU: 32 或 16
#   - 24GB GPU: 48 或 32
# 原值256太大，会导致内存不足（特别是启用OOD增强时）
BATCH_SIZE_G=64
BATCH_SIZE_D=64
NUM_D_STEPS=2
LR_G=1e-4
LR_D=1e-4
NUM_ACC_D=1
NUM_ACC_G=1

# Vicinal参数
SIGMA=-1
KAPPA=-2

# === OOD-增强：条件扰动和插值一致性正则参数 ===
# 默认启用（lambda=0.1），设置为0可禁用对应正则项
# ⚠️ 注意：如果训练出现NaN，可以降低权重或设为0禁用
SIGMA_Y=0.1              # 标签扰动的标准差（建议0.05-0.2）
LAMBDA_PERTURB=0.1       # 扰动一致性正则权重（建议0.05-0.5，设为0禁用）
LAMBDA_INTERP=0.1        # 插值一致性正则权重（建议0.05-0.5，设为0禁用）

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
    2>&1 | tee experiments/output_step5_oracle.txt

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    ✓ 步骤5完成！                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "模型保存在:"
echo "  ${ROOT_PATH}/output/RC-49_64/oracle_full/"
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║           🎉 全部训练完成！                               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "三个对比实验已完成："
echo "  1. Baseline (只用0-45度): baseline_id_only/"
echo "  2. Simple-Mix (混合少量OOD): simple_mix_50/"
echo "  3. Oracle (全部0-90度): oracle_full/"
echo ""
echo "实验目的："
echo "  - Baseline: 验证OOD问题存在"
echo "  - Simple-Mix: 测试简单混合是否足够"
echo "  - Oracle: 性能上界参考"
echo ""
echo "下一步：对比分析结果"
echo "  1. 查看三个模型的 results/fake_data/ 目录"
echo "  2. 对比ID区域（0-45度）和OOD区域（45-90度）的生成质量"
echo "  3. 分析Simple-Mix相比Baseline的改善程度"
echo "  4. 评估与Oracle的差距"
echo ""

