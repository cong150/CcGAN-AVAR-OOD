# 问题解答：Visdom 面板显示不出来

## 问题描述

你在训练和评估时 Visdom 面板都显示不出来。

---

## 🎯 快速诊断

### 在服务器上运行以下命令：

```bash
cd ~/nuist-lab/CcGAN-AVAR-OOD

# 1. 运行诊断脚本
bash experiments/check_visdom.sh
```

这个脚本会检查：
- ✓ Visdom 是否安装
- ✓ Visdom 服务器是否运行
- ✓ 端口是否监听
- ✓ 脚本配置是否正确

根据诊断结果，按照提示进行修复。

---

## 📋 最可能的原因和解决方案

### 原因1：Visdom 未安装（最常见）

**检查**：
```bash
python -c "import visdom; print('已安装')"
```

**如果报错**：
```bash
pip install visdom
```

---

### 原因2：Visdom 服务器未启动（最常见）

**检查**：
```bash
ps aux | grep visdom
```

**如果没有输出，说明服务器未启动**：

```bash
# 方法A：使用启动脚本（推荐）
bash experiments/start_visdom.sh

# 方法B：手动启动
screen -S visdom
python -m visdom.server
# 按 Ctrl+A, 然后按 D 退出
```

---

### 原因3：SSH 端口转发未配置（远程服务器必需）

如果你通过 SSH 连接到远程服务器，**必须**配置端口转发才能在本地浏览器访问。

**在你的本地电脑（不是服务器）运行**：

```bash
# 重新连接服务器，添加端口转发
ssh -L 8097:localhost:8097 wxc@你的服务器IP地址
```

然后在本地浏览器访问：`http://localhost:8097`

---

### 原因4：评估脚本不需要 Visdom

**重要**：评估脚本（`step6_evaluate_ood-*.sh`）**不会显示 Visdom**，因为评估时不需要实时监控。

✅ **训练脚本**（`step4_simple_mix-*.sh`）有 Visdom 配置：
```bash
--use_visdom \
--visdom_env "${VISDOM_ENV}" \
```

❌ **评估脚本**（`step6_evaluate_ood-*.sh`）没有 Visdom 配置，这是正常的。

**只有训练时才需要 Visdom！**

---

## ✅ 完整操作步骤

### 步骤1：安装 Visdom

在服务器上：
```bash
pip install visdom
python -c "import visdom; print('OK')"
```

---

### 步骤2：启动 Visdom 服务器

在服务器上：
```bash
cd ~/nuist-lab/CcGAN-AVAR-OOD

# 使用启动脚本
bash experiments/start_visdom.sh
# 选择 1 (使用 screen)

# 或者手动启动
screen -S visdom
python -m visdom.server
# 看到 "It's Alive!" 后，按 Ctrl+A, D 退出
```

验证服务器已启动：
```bash
ps aux | grep visdom
# 应该看到：python -m visdom.server
```

---

### 步骤3：配置 SSH 端口转发

**在你的本地电脑运行**（不是服务器）：

```bash
# 重新连接服务器，添加端口转发
ssh -L 8097:localhost:8097 wxc@你的服务器地址

# 例如：
ssh -L 8097:localhost:8097 wxc@192.168.1.100
```

---

### 步骤4：访问 Visdom 界面

在本地浏览器打开：
```
http://localhost:8097
```

你应该看到 Visdom 的界面（一个空白页面，左上角有 "Environment" 下拉框）。

---

### 步骤5：启动训练

在服务器上：
```bash
cd ~/nuist-lab/CcGAN-AVAR-OOD
bash experiments/step4_simple_mix-1.sh
```

训练开始后，你会在终端看到：
```
[Visdom] Connected: server=http://localhost port=8097 env='simple_mix_baseline'
```

---

### 步骤6：查看图表

在 Visdom 界面：
1. 左上角 "Environment" 下拉框 → 选择 `simple_mix_baseline`
2. 你会看到3个图表开始出现并实时更新

---

## 🐛 故障排查

