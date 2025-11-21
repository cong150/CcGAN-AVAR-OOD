# Visdom 配置和使用指南

## 📌 问题：Visdom 面板显示不出来

### 可能的原因
1. ❌ Visdom 没有安装
2. ❌ Visdom 服务器没有启动
3. ❌ 端口配置不匹配
4. ❌ SSH 端口转发没有配置（远程服务器场景）
5. ❌ 防火墙阻止了端口访问

---

## 🔍 步骤1：检查 Visdom 是否安装

在服务器上运行：

```bash
# 方法1：检查是否已安装
python -c "import visdom; print('Visdom version:', visdom.__version__)"

# 方法2：使用 pip 检查
pip show visdom
```

### 如果未安装：

```bash
# 安装 Visdom
pip install visdom

# 或者如果你用 conda
conda install -c conda-forge visdom
```

---

## 🚀 步骤2：启动 Visdom 服务器

### 方法1：默认端口启动（推荐）

```bash
# 在服务器上启动 Visdom 服务器（默认端口 8097）
python -m visdom.server
```

**输出示例**：
```
Checking for scripts.
It's Alive!
INFO:root:Application Started
You can navigate to http://localhost:8097
```

### 方法2：指定端口启动

```bash
# 如果 8097 端口被占用，可以指定其他端口
python -m visdom.server -port 8098
```

### ⚠️ 注意事项

1. **保持 Visdom 服务器运行**：这个命令需要在后台持续运行，训练期间不能关闭
2. **使用 screen 或 tmux**（推荐）：
   ```bash
   # 创建一个新的 screen 会话
   screen -S visdom
   
   # 在 screen 中启动 Visdom
   python -m visdom.server
   
   # 按 Ctrl+A, 然后按 D 来脱离 screen（服务器继续运行）
   
   # 重新连接到 screen
   screen -r visdom
   ```

3. **或者使用 nohup**：
   ```bash
   nohup python -m visdom.server > visdom.log 2>&1 &
   
   # 查看进程
   ps aux | grep visdom
   
   # 停止服务器
   kill <进程ID>
   ```

---

## 🌐 步骤3：配置端口转发（远程服务器必须）

如果你通过 SSH 连接到远程服务器，需要配置端口转发才能在本地浏览器访问 Visdom。

### 方法1：SSH 命令行转发

```bash
# 在你的本地电脑（不是服务器）运行：
ssh -L 8097:localhost:8097 用户名@服务器地址

# 例如：
ssh -L 8097:localhost:8097 wxc@192.168.1.100
```

**说明**：这会将服务器的 8097 端口映射到你本地的 8097 端口

### 方法2：使用 VS Code 的端口转发

如果你用 VS Code Remote SSH：

1. 按 `Ctrl+Shift+P`（或 `Cmd+Shift+P`）
2. 输入 "Forward a Port"
3. 输入端口号：`8097`
4. 点击确认

### 方法3：修改 SSH 配置文件（永久配置）

编辑 `~/.ssh/config`（在你的本地电脑）：

```
Host 你的服务器别名
    HostName 服务器IP地址
    User 用户名
    Port 22
    LocalForward 8097 localhost:8097
```

---

## 🔧 步骤4：检查脚本配置

### 检查 `opts.py` 中的默认配置

```bash
cat opts.py | grep -A 10 "visdom"
```

**应该看到**：
```python
parser.add_argument('--visdom_port', type=int, default=8097,
                    help='Visdom server port (default: 8097)')
```

### 检查训练脚本中的配置

```bash
cat experiments/step4_simple_mix-1.sh | grep -i visdom
```

**应该看到**：
```bash
--use_visdom \
--visdom_env "${VISDOM_ENV}" \
```

### ⚠️ 端口匹配检查

**关键**：确保以下三个地方的端口**完全一致**：

1. **Visdom 服务器启动端口**：
   ```bash
   python -m visdom.server -port 8097  # ← 这里
   ```

