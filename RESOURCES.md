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
