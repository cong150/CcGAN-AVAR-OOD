# Visdom 快速操作指南

## 🚀 5分钟快速开始

### 在服务器上执行以下命令：

```bash
# 1. 进入项目目录
cd ~/nuist-lab/CcGAN-AVAR-OOD

# 2. 检查 Visdom 配置（推荐先运行）
bash experiments/check_visdom.sh

# 3. 安装 Visdom（如果未安装）
pip install visdom

# 4. 启动 Visdom 服务器
bash experiments/start_visdom.sh
# 或者手动启动：
screen -S visdom
python -m visdom.server
# 按 Ctrl+A, 然后按 D 退出

# 5. 启动训练
bash experiments/step4_simple_mix-1.sh
```

### 在本地电脑：

```bash
# 1. SSH 连接服务器时添加端口转发
ssh -L 8097:localhost:8097 wxc@你的服务器地址

# 2. 打开浏览器访问
http://localhost:8097

# 3. 在 Visdom 界面左上角选择环境
# 环境名称就是你的 SETTING，例如：simple_mix_baseline
```

---

## 📋 详细步骤

### 步骤1：检查环境

在服务器上运行诊断脚本：

```bash
bash experiments/check_visdom.sh
```

这会检查：
- ✓ Visdom 是否安装
- ✓ Visdom 服务器是否运行
- ✓ 端口是否监听
- ✓ 脚本配置是否正确

---

### 步骤2：安装 Visdom（如果需要）

如果检查发现 Visdom 未安装：

```bash
# 使用 pip 安装
pip install visdom

# 验证安装
python -c "import visdom; print('OK')"
```

---

### 步骤3：启动 Visdom 服务器

#### 方法A：使用启动脚本（推荐）

```bash
bash experiments/start_visdom.sh
```

然后按提示选择启动方式（推荐选择1）。

#### 方法B：手动使用 screen（推荐）

```bash
# 创建 screen 会话
screen -S visdom

# 启动 Visdom
python -m visdom.server

# 看到 "It's Alive!" 后，按 Ctrl+A, 然后按 D 退出
# 服务器会继续在后台运行

# 重新连接到 screen（如果需要）
screen -r visdom

# 停止 Visdom
screen -X -S visdom quit
```

#### 方法C：使用 nohup（后台运行）

```bash
# 启动
nohup python -m visdom.server > ~/visdom.log 2>&1 &

# 查看日志
tail -f ~/visdom.log

# 查看进程
ps aux | grep visdom

# 停止
kill $(ps aux | grep "[p]ython -m visdom.server" | awk '{print $2}')
```

---

### 步骤4：配置 SSH 端口转发

**这一步非常重要！** 远程服务器需要端口转发才能在本地访问 Visdom。

#### 方法A：SSH 命令行（每次连接时使用）

```bash
# 在你的本地电脑运行：
ssh -L 8097:localhost:8097 wxc@192.168.1.100

# 如果使用其他端口：
ssh -L 8098:localhost:8098 wxc@192.168.1.100
```

#### 方法B：配置 SSH config（永久配置，推荐）

编辑 `~/.ssh/config`（在你的**本地电脑**）：

```
Host nuist-server
    HostName 你的服务器IP
    User wxc
    Port 22
    LocalForward 8097 localhost:8097
```

之后连接时只需：

```bash
ssh nuist-server
```

端口转发会自动生效。

#### 方法C：VS Code 端口转发（如果使用 VS Code）

1. 连接到远程服务器
2. 按 `Ctrl+Shift+P` (或 `Cmd+Shift+P`)
3. 输入 "Forward a Port"
4. 输入端口号：`8097`
5. 回车

---

### 步骤5：访问 Visdom 界面

打开浏览器，访问：

```
http://localhost:8097
```

你应该看到 Visdom 的界面，左上角有 "Environment" 下拉框。

---

### 步骤6：启动训练

```bash
cd ~/nuist-lab/CcGAN-AVAR-OOD
bash experiments/step4_simple_mix-1.sh
```

训练开始后，你会在终端看到：

```
[Visdom] Connected: server=http://localhost port=8097 env='simple_mix_baseline'
```

---

### 步骤7：查看实时图表

在 Visdom 界面：

1. **选择环境**：左上角 "Environment" 下拉框 → 选择 `simple_mix_baseline`
2. **查看图表**：你会看到3个窗口：
   - **D_loss**：判别器损失（D_adv, D_reg, D_dre）
   - **G_loss**：生成器损失（G_adv, G_reg, G_dre）
   - **OOD_regularization**：OOD正则项（L_perturb, L_interp）

3. **图表会自动更新**：每 20 个 iteration 更新一次

---

## 🐛 常见问题

### Q1: 浏览器显示 "无法访问此网站"

