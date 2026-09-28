# 锁定的环境与版本

本文所有版本号都在参考机器上实测过；**换成别的版本不保证结果一致**（尤其 exe 编译与制品哈希）。

## 参考机器

| 项 | 值 |
|---|---|
| GPU | NVIDIA GeForce RTX 4070 Ti SUPER 16GB（sm_89），VBIOS `95.03.45.00.ad` |
| 驱动 | 616.56（KMD 616.56，CUDA UMD 13.4） |
| 系统 | Windows 11 专业版 `10.0.26200`（Build 26200） |
| CPU / 内存 | i7-14700KF / 28 线程 / 63.8 GB（页文件 16 GB） |

## 工具链

| 组件 | 版本 |
|---|---|
| CUDA Toolkit | 13.2（`C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2`） |
| MSVC | 14.51.36231（VS18 BuildTools） |
| CMake | 4.4.3 |
| Ninja | 1.13.2 |
| Python | 3.12.14 |
| numpy | 2.5.3 |
| torch | 2.14.0+cpu |

> `torch` 是**打包器的隐式依赖**（`tools/artifact/layouts.py` 会 import 它），不是"纯 numpy"。

## 上游 pin

| 角色 | 仓库 | 版本 | 许可 |
|---|---|---|---|
| 引擎源码树 | `Ambolio/ninfer-4090-windows` | commit `6eb70a07`（v1.0.8 线） | Apache-2.0 |
| 部署指南 | 魔搭 `shensanshu/ninfer-ada-ternary` | commit `ca845a40` | Apache-2.0 |
| groupwise-int 模板 | `Barding-Defense/Qwen3.8-27B-huihui-abliterated-groupwise-int-NInfer` | 18,210,531,328 B | apache-2.0 |
| 三元模型权重 | `prism-ml/Ternary-Bonsai-2-27B-gguf` | 7,206,168,928 B | apache-2.0 |
| prefill 内核参考实现 | `CraneBW/ninfer-ternary-bonsai-ada` | master（`--depth 1`） | Apache-2.0 |

> ⚠️ 引擎源码树的上游**已 404**，所以本仓用 `mirror/ninfer-4090-windows-6eb70a07.bundle` 提供。

## 输入校验值

| 文件 | 字节数 | sha256 |
|---|---:|---|
| 模板 `.ninfer` | 18,210,531,328 | `8c9f9d67a07ac97506978f6db6695d8074f78dec0fb80c4a85a8fb6fbedd7f03` |
| 三元 GGUF | 7,206,168,928 | `3907dc1658db1f78a9826bf8d5bcb8dc65db0d466388937af57f2294fae62ec1` |

## 产物校验值

| 文件 | 字节数 | sha256 |
|---|---:|---|
| 制品 `Ternary-Bonsai-2-27B.ninfer` | 8,306,927,628 | `05bbbf01090c6f61113b54556daa22ad0b45036a078af6cd6f02a3fde47ad76c` |

> 制品哈希**可复现**（已验证：在干净目录从零跑一遍，得到同一个哈希）。
> **exe 不可逐字节复现** —— MSVC 会把源码路径与时间戳编进二进制，所以引擎用**行为验收**代替哈希（见 README 第 3 节）。

## 上游镜像（下载用）

| 用途 | 地址 |
|---|---|
| HuggingFace | `https://hf-mirror.com`（单连接 ~0.3 MB/s，**必须 8 连接**；个别仓库会 308 跳回 huggingface.co） |
| 魔搭 | `https://modelscope.cn`（快，约 40 MB/s） |
| PyPI | `https://mirrors.aliyun.com/pypi/simple`（清华镜像返回 403） |
| PyTorch CPU wheels | `https://download.pytorch.org/whl/cpu` |
| GitHub 克隆 | 需 `-c http.sslBackend=openssl`（默认 schannel 会 TLS 握手失败） |
