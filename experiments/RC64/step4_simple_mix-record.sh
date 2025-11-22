#!/bin/bash

###############################################################################
# 步骤4：训练Simple-Mix - 简单混合训练（ID充足 + OOD少量）
#
# 说明：
# - 使用完整的CcGAN-AVAR配置
# - 使用步骤2生成的混合数据集
# - 包含0-45度全部数据 + 45-90度每角度5张
# - 目的：验证"简单混合少量OOD数据"是否足够
###############################################################################

# NCCL配置（分布式训练相关，单卡训练也保留）
export NCCL_P2P_DISABLE=1  # 禁用点对点传输（避免某些硬件兼容性问题）
export NCCL_IB_DISABLE=1    # 禁用InfiniBand（如果没有IB网络）
export CUDA_VISIBLE_DEVICES=3  # 指定使用第4块GPU（编号从0开始）

# ==================== 配置区域（请修改这两行）====================
ROOT_PATH="/home/wxc/nuist-lab/CcGAN-AVAR-OOD"  # 项目根目录
DATA_PATH="experiments/data"  # 使用混合数据集的路径（相对于ROOT_PATH）
# ================================================================

echo "╔══════════════════════════════════════════════════════════╗"
echo "║    步骤4：训练Simple-Mix（简单混合基线）                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ==================== 实验参数 ====================
# 🎯 手动设置项目名字 - 消融实验1：基线（无OOD正则）
SETTING="simple_mix_baseline"  # 实验名称（保存模型的文件夹名）
VISDOM_ENV="${SETTING}"        # Visdom环境名（用于可视化区分不同实验）
LOG_FILE="experiments/output_${SETTING}.txt"  # 日志文件路径

# 使用混合数据集，文件名必须是 RC-49_64x64.h5 格式
# 我们使用符号链接或重命名
MIXED_DATA_FILE="RC-49_mixed_id_full_ood_5_64x64.h5"  # 混合数据集文件名

# 创建符号链接（如果不存在）
# 原因：代码默认读取 RC-49_64x64.h5，我们通过符号链接指向混合数据集
if [ ! -f "${DATA_PATH}/RC-49_64x64.h5" ] && [ -f "${DATA_PATH}/${MIXED_DATA_FILE}" ]; then
    echo "创建数据集符号链接..."
# 在数据目录下，创建一个“名为RC-49_64x64.h5的链接”，指向真实的混合数据集
    ln -s "${MIXED_DATA_FILE}" "${DATA_PATH}/RC-49_64x64.h5"
fi

DATA_NAME="RC-49"     # 数据集名称
SEED=2025             # 随机种子（保证可复现性）

# 训练区域：0-90度（混合数据集已经包含筛选后的数据）
MIN_LABEL=0           # 最小标签（0度）
MAX_LABEL=90          # 最大标签（90度）
IMG_SIZE=64           # 图像分辨率（64x64）

# ==================== 模型配置 ====================
NET_NAME="SNGAN"      # 使用SNGAN（Spectral Normalization GAN）
LOSS_TYPE="hinge"     # GAN损失类型（hinge loss，适合SNGAN）
THRESH_TYPE="soft"    # CcGAN的阈值类型（soft=软阈值，平滑过渡）
DIM_GAN=256           # GAN的隐藏层维度（256）
DIM_Y=128             # 标签嵌入维度（128）
GENE_CH=64            # 生成器的基础通道数（64）
DISC_CH=48            # 判别器的基础通道数（48）

# ==================== 训练参数 ====================
NITERS=30000          # 总训练迭代数（30000次）
RESUME_ITER=0     # 从哪个checkpoint恢复训练（0=从头训练，10000=从第10000次迭代恢复）
BATCH_SIZE_G=256      # 生成器的批量大小（256）
BATCH_SIZE_D=256      # 判别器的批量大小（256）
NUM_D_STEPS=2         # 每次更新生成器前，更新判别器的次数（2:1的比例）
LR_G=1e-4             # 生成器学习率（0.0001）
LR_D=1e-4             # 判别器学习率（0.0001）
NUM_ACC_D=1           # 判别器梯度累积步数（1=不累积，每步都更新）
NUM_ACC_G=1           # 生成器梯度累积步数（1=不累积，每步都更新）

# ==================== Vicinal参数 ====================
# CcGAN-AVAR的核心参数（控制标签的邻域范围）
SIGMA=-1              # kernel_sigma（-1=自动计算，根据数据分布自适应）
KAPPA=-2              # kappa（-2=使用自适应vicinity）

