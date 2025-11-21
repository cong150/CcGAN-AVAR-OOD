# UTKFace OOD实验指南

本文件夹包含UTKFace数据集的完整OOD泛化实验脚本。

## 📋 实验目标

验证**条件扰动一致性** (`L_perturb`) 和**插值一致性** (`L_interp`) 两种OOD正则化方法在UTKFace年龄生成任务上的有效性。

## 🗂️ 文件结构

```
experiments/UK64/
├── prepare_ood_data.py                    # 数据预处理脚本
├── step1_train_aux_regression.sh          # 步骤1：训练辅助回归模型
├── step2_prepare_data.sh                  # 步骤2：准备混合数据集（可选）
├── step3_baseline_id_only.sh              # 步骤3：Baseline（仅ID区域）
├── step4_simple_mix_baseline.sh           # 步骤4-1：Simple-Mix Baseline（无正则）
├── step4_simple_mix_perturb.sh            # 步骤4-2：Simple-Mix + L_perturb
├── step4_simple_mix_interp.sh             # 步骤4-3：Simple-Mix + L_interp
├── step4_simple_mix_both.sh               # 步骤4-4：Simple-Mix + Both
├── step5_oracle_full.sh                   # 步骤5：Oracle（全部数据，性能上界）
├── step6_evaluate_*.sh                    # 步骤6：评估脚本
└── README.md                              # 本文件
```

## 🚀 快速开始

### 准备工作

1. **修改配置路径**：编辑所有 `.sh` 脚本中的以下两行：
```bash
ROOT_PATH="/home/wxc/nuist-lab/CcGAN-AVAR-OOD"  # 修改为你的项目路径
DATA_PATH="/home/wxc/datasets"                   # 修改为你的数据集路径
```

2. **确保数据集存在**：
```bash
${DATA_PATH}/UTKFace_64x64.h5
```

3. **启动Visdom服务器**（可选，用于实时监控训练）：
```bash
cd experiments/RC64  # 使用RC64中的启动脚本
bash start_visdom.sh  # 选择1启动screen模式
```

---

## 📝 实验流程

### 步骤1：训练辅助回归模型（必须！）

**目的**：训练一个ResNet18回归网络，用于辅助判别器学习年龄信息。

**训练范围**：1-60岁全部数据（确保覆盖完整范围）

```bash
bash experiments/UK64/step1_train_aux_regression.sh
```

**预期输出**：
- 模型保存在：`output/UTKFace_64/aux_reg_model/ckpt_resnet18_epoch_200.pth`
- 训练日志：`experiments/UK64/output_step1_aux_regression.txt`
- **训练时间**：约1-2小时（取决于GPU）

---

### 步骤2：准备混合数据集（可选）

**目的**：创建混合训练集（ID区域全部 + OOD区域少量）

**数据划分**：
- **ID区域（1-30岁）**：全部训练数据
- **OOD区域（30-60岁）**：每个年龄5张

```bash
bash experiments/UK64/step2_prepare_data.sh
```

**预期输出**：
- 混合数据集：`experiments/data/UTKFace_mixed_id_full_ood_5_64x64.h5`
- **注意**：步骤4的脚本会自动使用这个混合数据集

---

### 步骤3：Baseline - 仅ID区域训练

**目的**：验证OOD问题的存在

**训练范围**：1-30岁

**OOD正则化**：无（`lambda_perturb=0`, `lambda_interp=0`）

```bash
# 修改GPU编号（如需要）
export CUDA_VISIBLE_DEVICES=0

bash experiments/UK64/step3_baseline_id_only.sh
```

**预期结果**：
- 1-30岁生成效果好
- 30-60岁生成效果差（验证OOD问题）
- **训练时间**：约10-15小时

---

### 步骤4：Simple-Mix实验（4个对比实验）

**目的**：测试OOD正则化的有效性

**训练数据**：混合数据集（ID全部 + OOD少量）

#### 4-1：Simple-Mix Baseline（无正则化）

```bash
bash experiments/UK64/step4_simple_mix_baseline.sh
```

- **lambda_perturb**: 0
- **lambda_interp**: 0

#### 4-2：Simple-Mix + L_perturb（仅条件扰动）

```bash
bash experiments/UK64/step4_simple_mix_perturb.sh
```

- **lambda_perturb**: 0.01
- **lambda_interp**: 0

#### 4-3：Simple-Mix + L_interp（仅插值一致性）

```bash
bash experiments/UK64/step4_simple_mix_interp.sh
```

- **lambda_perturb**: 0
- **lambda_interp**: 0.005

#### 4-4：Simple-Mix + Both（两个正则都用）

```bash
bash experiments/UK64/step4_simple_mix_both.sh
```

- **lambda_perturb**: 0.01
- **lambda_interp**: 0.005

**可以同时运行多个实验**（使用不同GPU）：
```bash
# Terminal 1
export CUDA_VISIBLE_DEVICES=0
bash experiments/UK64/step4_simple_mix_baseline.sh

# Terminal 2
export CUDA_VISIBLE_DEVICES=1
bash experiments/UK64/step4_simple_mix_perturb.sh

# Terminal 3
export CUDA_VISIBLE_DEVICES=2
bash experiments/UK64/step4_simple_mix_interp.sh

# Terminal 4
export CUDA_VISIBLE_DEVICES=3
bash experiments/UK64/step4_simple_mix_both.sh
```

