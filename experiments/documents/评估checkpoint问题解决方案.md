# 评估Checkpoint问题解决方案

## 🔍 **问题诊断**

### **你遇到的错误**：

```
FileNotFoundError: [Errno 2] No such file or directory: 
'./evaluation/eval_ckpts/RC49/metrics_64x64/ckpt_AE_epoch_200_seed_2020_CVMode_False.pth'
```

### **为什么会这样？**

```
评估流程分为两个阶段：

阶段1: 生成假图像 ✅
├─ 使用训练好的GAN生成fake_data
├─ 每个角度生成200张图片
└─ 保存到 results/fake_data/h5/

阶段2: 计算评估指标 ❌ (这里失败了!)
├─ FID: 需要预训练的AutoEncoder
├─ Label Score: 需要预训练的ResNet34 (回归)
├─ Diversity: 需要预训练的ResNet34 (回归)
└─ 这些预训练模型的checkpoint不存在！

结果：
- fake_data 生成成功 ✅
- eval_results.txt 没生成 ❌ (因为指标计算失败)
```

---

## 📥 **解决方案1：下载官方评估Checkpoint** ⭐

### **步骤1：下载checkpoint**

原项目README提供了下载链接：

**选择一个下载源**：
- **OneDrive**: https://1drv.ms/u/c/907562db44a4f6b8/EZQMkKev3alAh2gsqWx01zABDdJCLVKWTal-vjc_uwk2vA?e=Bbnu65
- **百度云**: https://pan.baidu.com/s/1wbN5_0CZTe1Ko3KwTWiwIg?pwd=mptb (提取码: mptb)

### **步骤2：解压到正确位置**

```bash
# 1. 下载zip文件后，解压
unzip eval_ckpts.zip

# 2. 确保文件结构正确：
./evaluation/eval_ckpts/
├── RC49/
│   └── metrics_64x64/
│       ├── ckpt_AE_epoch_200_seed_2020_CVMode_False.pth
│       ├── ckpt_PreCNNForEvalGANs_ResNet34_class_epoch_200_seed_2020_classify_49_chair_types_CVMode_False.pth
│       └── ckpt_PreCNNForEvalGANs_ResNet34_regre_epoch_200_seed_2020_CVMode_False.pth
├── UTKFace/
│   └── metrics_64x64/
│       └── ...
└── put ckpts for evaluation models here.txt
```

### **步骤3：重新运行评估**

```bash
# 在项目根目录
cd /home/wxc/nuist-lab/CcGAN-AVAR-OOD

# 重新评估所有实验
bash experiments/eval_all.sh
```

### **预期结果**：

```
✅ 生成fake_data（已经有了）
✅ 计算FID
✅ 计算Label Score (MAE)
✅ 计算Diversity
✅ 生成eval_results.txt

示例输出：
===================================================================================================
Evaluation Results:
===================================================================================================
FID: 42.35
Label Score (MAE): 8.23 degrees
Label Score (Kendall's Tau): 0.87
Diversity: 0.92
...
===================================================================================================
```

---

## 🛠️ **解决方案2：跳过指标计算（临时方案）**

如果你现在不需要定量指标，可以：

### **1. 只查看生成的图像**

```bash
# 已经生成的fake_data
ls output/RC-49_64/baseline_id_only/results/fake_data/h5/
ls output/RC-49_64/simple_mix_5/results/fake_data/h5/
ls output/RC-49_64/oracle_full/results/fake_data/h5/

# 每个目录应该有：
# fake_data_200samples_per_label.h5  (完整数据集)
```

### **2. 使用Python读取生成的图像**

```python
import h5py
import numpy as np
from PIL import Image

# 读取fake_data
f = h5py.File('output/RC-49_64/simple_mix_5/results/fake_data/h5/fake_data_200samples_per_label.h5', 'r')
fake_images = f['fake_images'][:]  # shape: (90000, 3, 64, 64)
fake_labels = f['fake_labels'][:]  # shape: (90000,)

# 查看某个角度的图像
angle = 60.0
mask = (fake_labels >= angle-0.1) & (fake_labels <= angle+0.1)
images_60deg = fake_images[mask]

print(f"60度附近的图像数量: {len(images_60deg)}")

# 保存为图片查看
for i, img in enumerate(images_60deg[:10]):  # 前10张
    img = (img.transpose(1,2,0) * 127.5 + 127.5).astype(np.uint8)
    Image.fromarray(img).save(f'sample_60deg_{i}.png')
```