**原因**：端口转发没有配置

**解决**：
```bash
# 重新连接 SSH，加上端口转发
ssh -L 8097:localhost:8097 wxc@服务器地址
```

---

### Q2: Visdom 页面空白，没有图表

**原因1**：没有选择正确的环境

**解决**：左上角 "Environment" 下拉框 → 选择 `simple_mix_baseline`

**原因2**：训练还没开始

**解决**：等待训练运行到第一个日志输出点（通常是第 20 个 iteration）

---

### Q3: 训练日志显示 "Cannot connect to Visdom server"

**完整错误**：
```
[Visdom] WARNING: Cannot connect to Visdom server at http://localhost:8097
```

**原因**：Visdom 服务器没有启动

**解决**：
```bash
# 检查 Visdom 是否运行
ps aux | grep visdom

# 如果没有运行，启动它
screen -S visdom
python -m visdom.server
# Ctrl+A, D
```

---

### Q4: 端口被占用

**错误**：
```
OSError: [Errno 98] Address already in use
```

**解决方案A**：杀死占用端口的进程
```bash
# 找到进程
lsof -i :8097

# 杀死进程
kill -9 <PID>
```

**解决方案B**：使用其他端口
```bash
# 启动 Visdom 在其他端口
python -m visdom.server -port 8098

# 修改训练脚本，添加参数
--visdom_port 8098

# 修改 SSH 端口转发
ssh -L 8098:localhost:8098 wxc@服务器地址
```

---

## 💡 实用技巧

### 技巧1：同时运行多个实验

每个实验使用不同的环境名：

```bash
# 实验1
SETTING="simple_mix_baseline"
--visdom_env "${SETTING}"

# 实验2
SETTING="simple_mix_perturb"
--visdom_env "${SETTING}"
```

在 Visdom 界面切换环境来查看不同实验的结果。

---

### 技巧2：保存图表

在 Visdom 界面：

1. 点击图表右上角的 "💾" 图标
2. 选择 "Save as image"
3. 或者点击 "Download" 按钮下载数据

---

### 技巧3：清除旧数据

如果环境中有过多旧数据：

1. 在 Visdom 界面，选择要清除的环境
2. 点击右上角的 "🗑️" 图标
3. 确认删除

或者在服务器上：

```bash
# 删除所有 Visdom 数据
rm -rf ~/.visdom/

# 重启 Visdom 服务器
screen -X -S visdom quit
screen -S visdom
python -m visdom.server
```

---

### 技巧4：不使用 Visdom 也能训练

如果 Visdom 有问题，可以暂时禁用：

```bash
# 方法1：脚本中注释掉
# --use_visdom \
# --visdom_env "${VISDOM_ENV}" \

# 方法2：从命令行查看损失值
tail -f experiments/output_simple_mix_baseline.txt
```

---

## 📊 查看训练进度

### 通过 Visdom（推荐）

打开 `http://localhost:8097`，实时查看曲线。

### 通过日志文件

```bash
# 实时查看日志
tail -f experiments/output_simple_mix_baseline.txt

# 搜索特定的损失值
grep "Iter.*D loss" experiments/output_simple_mix_baseline.txt | tail -20
```

### 日志格式说明

```
CcGAN,SNGAN,hinge: [Iter 100/30000] [D loss: 0.523/0.142/0.035] [G loss: 1.234/0.089/0.021] [L_perturb: 0.0023] [L_interp: 0.0015] [Time: 123.456]
```

- **D loss**: D_adv / D_reg / D_dre
- **G loss**: G_adv / G_reg / G_dre
- **L_perturb**: 扰动一致性损失
- **L_interp**: 插值一致性损失

---

## 🎯 完整工作流程示例

### 终端1：启动 Visdom

```bash
ssh wxc@服务器地址
cd ~/nuist-lab/CcGAN-AVAR-OOD
bash experiments/check_visdom.sh
bash experiments/start_visdom.sh
# 选择 1 (screen)
```

### 终端2：启动训练

```bash
ssh wxc@服务器地址
cd ~/nuist-lab/CcGAN-AVAR-OOD
bash experiments/step4_simple_mix-1.sh
```

### 本地浏览器

```bash
# 如果还没连接，重新连接并添加端口转发
ssh -L 8097:localhost:8097 wxc@服务器地址

# 打开浏览器
http://localhost:8097
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
- 选择环境后能看到 3 个图表
- 图表会随着训练自动更新

---

## 📚 更多帮助

详细文档：
- `experiments/documents/Visdom配置和使用指南.md`

诊断工具：
- `bash experiments/check_visdom.sh`

启动脚本：
- `bash experiments/start_visdom.sh`

---

**祝训练顺利！** 🎉

