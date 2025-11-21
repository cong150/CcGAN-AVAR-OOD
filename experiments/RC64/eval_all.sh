#!/bin/bash

###############################################################################
# 快速评估所有已训练的模型
# 用法：bash eval_all.sh
###############################################################################

export CUDA_VISIBLE_DEVICES=3

ROOT_PATH="/home/wxc/nuist-lab/CcGAN-AVAR-OOD"
DATA_PATH="/home/wxc/datasets"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║          批量评估所有实验的OOD泛化性能                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# 检查哪些实验已经训练完成
EXPERIMENTS=()
CHECKPOINTS=()

if [ -f "output/RC-49_64/baseline_id_only/results/ckpt_niter_30000.pth" ]; then
    EXPERIMENTS+=("baseline_id_only")
    CHECKPOINTS+=(30000)
    echo "✅ 发现: baseline_id_only (30000)"
fi

if [ -f "output/RC-49_64/simple_mix_5/results/ckpt_niter_30000.pth" ]; then
    EXPERIMENTS+=("simple_mix_5")
    CHECKPOINTS+=(30000)
    echo "✅ 发现: simple_mix_5 (30000)"
fi

if [ -f "output/RC-49_64/oracle_full/results/ckpt_niter_30000.pth" ]; then
    EXPERIMENTS+=("oracle_full")
    CHECKPOINTS+=(30000)
    echo "✅ 发现: oracle_full (30000)"
fi

if [ ${#EXPERIMENTS[@]} -eq 0 ]; then
    echo "❌ 没有找到已训练完成的模型！"
    exit 1
fi

echo ""
echo "将评估 ${#EXPERIMENTS[@]} 个实验..."
echo ""

# 评估每个实验
for i in "${!EXPERIMENTS[@]}"; do
    EXPERIMENT="${EXPERIMENTS[$i]}"
    RESUME_ITER="${CHECKPOINTS[$i]}"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[$((i+1))/${#EXPERIMENTS[@]}] 评估: ${EXPERIMENT}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # 设置数据路径（simple_mix需要特殊处理）
    if [[ "$EXPERIMENT" == "simple_mix_"* ]]; then
        EVAL_DATA_PATH="experiments/data"
        # 创建符号链接
        if [ -f "experiments/data/RC-49_mixed_id_full_ood_5_64x64.h5" ]; then
            ln -sf "RC-49_mixed_id_full_ood_5_64x64.h5" "experiments/data/RC-49_64x64.h5"
        fi
    else
        EVAL_DATA_PATH="${DATA_PATH}"
    fi
    
    cd "${ROOT_PATH}"
    
    python main.py \
        --setting_name "${EXPERIMENT}" \
        --data_name "RC-49" \
        --root_path "${ROOT_PATH}" \
        --data_path "${EVAL_DATA_PATH}" \
        --seed 2025 \
        --min_label 0 \
        --max_label 90 \
        --img_size 64 \
        --max_num_img_per_label 25 \
        --net_name "SNGAN" \
        --dim_z 256 \
        --dim_y 128 \
        --gene_ch 64 \
        --disc_ch 48 \
        --niters 0 \
        --resume_iter "${RESUME_ITER}" \
        --use_ema \
        --use_aux_reg_branch --use_aux_reg_model \
        --aux_reg_loss_type ei_hinge \
        --use_ada_vic --ada_vic_type hybrid --min_n_per_vic 50 --use_symm_vic \
        --use_dre_reg --dre_lambda 1e-2 \
        --sigma_y 0.047 \
        --lambda_perturb 0 \
        --lambda_interp 0 \
        --do_eval \
        --dump_fake_for_h5 \
        --samp_batch_size 200 --eval_batch_size 200 \
        2>&1 | tee experiments/output_eval_${EXPERIMENT}.txt
    
    echo ""
    echo "✅ ${EXPERIMENT} 评估完成！"
    echo "   结果: output/RC-49_64/${EXPERIMENT}/eval_*/"
    echo ""
    
    # 清理符号链接
    if [[ "$EXPERIMENT" == "simple_mix_"* ]]; then
        rm -f "experiments/data/RC-49_64x64.h5"
    fi
done

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                 ✓ 所有评估完成！                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "📊 查看评估结果："
echo ""

for EXPERIMENT in "${EXPERIMENTS[@]}"; do
    EVAL_DIR=$(ls -td output/RC-49_64/${EXPERIMENT}/eval_* 2>/dev/null | head -1)
    if [ -d "$EVAL_DIR" ]; then
        echo "【${EXPERIMENT}】"
        echo "  评估报告: ${EVAL_DIR}/eval_results.txt"
        if [ -f "${EVAL_DIR}/eval_results.txt" ]; then
            echo "  主要指标:"
            grep -E "Label_Score|FID|Diversity" "${EVAL_DIR}/eval_results.txt" | head -5
        fi
        echo ""
    fi
done

echo "💡 提示："
echo "  - 完整报告: cat output/RC-49_64/*/eval_*/eval_results.txt"
echo "  - 生成图片: ls output/RC-49_64/*/results/fake_data/h5/"



