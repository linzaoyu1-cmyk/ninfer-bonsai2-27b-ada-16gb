# vendor/guide — 上游指南的离线镜像

本目录是 魔搭 `shensanshu/ninfer-ada-ternary` 在 commit `ca845a402866e98fcd468e010cc980f7f4d002a2`
的**逐文件镜像**（不含 `.git`）。

| | |
|---|---|
| 来源 | https://modelscope.cn/models/shensanshu/ninfer-ada-ternary |
| Commit | `ca845a402866e98fcd468e010cc980f7f4d002a2` |
| 许可 | 见本目录 `LICENSE` 与 `NOTICE.md`（**Apache-2.0**） |
| 用途 | **上游失效时的备用** |

## 为什么要有它

`patches/pack-py.patch` 只是一个**补丁**，必须打在一份 `pack.py` 上；而 `pack.py` 运行时
还要读同目录的 `MAPPING.json`。这两个文件**只存在于上游指南仓**里。
上游是**活仓库**（HEAD 已前进过），也可能像 `Ambolio/ninfer-4090-windows` 那样直接消失——
所以这里留一份离线副本。

## 怎么用

**正常流程仍按 README 步骤 3 从魔搭 clone 并 pin commit。** 只有取不到时才用镜像：

```powershell
robocopy vendor\guide guide /E
```

之后步骤 4 照旧执行 `git -C guide apply ..\patches\pack-py.patch`
（`git apply` 不要求目标是 git 仓库，所以镜像目录也能打补丁）。

> ⚠️ 镜像内是**未打补丁的原始状态**，`patches/pack-py.patch` 必须照常应用。
> ⚠️ 镜像里的文件与 commit `ca845a40` 逐字节一致；**不要在本目录里直接改东西**，改动请走 `patches/`。