### 问题A：浏览器显示 "无法访问此网站"

**原因**：端口转发没配置或配置错误

**解决**：
1. 确保在**本地电脑**（不是服务器）运行了 SSH 端口转发命令
2. 检查端口转发是否生效：
   ```bash
   # Windows (PowerShell)
   netstat -ano | findstr "8097"
   
   # Linux/Mac
   netstat -an | grep 8097
   ```
3. 如果看不到输出，说明端口转发没有生效，重新连接 SSH

---

### 问题B：Visdom 页面空白，没有图表

**原因1**：训练还没开始
- 等待训练运行到第一个日志输出点（通常是第 20 个 iteration）

**原因2**：环境名称选择错误
- 左上角 "Environment" 下拉框 → 选择 `simple_mix_baseline`

**原因3**：你在运行评估脚本
- 评估时不会有 Visdom 输出，这是正常的
- 只有**训练脚本**才会有 Visdom 输出

---

### 问题C：训练日志显示 "Cannot connect to Visdom server"

**完整错误**：
```
[Visdom] WARNING: Cannot connect to Visdom server at http://localhost:8097
```

**原因**：Visdom 服务器没有启动

**解决**：
```bash
# 检查服务器是否运行
ps aux | grep visdom

# 如果没有，启动它
bash experiments/start_visdom.sh
```

---

### 问题D：端口被占用

**错误**：
```
OSError: [Errno 98] Address already in use
```

**解决**：
```bash
# 找到占用端口的进程
lsof -i :8097

# 杀死进程
kill -9 <PID>

# 重新启动 Visdom
bash experiments/start_visdom.sh
```

---

## 💡 重要提示

### 1. 评估时不需要 Visdom

**评估脚本**（`step6_evaluate_ood-*.sh`）**不会显示 Visdom**。

这是因为：
- 评估是一次性的，不需要实时监控
- 评估结果会保存在文件中：`output/RC-49_64/<SETTING>/eval_*/eval_results.txt`

**只有训练时才需要 Visdom！**

---

### 2. Visdom 是可选的

即使 Visdom 不工作，训练也能正常进行。

你可以通过日志文件查看训练进度：
```bash
tail -f experiments/output_simple_mix_baseline.txt
```

---

### 3. 端口转发是必需的（远程服务器）

如果你通过 SSH 连接到远程服务器，**必须**配置端口转发，否则无法在本地浏览器访问 Visdom。

---

## 📚 详细文档

如果上述方法还不能解决问题，请查看详细文档：

1. **详细配置指南**：
   ```bash
   cat experiments/documents/Visdom配置和使用指南.md
   ```

2. **快速操作指南**：
   ```bash
   cat experiments/documents/Visdom快速操作指南.md
   ```

3. **运行诊断脚本**：
   ```bash
   bash experiments/check_visdom.sh
   ```

---

## ✅ 成功标志

如果一切正常，你应该看到：

### 服务器终端

```
[Visdom] Connected: server=http://localhost port=8097 env='simple_mix_baseline'

CcGAN,SNGAN,hinge: [Iter 20/30000] [D loss: 0.523/0.142/0.035] [G loss: 1.234/0.089/0.021] [L_perturb: 0.0023] [L_interp: 0.0015] [Time: 123.456]
```

### Visdom 界面

- 左上角环境列表中有 `simple_mix_baseline`
- 选择环境后能看到 3 个图表：D_loss, G_loss, OOD_regularization
- 图表会随着训练自动更新

---

## 🎯 总结

**最常见的原因**：

1. ❌ Visdom 未安装 → `pip install visdom`
2. ❌ Visdom 服务器未启动 → `bash experiments/start_visdom.sh`
3. ❌ SSH 端口转发未配置 → `ssh -L 8097:localhost:8097 用户名@服务器地址`
4. ⚠️ 在运行评估脚本（评估时不需要 Visdom）

**按照步骤1-6操作，通常就能解决问题！**

---

**祝训练顺利！** 🚀