---

## 📊 **解决方案3：自己训练评估模型（不推荐）**

如果无法下载checkpoint，可以自己训练评估网络：

```bash
# 训练AutoEncoder (FID)
python evaluation/train_ae.py \
    --data_path /home/wxc/datasets \
    --data_name RC-49 \
    --img_size 64 \
    --epochs 200 \
    --seed 2020

# 训练ResNet34分类器 (Class Score)
python evaluation/train_cnn_for_eval.py \
    --data_path /home/wxc/datasets \
    --data_name RC-49 \
    --img_size 64 \
    --net_type class \
    --epochs 200 \
    --seed 2020

# 训练ResNet34回归器 (Label Score)
python evaluation/train_cnn_for_eval.py \
    --data_path /home/wxc/datasets \
    --data_name RC-49 \
    --img_size 64 \
    --net_type regre \
    --epochs 200 \
    --seed 2020
```

⚠️ **注意**：这需要额外的训练时间（约1-2小时）

---

## 🎯 **当前状态总结**

### **你已经完成的工作** ✅

```
1. ✅ 辅助回归模型训练 (Step1)
2. ✅ 混合数据集创建 (Step2)
3. ✅ Baseline实验训练 (Step3) - 30000 iters
4. ✅ Simple-Mix实验训练 (Step4) - 30000 iters
5. ✅ Oracle实验训练 (Step5) - 30000 iters
6. ✅ 生成fake_data (所有实验)
   ├─ baseline_id_only: 179800张图 (450角度x200张，间隔0.2度)
   ├─ simple_mix_5: 90000张图 (450角度x200张，间隔0.2度)
   └─ oracle_full: 179800张图 (899角度x200张，间隔0.1度)
```

### **只差最后一步** ⚠️

```
7. ❌ 计算评估指标 (缺少checkpoint)
   └─ 需要下载/训练评估网络
```

---

## 💡 **推荐做法**

### **如果你需要定量指标（写论文）**：

1. **立即下载checkpoint**（5分钟）
   ```bash
   # 从百度云或OneDrive下载
   # 解压到 ./evaluation/eval_ckpts/
   ```

2. **重新运行评估**
   ```bash
   bash experiments/eval_all.sh
   ```

3. **对比结果**
   ```bash
   # 查看三个实验的Label Score对比
   grep -A 20 "Label Score" output/RC-49_64/*/eval_*/eval_results.txt
   ```

### **如果只是测试/调试**：

1. 直接查看生成的图像
   ```bash
   # fake_data已经生成，可以用Python读取
   ```

2. 暂时跳过指标计算

3. 后续需要时再下载checkpoint评估

---

## 🔧 **验证Checkpoint是否正确**

下载并解压后，运行以下命令验证：

```bash
# 检查文件是否存在
ls -lh evaluation/eval_ckpts/RC49/metrics_64x64/

# 应该看到：
# ckpt_AE_epoch_200_seed_2020_CVMode_False.pth                                (约500MB)
# ckpt_PreCNNForEvalGANs_ResNet34_class_epoch_200_seed_2020_classify_49_chair_types_CVMode_False.pth  (约100MB)
# ckpt_PreCNNForEvalGANs_ResNet34_regre_epoch_200_seed_2020_CVMode_False.pth  (约100MB)
```

---

## 📞 **如果下载遇到问题**

1. **OneDrive无法访问**：尝试百度云
2. **百度云限速**：可以考虑：
   - 使用百度云客户端
   - 或者自己训练评估网络（见解决方案3）

---

## 📝 **总结**

**你的训练完全没问题！** ✅

只是评估脚本在计算指标时需要额外的预训练网络，这些网络不包含在源代码中，需要单独下载。

**核心数据都已经生成了**：
- 训练好的GAN模型 ✅
- 生成的fake_data ✅
- 只差最后的指标计算 ⚠️

**最简单的解决方法**：
1. 下载checkpoint (5分钟)
2. 重新运行 `bash experiments/eval_all.sh`
3. 查看 `eval_results.txt` 中的定量指标

