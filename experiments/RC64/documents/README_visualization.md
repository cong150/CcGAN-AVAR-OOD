# 评估结果可视化指南

## 📊 功能说明

本目录提供了评估结果的可视化工具，用于分析ID区域和OOD区域的性能差异。

### 可视化内容

`fid_ls_entropy_over_centers.npz` 文件包含以下数据：

| 键名 | 说明 | 形状 | 用途 |
|------|------|------|------|
| `centers` | 标签中心位置 | (N,) | X轴坐标 |
| `fids` | 每个中心的FID值 | (N,) | 图像质量（越低越好）✅ 可视化 |
| `labelscores` | 每个中心的Label Score | (N,) | 标签一致性（越低越好）✅ 可视化 |
| `entropies` | 每个中心的Entropy | (N,) | 生成多样性（适中最好）✅ 可视化 |
| `nrealimgs` | 每个中心的真实图像数量 | (N,) | 数据统计信息（可选） |

**注意**：
- 当前可视化脚本只显示 FID、Label Score、Entropy 这3个主要指标
- 评估代码还会计算整体FID、整体LS、IS(Inception Score)等指标，但这些指标没有保存到npz文件中
- 如需查看npz文件详细内容，可以使用：`python experiments/RC64/inspect_npz.py <npz文件路径>`

### 可视化特点

- ✅ 区分ID区域和OOD区域（用不同颜色）
- ✅ 显示ID/OOD边界线
- ✅ 计算并显示平均指标
- ✅ 支持单实验可视化和多实验对比

---

## 🚀 快速开始

### 方法1：使用便捷脚本（推荐）

#### 可视化单个实验

```bash
# 可视化 simple_mix_baseline 实验
bash experiments/RC64/visualize_eval.sh simple_mix_baseline

# 可视化其他实验
bash experiments/RC64/visualize_eval.sh baseline_id_only
bash experiments/RC64/visualize_eval.sh simple_mix_perturb
bash experiments/RC64/visualize_eval.sh oracle_full
```

**输出位置**：
- 图片保存在：`output/RC-49_64/${SETTING}/eval_*/eval_visualization.png`

#### 对比多个实验

```bash
# 对比3个实验
bash experiments/RC64/visualize_compare.sh baseline_id_only simple_mix_baseline oracle_full

# 对比所有消融实验
bash experiments/RC64/visualize_compare.sh \
    simple_mix_baseline \
    simple_mix_perturb \
    simple_mix_interp \
    simple_mix_both
```

**输出位置**：
- 对比图保存在：`experiments/RC64/eval_comparison.png`

---

### 方法2：直接使用Python脚本

#### 可视化单个实验

```bash
python experiments/RC64/visualize_eval_results.py \
    --npz_path /home/wxc/nuist-lab/CcGAN-AVAR-OOD/output/RC-49_64/simple_mix_baseline/eval_2025-11-21_10-30-27/fid_ls_entropy_over_centers.npz \
    --output_path ./visualization.png \
    --id_min 0 \
    --id_max 45 \
    --ood_min 45 \
    --ood_max 90 \
    --experiment_name "Simple-Mix Baseline"
```

#### 对比多个实验

```bash
python experiments/RC64/visualize_eval_results.py \
    --compare \
        /home/wxc/nuist-lab/CcGAN-AVAR-OOD/output/RC-49_64/baseline_id_only/eval_2025-11-21_10-30-27 \
        /home/wxc/nuist-lab/CcGAN-AVAR-OOD/output/RC-49_64/simple_mix_baseline/eval_2025-11-21_10-30-27 \
        /home/wxc/nuist-lab/CcGAN-AVAR-OOD/output/RC-49_64/oracle_full/eval_2025-11-21_10-30-27 \
    --output_path ./comparison.png \
    --id_min 0 \
    --id_max 45 \
    --ood_min 45 \
    --ood_max 90
```

---

## 📋 参数说明