# ==================== OOD正则化参数 ====================
# 条件扰动和插值一致性正则化（你的创新点）
SIGMA_Y=0.047         # 标签扰动的标准差（控制L_perturb中的噪声强度）
LAMBDA_PERTURB=0      # 扰动一致性正则权重（0=不使用L_perturb，这是baseline）
LAMBDA_INTERP=0       # 插值一致性正则权重（0=不使用L_interp，这是baseline）

# ==================== 开始训练 ====================
# Python命令行参数详细说明（按功能分组）：
#
# 【基础配置】
# --setting_name: 实验名称（保存路径会用到）
# --data_name: 数据集名称（RC-49）
# --root_path: 项目根目录
# --data_path: 数据集路径
# --seed: 随机种子
# --min_label/max_label: 训练数据标签范围（0-90度）
# --img_size: 图像大小（64x64）
# --max_num_img_per_label: 每个标签最多使用25张（与辅助回归一致）
#
# 【模型架构】
# --net_name: 网络类型（SNGAN）
# --dim_z: 噪声向量维度（256）
# --dim_y: 标签嵌入维度（128）
# --gene_ch: 生成器基础通道数（64）
# --disc_ch: 判别器基础通道数（48）
#
# 【训练设置】
# --niters: 总训练迭代数（30000）
# --resume_iter: 恢复训练的迭代数（0=从头训练）
# --loss_type: GAN损失类型（hinge）
# --num_D_steps: D:G更新比例（2:1）
# --save_freq: 每10000次迭代保存一次模型
# --sample_freq: 每5000次迭代生成一次样本图片
# --batch_size_disc/gene: 判别器/生成器批量大小（256）
# --lr_g/lr_d: 生成器/判别器学习率（1e-4）
# --num_grad_acc_d/g: 梯度累积步数（1）
#
# 【CcGAN-AVAR配置】
# --kernel_sigma: CcGAN的kernel sigma（-1=自动）
# --threshold_type: 阈值类型（soft）
# --kappa: CcGAN的kappa参数（-2=自适应）
# --use_ada_vic: 使用自适应vicinity
# --ada_vic_type: vicinity类型（hybrid）
# --min_n_per_vic: 每个vicinity最少样本数（50）
# --use_symm_vic: 使用对称vicinity
#
# 【辅助任务】
# --use_aux_reg_branch/model: 使用辅助回归分支和预训练模型
# --aux_reg_loss_type: 辅助回归损失类型（ei_hinge）
# --weight_d/g_aux_reg_loss: 判别器/生成器的辅助回归损失权重（1.0）
# --use_dre_reg: 使用DRE正则化
# --dre_lambda: DRE lambda参数（1e-2）
# --weight_d/g_aux_dre_loss: 判别器/生成器的DRE损失权重
#
# 【OOD正则化（你的创新点）】
# --sigma_y: 标签扰动标准差（L_perturb用）
# --lambda_perturb: L_perturb权重（0=不使用，这是baseline）
# --lambda_interp: L_interp权重（0=不使用，这是baseline）
#
# 【优化技巧】
# --use_diffaug: 使用数据增强（颜色、平移、cutout）
# --use_ema: 使用EMA模型
# --use_amp: 使用混合精度
# --max_grad_norm: 梯度裁剪（1.0）
#
# 【可视化】
# --use_visdom: 启用Visdom实时监控
# --visdom_port: Visdom服务器端口（8098）
# --visdom_env: Visdom环境名（区分不同实验）

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
    --use_ema \
    --use_amp --max_grad_norm 1.0 \
    --use_ada_vic --ada_vic_type hybrid --min_n_per_vic 50 --use_symm_vic \
    --use_aux_reg_branch --use_aux_reg_model \
    --aux_reg_loss_type ei_hinge --weight_d_aux_reg_loss 1.0 --weight_g_aux_reg_loss 1.0 \
    --use_dre_reg --dre_lambda 1e-2 --weight_d_aux_dre_loss 1.0 --weight_g_aux_dre_loss 0.5 \
    --sigma_y "${SIGMA_Y}" \
    --lambda_perturb "${LAMBDA_PERTURB}" \
    --lambda_interp "${LAMBDA_INTERP}" \
    --use_visdom \
    --visdom_port 8098 \
    --visdom_env "${VISDOM_ENV}" \
    2>&1 | tee "${LOG_FILE}"


# 清理符号链接（训练结束后删除临时链接）
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