2. **训练脚本中的端口**（如果没有指定，使用默认值）：
   ```bash
   python main.py \
       --use_visdom \
       --visdom_port 8097 \  # ← 可以显式指定
       ...
   ```

3. **`opts.py` 中的默认端口**：
   ```python
   parser.add_argument('--visdom_port', type=int, default=8097)
   ```

---

## 🎯 步骤5：完整操作流程

### 在服务器上：

```bash
# 1. 检查 Visdom 是否安装
python -c "import visdom; print('OK')"

# 2. 启动 Visdom 服务器（使用 screen）
screen -S visdom
python -m visdom.server
# 按 Ctrl+A, D 脱离 screen

# 3. 启动训练（在另一个终端）
cd ~/nuist-lab/CcGAN-AVAR-OOD
bash experiments/step4_simple_mix-1.sh
```

### 在本地电脑：

```bash
# 1. 配置 SSH 端口转发（如果还没连接服务器）
ssh -L 8097:localhost:8097 wxc@服务器地址

# 2. 打开浏览器访问
# 在浏览器地址栏输入：
http://localhost:8097
```

---

## 📊 步骤6：查看 Visdom 面板

### 访问 Visdom

打开浏览器，访问：`http://localhost:8097`

你应该看到 Visdom 的界面，左侧有环境列表。

### 切换到你的实验环境

在左上角的 "Environment" 下拉框中，选择你的环境名称，例如：
- `simple_mix_baseline`
- `simple_mix_perturb`
- `simple_mix_interp`

### 应该看到的图表

训练开始后，你会看到3个窗口：

1. **D_loss**：判别器损失
   - D_adv（对抗损失）
   - D_reg（辅助回归损失）
   - D_dre（密度比估计损失）

2. **G_loss**：生成器损失
   - G_adv（对抗损失）
   - G_reg（辅助回归损失）
   - G_dre（密度比估计损失）

3. **OOD_regularization**：OOD 增强正则项
   - L_perturb（扰动一致性损失）
   - L_interp（插值一致性损失）

---

## 🐛 常见问题排查

### 问题1：浏览器显示"无法访问此网站"

**原因**：端口转发没有配置或配置错误

**解决方案**：
```bash
# 在本地电脑重新建立 SSH 连接，加上端口转发
ssh -L 8097:localhost:8097 用户名@服务器地址

# 确认端口转发是否生效
# 在本地电脑运行：
netstat -an | grep 8097  # Linux/Mac
netstat -ano | findstr "8097"  # Windows
```

### 问题2：Visdom 页面空白，没有图表

**原因1**：训练还没开始或还没到第一个打印点

**解决方案**：等待训练运行到第一个日志输出（通常是 20 个 iteration）

**原因2**：环境名称选择错误

**解决方案**：
- 检查训练脚本中的 `VISDOM_ENV` 变量
- 在 Visdom 界面左上角选择对应的环境

**原因3**：训练脚本中没有传递 `--use_visdom`

**解决方案**：
```bash
# 确认脚本中有这一行
cat experiments/step4_simple_mix-1.sh | grep "use_visdom"

# 应该输出：
--use_visdom \
```

### 问题3：训练日志中出现 Visdom 警告

**日志示例**：
```
[Visdom] WARNING: Cannot connect to Visdom server at http://localhost:8097 (env='simple_mix_baseline'). Disable Visdom.
```

**原因**：Visdom 服务器没有启动或端口不对

**解决方案**：
```bash
# 1. 检查 Visdom 服务器是否在运行
ps aux | grep visdom

# 2. 如果没有运行，启动它
screen -S visdom
python -m visdom.server

# 3. 确认端口
# 服务器启动时会显示：
# You can navigate to http://localhost:8097
```

### 问题4：端口被占用

**日志示例**：
```
OSError: [Errno 98] Address already in use
```

**解决方案**：
```bash
# 方法1：找到并杀死占用端口的进程
lsof -i :8097  # 查看哪个进程占用了 8097
kill -9 <PID>  # 杀死进程

# 方法2：换一个端口
python -m visdom.server -port 8098

# 然后修改训练脚本，添加：
--visdom_port 8098
```

