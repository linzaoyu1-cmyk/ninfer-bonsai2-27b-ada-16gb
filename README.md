# NInfer 三元 Bonsai-2-27B · Windows / RTX 4070 Ti SUPER 16GB

在 Windows + Ada 16GB 卡上把三元量化的 Bonsai-2-27B 跑起来：**256K 上下文 · prefill 2000 tok/s · decode 86 tok/s · 带视觉**。

- 从零复现 → **第 2 节**（约 90 分钟）
- 出问题 → **第 5 节**
- 仓库里都有啥 → **第 6 节**

> 本文所有命令都在 **RTX 4070 Ti SUPER 16GB + Windows 11** 上实测通过；其中步骤 1–7、9 在干净目录从零跑过一遍，产出的制品与参考制品 **sha256 逐字节一致**。

---

## 1. 你需要什么

| 项 | 要求 |
|---|---|
| 显卡 | RTX 4070 Ti SUPER **16GB**（本卡实测可跑 **256K 上下文**）；低于 16GB 显存请自行测上下文上限 |
| 系统 | Windows 11 |
| 驱动 | 616.56 或更新（**不需要装 CUDA Toolkit**，运行时已静态链接） |
| 编译工具 | CUDA 13.2 · VS18 BuildTools(MSVC 14.51) · CMake 4.4.3 · Ninja 1.13.2 |
| 磁盘 | **SSD**，约 60 GB 空闲 |
| 内存 | 32 GB 以上 |

> 显存低于 16GB 的显卡，上下文上限请**自己测**，**建议从低开始调**（例如从 65536 起步逐步加倍），观察启动日志的 `capacity` 行；放不下时引擎会直接报还差多少字节。

---

## 2. 从零复现（约 90 分钟）

### 步骤 1 · 下载输入（25 GB，约 20 分钟）

```powershell
aria2c -x8 -s8 -k1M --file-allocation=none `
  "https://hf-mirror.com/Barding-Defense/Qwen3.8-27B-huihui-abliterated-groupwise-int-NInfer/resolve/main/qwen3_8_27b_huihui_abliterated.ninfer" `
  --out=qwen3_8_27b_huihui_abliterated.ninfer

aria2c -x8 -s8 -k1M --file-allocation=none `
  "https://modelscope.cn/models/prism-ml/Ternary-Bonsai-2-27B-gguf/resolve/master/Ternary-Bonsai-2-27B-PQ2_0.gguf" `
  --out=Ternary-Bonsai-2-27B-PQ2_0.gguf
```

✅ **成功的样子**

| 文件 | 字节数 | sha256 |
|---|---:|---|
| 模板 `.ninfer` | 18,210,531,328 | `8c9f9d67a07ac97506978f6db6695d8074f78dec0fb80c4a85a8fb6fbedd7f03` |
| 三元 GGUF | 7,206,168,928 | `3907dc1658db1f78a9826bf8d5bcb8dc65db0d466388937af57f2294fae62ec1` |

### 步骤 2 · 取源码

```powershell
git clone mirror\ninfer-4090-windows-6eb70a07.bundle src\ninfer
```

✅ **成功的样子**：`git -C src\ninfer log -1 --format="%H %s"` 显示
`6eb70a0784b68c87efcbeb0b08bd2c3a95914492  v1.0.8: 5 fork ports ...`

> 原始上游 `Ambolio/ninfer-4090-windows` **已 404**，所以本仓自带 10.5 MB 的 git bundle（含该提交与全部 tag）。

### 步骤 3 · 取指南并 pin

```powershell
git clone https://modelscope.cn/shensanshu/ninfer-ada-ternary.git guide
git -C guide checkout ca845a402866e98fcd468e010cc980f7f4d002a2
```

✅ **成功的样子**：`git -C guide log -1 --format=%H` 显示 `ca845a40…`

> 这是**活仓库**，HEAD 已前进过。**不 pin 就复现不出同一个制品。**

### 步骤 4 · 打补丁

```powershell
git -C src\ninfer apply ..\patches\src-tree.patch
git -C guide      apply ..\patches\pack-py.patch
```

✅ **成功的样子**：`git -C src\ninfer status --porcelain` 输出 **33 行**，且含 `?? src/ops/linear/ternary/`

### 步骤 5 · 装工具链

```powershell
uv python install 3.12
uv venv .venv --python <刚装好的 3.12 路径>

uv pip install --python .venv\Scripts\python.exe --index-url https://mirrors.aliyun.com/pypi/simple `
    cmake==4.4.3 ninja==1.13.2 numpy==2.5.3

uv pip install --python .venv\Scripts\python.exe --index-url https://download.pytorch.org/whl/cpu `
    torch==2.14.0
```

✅ **成功的样子**：`cmake --version` → 4.4.3；`ninja --version` → 1.13.2；`python -c "import torch"` → 2.14.0+cpu

### 步骤 6 · 编译引擎（**必须在交互式终端里跑**，10–25 分钟）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\configure-vision.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-vision.ps1
```

✅ **成功的样子**：先打印 `CONFIGURE_OK`，最后打印 **`NINFER_VISION_BUILD_OK`**；`runtime-vision\` 里出现 3 个 exe + 5 个 DLL

### 步骤 7 · 打包装制品

```powershell
python guide\tools\pack.py `
  --template <步骤1的模板> --gguf <步骤1的GGUF> `
  build models\Ternary-Bonsai-2-27B.ninfer