---

### 步骤5：Oracle - 全部数据训练（性能上界）

**目的**：获得性能上界，用于对比

**训练范围**：1-60岁全部数据

```bash
bash experiments/UK64/step5_oracle_full.sh
```

---

### 步骤6：评估

**评估所有实验**（在1-60岁全范围上）：

```bash
# 评估Baseline
bash experiments/UK64/step6_evaluate_baseline.sh

# 评估Simple-Mix实验
bash experiments/UK64/step6_evaluate_simple_mix_baseline.sh
bash experiments/UK64/step6_evaluate_simple_mix_perturb.sh
bash experiments/UK64/step6_evaluate_simple_mix_interp.sh
bash experiments/UK64/step6_evaluate_simple_mix_both.sh

# 评估Oracle
bash experiments/UK64/step6_evaluate_oracle.sh
```

**评估结果保存在**：
```
output/UTKFace_64/${SETTING}/eval_results/
├── fid_ls_entropy_over_centers.npz  # ID/OOD区间的FID、LS等指标
└── fake_data/                        # 生成的图像
```

---

## 📊 实验对比

| 实验名称 | 训练数据 | L_perturb | L_interp | 目的 |
|---------|---------|-----------|----------|------|
| **baseline_id_only** | 1-30岁 | ✗ | ✗ | 验证OOD问题 |
| **simple_mix_baseline** | 混合数据 | ✗ | ✗ | 简单混合基线 |
| **simple_mix_perturb** | 混合数据 | ✓ | ✗ | 测试L_perturb |
| **simple_mix_interp** | 混合数据 | ✗ | ✓ | 测试L_interp |
| **simple_mix_both** | 混合数据 | ✓ | ✓ | 测试组合效果 |
| **oracle_full** | 1-60岁全部 | ✗ | ✗ | 性能上界 |

**关键对比**：
1. **Baseline vs Simple-Mix Baseline**：验证简单混合少量OOD数据的效果
2. **Simple-Mix Baseline vs Simple-Mix + 正则化**：验证OOD正则化的有效性
3. **All vs Oracle**：与性能上界对比，看还有多少提升空间

---

## ⚙️ 超参数说明

### 数据划分
- **ID区域**：1-30岁（一半）
- **OOD区域**：30-60岁（一半）
- **OOD Few-shot**：每个年龄5张

### OOD正则化
- **sigma_y**: 0.04（标签扰动标准差）
- **lambda_perturb**: 0.01（条件扰动一致性权重）
- **lambda_interp**: 0.005（插值一致性权重）

### 训练配置
- **训练迭代数**：30000
- **Batch Size**：64（G和D）
- **学习率**：1e-4（G和D）
- **Vicinal类型**：hybrid（HAV）
- **min_n_per_vic**: 400

---

## 🔧 常见问题

### Q1: GPU内存不足怎么办？

**A**: 减小batch size：
```bash
# 在脚本中修改
BATCH_SIZE_G=32  # 原来是64
BATCH_SIZE_D=32
```

### Q2: 训练出现NaN怎么办？

**A**: 降低OOD正则化权重：
```bash
SIGMA_Y=0.02          # 原来0.04
LAMBDA_PERTURB=0.005  # 原来0.01
LAMBDA_INTERP=0.002   # 原来0.005
```

### Q3: 如何恢复训练？

**A**: 修改 `RESUME_ITER`：
```bash
RESUME_ITER=10000  # 从第10000次迭代恢复
```

### Q4: Visdom面板不显示？

**A**: 检查端口配置：
```bash
# 1. 确认Visdom服务器端口
ps aux | grep visdom

# 2. 确保脚本中的端口一致
--visdom_port 8098  # 修改为你的端口
```

### Q5: 如何同时运行多个实验？

**A**: 使用不同的GPU和visdom_env：
```bash
# 实验1
export CUDA_VISIBLE_DEVICES=0
# 脚本中 VISDOM_ENV="simple_mix_baseline"

# 实验2
export CUDA_VISIBLE_DEVICES=1
# 脚本中 VISDOM_ENV="simple_mix_perturb"
```

---

## 📈 预期结果

### 预期改善（相比Baseline）：
1. **FID** ↓（图像质量提升）
2. **Label Score** ↑（年龄预测准确度提升）
3. **OOD区域效果** ↑（30-60岁生成质量提升）

### 重点观察：
- **OOD区域（30-60岁）**：正则化方法应该显著改善生成质量
- **ID区域（1-30岁）**：不应该显著下降（证明正则化没有伤害ID性能）

---

## 📞 技术支持

遇到问题请查看：
1. 训练日志：`experiments/UK64/output_*.txt`
2. Visdom监控：`http://localhost:8098`（需要SSH端口转发）
3. 代码注释：`trainer.py` 中的OOD正则化实现

---

## 🎯 下一步

完成UTKFace实验后，可以：
1. **对比RC-49和UTKFace结果**：验证方法的通用性
2. **调整超参数**：探索最优配置
3. **可视化生成结果**：对比不同方法的生成图像
4. **撰写论文**：总结实验结果

祝实验顺利！🚀

