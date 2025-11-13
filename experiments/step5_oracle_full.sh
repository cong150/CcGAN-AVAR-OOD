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
BATCH_SIZE_G=256
BATCH_SIZE_D=256
NUM_D_STEPS=2
LR_G=1e-4
LR_D=1e-4
NUM_ACC_D=1
NUM_ACC_G=1

# Vicinal参数
SIGMA=-1
KAPPA=-2

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
    --do_eval \
    --samp_batch_size 200 --eval_batch_size 200 \
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