```

✅ **成功的样子**

```
total file : 8,306,927,628 B = 7.736 GiB
objects    : 1126
sha256     : 05bbbf01090c6f61113b54556daa22ad0b45036a078af6cd6f02a3fde47ad76c
```

**这个 sha256 一致 = 整条流水线复现成功。**

### 步骤 8 · 提速 4.6 倍（移植 prefill 内核）

**方式 A（联网，推荐）**

```powershell
git -c http.sslBackend=openssl clone --depth 1 https://github.com/CraneBW/ninfer-ternary-bonsai-ada.git ref\cranebw

xcopy /E /Y ref\cranebw\src\ops\linear\ternary\* src\ninfer\src\ops\linear\ternary\
copy ref\cranebw\src\ops\wrapper\attn_input_proj.cpp src\ninfer\src\ops\wrapper\
copy ref\cranebw\src\ops\wrapper\gdn_input_proj.cpp  src\ninfer\src\ops\wrapper\

powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-vision.ps1
```

**方式 B（离线，不依赖 CraneBW 仓库）**

```powershell
Push-Location src\ninfer
git apply -p2 ..\..\patches\prefill-port.patch
Pop-Location
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-vision.ps1
```

✅ **成功的样子**：编译通过（实测一次通过、零错误）；prefill 从 ~470 涨到 **~2000 tok/s**

### 步骤 9 · 启动并验收

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File start-server-vision.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\verify-speed.ps1
```

---

## 3. 验收标准

| 项 | 期望值 |
|---|---|
| `capacity` 行 | `KV 252,160 tokens, rk4v4, pages 3,940/3,940, runtime 5.13 GiB` |
| 正确性 | `Paris` / `在标准大气压下，水的沸点是100摄氏度。` |
| prefill（4.9k prompt） | **≥ 1500 tok/s**（旧内核只有 ~470） |
| decode（800 tok） | **≥ 78 tok/s** |
| 显存 | ≈ 14.9 GB / 16.4 GB |

---

## 4. 换配置 / 重来

| 想做什么 | 怎么做 |
|---|---|
| 换 KV 精度 | `.\start-server-vision.ps1 -KvDtype fp8`（可选 `bf16 / int8 / fp8 / rk4v4`） |
| 换上下文长度 | `-MaxContext 252144`（本卡上限 **262144 = 256K**，实测可跑但余量只剩 ~0.9 GB；默认 252144 留约 1 GB） |
| 换投机档位 | `-Spec mtp -DraftTokens 5` |
| 编译坏了重来 | 删掉 `build\`，重跑步骤 6 |
| 全部重来 | 删目录从步骤 1 重来（制品 sha256 会一样） |
| 保留上一版引擎 | 覆盖前 `Copy-Item …exe …exe.prev -Force`，换回就拷回来重启 |

---

## 5. 出问题怎么办

| 现象 | 原因 | 处理 |
|---|---|---|
| clone 报 TLS/schannel 握手失败 | GitHub 直连被拦 | 加 `-c http.sslBackend=openssl` |
| `git apply` 报 `corrupt patch` | 补丁文件不是 CRLF+UTF-8 | 确认编码；别用 `>` 重定向生成补丁 |
| 下载只有 0.3 MB/s | 镜像单连接限速 | aria2 加 `-x8 -s8` |
| pip 403 | 清华镜像拒绝 | 换 aliyun 镜像 |
| 编译报 `crtdefs.h` 找不到 | 在服务/非交互上下文编译，vcvars 没生效 | 到**交互式终端**里编译 |
| 编译报 spdlog `target_compile_features` | 上次失败留下的残缺 CMake 缓存 | 删掉 `build\` 重新 configure |
| `pack.py` 找不到源码 | 脚本里写死了绝对路径 | 用本仓 `pack-py.patch` 后的版本 |
| 闲置一会儿后第一个请求很慢 | WDDM 把空闲显存换出 | 属正常，重发一次即可 |
| 视觉提问返回空 | `max_tokens` 被思考链吃光 | 调大 `max_tokens` 或加 `reasoning_effort:"none"` |
| 引擎启动要 50 秒 | 装在机械硬盘 | 移到 SSD |
| prefill 只有 ~470 | 还在用没移植的旧内核 | 跑步骤 8 |

---

## 6. 仓库里有什么

```
README.md                              本文件
LICENSE                                Apache-2.0 全文
versions.md                            锁定的环境与上游版本
NOTICE                                 上游署名与许可
patches\src-tree.patch                 源码树改动（33 文件 + 新增三元目录）
patches\pack-py.patch                  打包器改动（去掉硬编码路径）
patches\prefill-port.patch             prefill 内核移植（18 文件，-p2 应用）
mirror\ninfer-4090-windows-6eb70a07.bundle   源码树备份（上游已 404）
tools\configure-vision.ps1             配置（视觉版）
tools\build-vision.ps1                 编译
tools\verify-speed.ps1                 一键体检（prefill / decode / 正确性）
tools\launch-detached.ps1              脱离终端启动
tools\stop-server.ps1                  停止服务
start-server-vision.ps1                启动服务（默认 rk4v4 / 252144 / MTP K=3 / --vision）
start-cli.ps1                          命令行单次推理
```

## 署名

见 `NOTICE`。
