#!/bin/bash

# ═══════════════════════════════════════════════════════════════
#     步骤6：评估OOD泛化性能（可选的独立评估）
# ═══════════════════════════════════════════════════════════════

# 指定使用哪块GPU（1表示第二块GPU）
export CUDA_VISIBLE_DEVICES=3

# 项目根目录和数据集路径
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
SETTING="simple_mix_baseline"  # 消融实验1：基线（无OOD正则）

echo "当前评估实验: ${SETTING}"
echo ""

# ==================== 数据集配置 ====================
DATA_NAME="RC-49"     # 数据集名称
IMG_SIZE=64           # 图像分辨率（64x64）
MIN_LABEL=0           # 评估范围最小标签（0度）
MAX_LABEL=90          # ⭐ 评估全范围（0-90度）！即使训练时只用0-45度

# ==================== 模型配置 ====================
# 必须与训练时的配置完全一致
NET_NAME="SNGAN"      # 网络类型（SNGAN）
DIM_GAN=256           # 噪声向量维度（256）
DIM_Y=128             # 标签嵌入维度（128）
GENE_CH=64            # 生成器基础通道数（64）
DISC_CH=48            # 判别器基础通道数（48）

# ==================== 评估配置 ====================
# 从哪个checkpoint恢复（通常选最后一个）
RESUME_ITER=30000     # 评估第30000次迭代的模型（训练终点）

# ==================== 开始评估 ====================
echo "开始评估..."
echo "  - 实验: ${SETTING}"
echo "  - Checkpoint: ${RESUME_ITER}"
echo "  - 评估范围: ${MIN_LABEL}-${MAX_LABEL}度"
echo ""

# 切换到项目根目录
cd "${ROOT_PATH}"

# ==================== Python命令行参数说明 ====================
# --setting_name: 实验名称（用于找到对应的checkpoint）
# --data_name: 数据集名称（RC-49）
# --root_path: 项目根目录
# --data_path: 数据集路径
# --seed: 随机种子（保证可复现性）
# --min_label/max_label: 评估标签范围（0-90度全范围）
# --img_size: 图像大小（64x64）
# --max_num_img_per_label: 每个标签最多使用25张真实图片（用于计算FID）
# --net_name: 网络类型（SNGAN）
# --dim_z: 噪声向量维度（256）
# --dim_y: 标签嵌入维度（128）
# --gene_ch: 生成器基础通道数（64）
# --disc_ch: 判别器基础通道数（48）
# --niters 0: 训练迭代数设为0（表示只评估不训练）
# --resume_iter: 加载第30000次迭代的checkpoint
# --use_ema: ⭐ 注释掉后，不使用EMA模型评估（测试普通模型）
# --use_aux_reg_branch/model: 使用辅助回归分支（评估时需要）
# --aux_reg_loss_type: 辅助回归损失类型（必须与训练时一致）
# --use_ada_vic: 使用自适应vicinity（必须与训练时一致）
# --use_dre_reg: 使用DRE正则化（必须与训练时一致）
# --do_eval: 执行评估（计算FID、IS、LS等指标）
# --dump_fake_for_h5: 保存生成的图像为h5文件（用于后续分析）
# --samp_batch_size/eval_batch_size: 采样和评估的批量大小（200）

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
    --use_ema \
    --use_aux_reg_branch --use_aux_reg_model \
    --aux_reg_loss_type ei_hinge \
    --use_ada_vic --ada_vic_type hybrid --min_n_per_vic 50 --use_symm_vic \
    --use_dre_reg --dre_lambda 1e-2 \
    --do_eval \
    --dump_fake_for_h5 \
    --samp_batch_size 200 --eval_batch_size 200 \
    2>&1 | tee experiments/output_step6_eval_${SETTING}.txt

# ⭐ 如果要测试EMA模型，在 --resume_iter 后面添加：
#    

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
echo "  SETTING=\"simple_mix_perturb\"  # 评估只用L_perturb的模型"
echo "  SETTING=\"simple_mix_full\"     # 评估完整OOD增强的模型"

