#!/bin/bash

# ═══════════════════════════════════════════════════════════════
#     步骤6：评估OOD泛化性能（可选的独立评估）
# ═══════════════════════════════════════════════════════════════

export CUDA_VISIBLE_DEVICES=2

ROOT_PATH="/home/wxc/nuist-lab/CcGAN-AVAR-OOD"
DATA_PATH="/home/wxc/datasets"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║          步骤6：评估OOD泛化性能（独立评估）               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "说明：此脚本用于对已训练好的模型进行独立评估"
echo "      特别是验证在OOD区域（45-90度）的生成质量"
echo ""

# ==================== 选择要评估的实验 ====================
# 🎯 手动设置要评估的实验名字（必须与训练时的SETTING一致）
SETTING="simple_mix_perturb"  # 消融实验2：只用扰动一致性正则（L_perturb）

echo "当前评估实验: ${SETTING}"
echo ""

# ==================== 数据集配置 ====================
DATA_NAME="RC-49"
IMG_SIZE=64
MIN_LABEL=0
MAX_LABEL=90  # ⭐ 评估全范围！即使训练时只用0-45

# ==================== 模型配置 ====================
NET_NAME="SNGAN"
DIM_GAN=256
DIM_Y=128
GENE_CH=64
DISC_CH=48

# ==================== 评估配置 ====================
# 从哪个checkpoint恢复（通常选最后一个）
RESUME_ITER=30000

# ==================== 开始评估 ====================
echo "开始评估..."
echo "  - 实验: ${SETTING}"
echo "  - Checkpoint: ${RESUME_ITER}"
echo "  - 评估范围: ${MIN_LABEL}-${MAX_LABEL}度"
echo ""

cd "${ROOT_PATH}"

python main.py \
    --setting_name "${SETTING}" \
    --data_name "${DATA_NAME}" \
    --root_path "${ROOT_PATH}" \
    --data_path "${DATA_PATH}" \
    --seed 2025 \
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
    --use_aux_reg_branch --use_aux_reg_model \
    --aux_reg_loss_type ei_hinge \
    --use_ada_vic --ada_vic_type hybrid --min_n_per_vic 50 --use_symm_vic \
    --use_dre_reg --dre_lambda 1e-2 \
    --do_eval \
    --dump_fake_for_h5 \
    --samp_batch_size 200 --eval_batch_size 200 \
    2>&1 | tee experiments/output_step6_eval_${SETTING}.txt

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    ✓ 评估完成！                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "结果位置："
echo "  - 评估指标: output/RC-49_64/${SETTING}/eval_*/"
echo "  - 生成样本: output/RC-49_64/${SETTING}/results/fake_data/"
echo ""
echo "📊 查看评估结果:"
echo "  cat output/RC-49_64/${SETTING}/eval_*/eval_results.txt"
echo ""
echo "💡 修改SETTING变量可评估其他模型："
echo "  SETTING=\"simple_mix_baseline\"  # 评估baseline模型"
echo "  SETTING=\"simple_mix_full\"      # 评估完整OOD增强的模型"



