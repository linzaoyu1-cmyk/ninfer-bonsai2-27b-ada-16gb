# RESOURCES.md — 复现需要哪些资源、从哪拿、断了怎么办

> 一句话：**只要下表每一样都拿得到，按 README 的步骤就一定能复现。**
> 标 ✅「自带」的已经在这个仓库里了；其余都给了**多个来源**。

## 一、清单

| # | 资源 | 大小 | 主要来源 | 备用来源 | 仓库自带 | 拿不到会怎样 |
|:-:|---|---|---|---|:-:|---|
| 1 | 源码树 `6eb70a07` | 11 MB | 上游 **已 404** | — | ✅ `mirror\ninfer-4090-windows-6eb70a07.bundle` | — |
| 2 | prefill 内核 | 257 KB | `CraneBW/ninfer-ternary-bonsai-ada` | — | ✅ `patches\prefill-port.patch` | — |
| 3 | 上游指南 `ca845a40` | 1.4 MB | 魔搭 `shensanshu/ninfer-ada-ternary` | — | ✅ `vendor\guide\` | — |
| 4 | **容器模板** | **18.21 GB** | hf-mirror（HuggingFace） | ⚠️ 只有一家 | ❌ | **步骤 7 打不出制品** |
| 5 | **三元 GGUF** | **7.21 GB** | 魔搭 `prism-ml` | HuggingFace 同名仓 | ❌ | **步骤 7 打不出制品** |
| 6 | FFmpeg 开发包 | 83 MB | GitHub 直连 | **见下 3 个代理** | ❌ | 步骤 6 失败 |
| 7 | CUDA Toolkit 13.2 | ~3 GB | NVIDIA 官方归档 | — | ❌ | 步骤 6 失败 |
| 8 | VS18 BuildTools | ~5 GB | 微软官网 | — | ❌ | 步骤 6 失败 |
| 9 | CMake / Ninja / Python / numpy / torch | ~300 MB | aliyun PyPI / pytorch CPU index | pypi.org | ❌ | 步骤 5 失败 |

> ⚠️ **#4 和 #5 是本方案唯一的"外部单点"**：它们不在本仓、也没有第二个来源。
> 若将来上游删仓，请自行保留副本（见第四节）。

## 二、必须比对的 sha256

| 文件 | 字节数 | sha256 |
|---|---:|---|
| 容器模板 `.ninfer` | 18,210,531,328 | `8c9f9d67a07ac97506978f6db6695d8074f78dec0fb80c4a85a8fb6fbedd7f03` |
| 三元 GGUF | 7,206,168,928 | `3907dc1658db1f78a9826bf8d5bcb8dc65db0d466388937af57f2294fae62ec1` |
| **产出制品** `.ninfer` | **8,306,927,628** | **`05bbbf01090c6f61113b54556daa22ad0b45036a078af6cd6f02a3fde47ad76c`** |

**制品那一行是"复现成功"的最终判据。** 前两行对不上就不要继续（后面所有结果都会不同）。

## 三、FFmpeg 的下载源（2026-09-28 实测全部可用，均 83 MB / HTTP 200）

```powershell
# 首选：GitHub 直连（实测通，约 2 MB/s）
$gh = 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip'

# 备用（国内代理，把原始 GitHub 链接拼在后面）
#   https://ghfast.top/$gh
#   https://gh-proxy.com/$gh
#   https://ghproxy.net/$gh
```

用备用源时把代理前缀拼上即可，例如：

```powershell
Invoke-WebRequest -Uri ('https://ghfast.top/' + $gh) -OutFile ffmpeg.zip
```

> 这是**GPL 版 FFmpeg**。本仓不包含、也不分发它，仅在你机器上按需下载。

## 四、怎么把"外部单点"也锁死（可选，需你决策）

- **只镜像 GGUF**（7.21 GB，Apache-2.0、干净）：上传到你自己的 HuggingFace / 魔搭，README 里加一句备用地址即可。
- **模板（18.21 GB）**：它源自 `huihui-ai/…-abliterated`（**去审核**模型）。
  Apache-2.0 **允许**再分发，但**公开发布**会带来**监管与平台层面**的风险（与版权无关）。
  → 更干净的做法：换成**非 abliterated** 的 groupwise-int 模板重新打包，再镜像。
- 镜像完成后，请把新地址补进本文件，并在第 4/5 行的"备用来源"列里更新。

## 三、发布者视角：为什么本仓不分发模型权重

本仓**只提供流程、脚本与补丁**，**不镜像任何模型权重**（既不含三元权重，也不含容器模板）。原因有三：

1. **版权上没必要** —— 模板与权重都是 Apache-2.0，任何人从官方源即可免费下载；本仓不镜像，不影响任何人复现。
2. **避免"分发者"身份** —— 一旦本仓（或维护者账号）公开镜像权重，维护者就从"写文档的人"变成"公开分发模型权重的人"，责任性质随之改变。
3. **上游可追踪** —— 用官方源 + sha256 校验，任何人都能确认自己拿到的就是被验证过的那一份。

### 如果某个来源失效了

**请不要来本仓找镜像**，而是：

1. 在 HuggingFace / 魔搭上搜索同名的 **groupwise-int 容器模板**；
2. 用这几条判断一个模板能不能用：
   - 文件名形如 `*.ninfer`；
   - 同目录的 `artifact-manifest.json` 里 `weights_id` 值为 `"groupwise-int"`；
   - 体积为 `18,210,531,328` 字节（v2 容器）；
   - 对象名里可以含 `dflash2/*`（含与不含都能用，但本流程只验证过"不含"的那种）。
3. 拿到后**按上面的 sha256 表核对**；不一致就不要用。

### 关于"代操作 / 代部署"收费

这属于**技术服务**，不是分发模型。建议：

- 让**下载发生在客户的机器上**（从上面这些公开源），而不是由你转手文件；
- 交付时随附本目录的 `NOTICE`（六家上游 + Prism ML 必需署名）；
- 售前明确硬件要求（Ada 架构、显存 ≥16GB、SSD），避免"装不上"的纠纷。