### Python脚本参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--npz_path` | fid_ls_entropy_over_centers.npz文件路径 | **必需** |
| `--output_path` | 输出图片路径 | 自动生成 |
| `--id_min` | ID区域最小标签 | 0.0 |
| `--id_max` | ID区域最大标签 | 45.0 |
| `--ood_min` | OOD区域最小标签 | 45.0 |
| `--ood_max` | OOD区域最大标签 | 90.0 |
| `--experiment_name` | 实验名称（用于图表标题） | 从路径推断 |
| `--compare` | 对比模式：提供多个eval目录路径 | None |

---

## 📊 输出说明

### 单实验可视化

生成一个包含3个子图的图片：
1. **FID曲线**：显示ID和OOD区域的FID变化
2. **Label Score曲线**：显示ID和OOD区域的标签预测准确度
3. **Entropy曲线**：显示ID和OOD区域的生成多样性

每个子图包含：
- ID区域（蓝色）和OOD区域（红色）的曲线
- ID/OOD边界线（灰色虚线）
- 平均指标标注

### 对比可视化

生成一个包含3个子图的对比图：
- 所有实验的FID曲线对比
- 所有实验的Label Score曲线对比
- 所有实验的Entropy曲线对比

---

## 💡 使用示例

### 示例1：查看Simple-Mix Baseline结果

```bash
cd /home/wxc/nuist-lab/CcGAN-AVAR-OOD
bash experiments/RC64/visualize_eval.sh simple_mix_baseline
```

**输出**：
- 图片：`output/RC-49_64/simple_mix_baseline/eval_*/eval_visualization.png`
- 控制台会显示统计摘要（平均FID、LS、Entropy）

### 示例2：对比所有消融实验

```bash
bash experiments/RC64/visualize_compare.sh \
    simple_mix_baseline \
    simple_mix_perturb \
    simple_mix_interp \
    simple_mix_both
```

**输出**：
- 对比图：`experiments/RC64/eval_comparison.png`
- 可以看到不同正则化方法的效果对比

### 示例3：对比Baseline、Simple-Mix、Oracle

```bash
bash experiments/RC64/visualize_compare.sh \
    baseline_id_only \
    simple_mix_baseline \
    oracle_full
```

**输出**：
- 可以看到从Baseline到Oracle的性能提升趋势

---

## 🔍 如何查看图片

### 方法1：使用scp下载到本地

```bash
# 在本地电脑上运行
scp user@server:/home/wxc/nuist-lab/CcGAN-AVAR-OOD/output/RC-49_64/simple_mix_baseline/eval_*/eval_visualization.png ./
```

### 方法2：使用X11转发（如果服务器支持）

```bash
# SSH连接时启用X11转发
ssh -X user@server

# 然后运行可视化脚本，图片会自动显示
bash experiments/RC64/visualize_eval.sh simple_mix_baseline
```

### 方法3：使用Jupyter Notebook

```python
from IPython.display import Image, display
display(Image('output/RC-49_64/simple_mix_baseline/eval_*/eval_visualization.png'))
```

---

## ⚠️ 常见问题

### Q1: 找不到npz文件？

**A**: 确保已经运行过评估脚本：
```bash
bash experiments/RC64/step6_evaluate_ood-1.sh
```

### Q2: 图片显示乱码？

**A**: 可能是中文字体问题，可以修改脚本中的字体设置，或使用英文标签。

### Q3: 想修改ID/OOD区域划分？

**A**: 使用参数：
```bash
python experiments/RC64/visualize_eval_results.py \
    --npz_path ... \
    --id_min 0 --id_max 30 \
    --ood_min 30 --ood_max 60
```

### Q4: 想对比更多实验？

**A**: 在 `visualize_compare.sh` 中添加更多实验名称：
```bash
bash experiments/RC64/visualize_compare.sh exp1 exp2 exp3 exp4 exp5
```

---

## 📝 文件说明

- `visualize_eval_results.py`: 核心可视化Python脚本
- `visualize_eval.sh`: 单实验可视化便捷脚本
- `visualize_compare.sh`: 多实验对比便捷脚本
- `README_visualization.md`: 本说明文档

---

## 🎯 下一步

1. 运行评估脚本生成数据
2. 使用可视化脚本查看结果
3. 对比不同实验的性能
4. 分析ID vs OOD区域的性能差异

祝实验顺利！🚀