---

## 📝 推荐的工作流程

### 方案A：使用 screen（推荐）

```bash
# 终端1：启动 Visdom
screen -S visdom
python -m visdom.server
# Ctrl+A, D

# 终端2：启动训练
cd ~/nuist-lab/CcGAN-AVAR-OOD
bash experiments/step4_simple_mix-1.sh

# 本地浏览器：访问 http://localhost:8097
```

### 方案B：使用后台进程

```bash
# 启动 Visdom（后台）
nohup python -m visdom.server > ~/visdom.log 2>&1 &

# 启动训练
cd ~/nuist-lab/CcGAN-AVAR-OOD
bash experiments/step4_simple_mix-1.sh

# 查看 Visdom 日志
tail -f ~/visdom.log

# 本地浏览器：访问 http://localhost:8097
```

---

## 🔍 快速诊断命令

在服务器上依次运行这些命令，检查每一步：

```bash
# 1. 检查 Visdom 是否安装
python -c "import visdom; print('✓ Visdom installed')" || echo "✗ Visdom NOT installed"

# 2. 检查 Visdom 服务器是否运行
ps aux | grep "visdom.server" | grep -v grep && echo "✓ Visdom server running" || echo "✗ Visdom server NOT running"

# 3. 检查端口是否监听
netstat -tuln | grep 8097 && echo "✓ Port 8097 listening" || echo "✗ Port 8097 NOT listening"

# 4. 检查训练脚本配置
grep -E "use_visdom|visdom_env" experiments/step4_simple_mix-1.sh && echo "✓ Script configured" || echo "✗ Script NOT configured"
```

---

## 💡 如果 Visdom 仍然不工作

### 临时禁用 Visdom

如果你急着训练，可以暂时禁用 Visdom：

```bash
# 方法1：修改脚本，删除或注释掉这两行
# --use_visdom \
# --visdom_env "${VISDOM_ENV}" \

# 方法2：训练仍然会正常进行，只是没有实时图表
# 你可以通过日志文件查看损失值：
tail -f experiments/output_simple_mix_baseline.txt
```

### 训练日志中的损失值

即使没有 Visdom，你仍然可以从日志中看到详细的损失值：

```
CcGAN,SNGAN,hinge: [Iter 100/30000] [D loss: 0.523/0.142/0.035] [G loss: 1.234/0.089/0.021] [L_perturb: 0.0023] [L_interp: 0.0015] [Time: 123.456]
```

格式说明：
- **D loss**: D_adv / D_reg / D_dre
- **G loss**: G_adv / G_reg / G_dre
- **L_perturb**: 扰动一致性损失
- **L_interp**: 插值一致性损失

---

## ✅ 检查清单

训练前，确保以下所有项目都打勾：

- [ ] Visdom 已安装（`python -c "import visdom"`）
- [ ] Visdom 服务器已启动（`ps aux | grep visdom`）
- [ ] 端口转发已配置（本地访问 `http://localhost:8097` 能看到 Visdom 界面）
- [ ] 训练脚本中有 `--use_visdom` 参数
- [ ] 训练脚本中的 `--visdom_port` 与服务器端口一致
- [ ] 训练开始后，在 Visdom 界面选择了正确的环境名称

---

## 🎉 成功的标志

如果一切正常，你应该看到：

1. **服务器端**：
   ```
   [Visdom] Connected: server=http://localhost port=8097 env='simple_mix_baseline'
   CcGAN,SNGAN,hinge: [Iter 20/30000] [D loss: ...] [G loss: ...] [L_perturb: ...] [L_interp: ...] [Time: ...]
   ```

2. **浏览器端**：
   - Visdom 界面打开正常
   - 左上角环境列表中有 `simple_mix_baseline`
   - 选择环境后，能看到 3 个实时更新的图表

3. **图表更新**：
   - 曲线随着训练进行不断延长
   - 横轴是 iteration，纵轴是 loss 值

---

**祝训练顺利！** 🚀

