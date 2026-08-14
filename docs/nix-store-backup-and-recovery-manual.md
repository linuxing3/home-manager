# UOS + Home Manager 备份与恢复手册

本手册适用于当前主机：UOS Desktop 20 Professional、`aarch64-linux`、
standalone Home Manager。它说明怎样备份配置、凭据、Nix 闭包和整机，
以及怎样在故障后按安全顺序恢复。

随附入口脚本：`tools/nix-recovery-guide`。脚本默认只检查；任何写入、
导入、构建或激活操作都需要单独确认。

Agent 操作手册：`.codex/skills/uos-nix-store-backup/SKILL.md`（提炼自
2026-08-13 实操会话）。

## 1. 先理解四种不同的恢复材料

| 材料 | 解决的问题 | 不能替代什么 |
|---|---|---|
| Git 仓库与 `flake.lock` | 重新构建 Home Manager 配置 | 用户数据、解密私钥、UOS 系统配置 |
| 加密凭据备份 | 恢复 SSH/Agenix、rclone、Bitwarden 等身份 | Nix 软件闭包和普通用户数据 |
| 签名 Nix binary cache | 快速或离线恢复已构建的软件 | EFI、内核、APT、systemd 和分区表 |
| 整盘离线镜像 | 直接恢复可启动的 UOS 系统 | 镜像之后新增的数据 |

只复制 `/nix/store` 不等于可恢复备份。Nix 还依赖数据库、签名、profile、
GC root 和顶层闭包；完整电脑还依赖 EFI、`/boot`、根分区、`/etc`、用户
数据与密钥。

## 2. 当前主机的容量与边界

- 当前 Home Manager 闭包约 9.0 GiB、1477 个 store path。
- 当前用户 Nix profile 约 13.8 GiB。
- 两者合并去重后约 2136 个 path，NAR 数据约 14.11 GiB。
- KeyVault USB 约 15 GiB，不宜承担大型闭包缓存。
- `/share` 位于独立 1 TB 硬盘，适合作为本地 Nix cache，但仍需异地副本。
- `/nix`、`/home`、`/var` 等实际位于同一个 NVMe 数据分区；它们不是相互
  独立的灾难恢复副本。

因此建议：KeyVault 保存手册、恢复脚本、缓存签名密钥、公钥、顶层路径、
配置快照与校验信息；大型 Nix cache 保存到 `/share/recovery/nix-cache`，
然后再同步到可信远端或另一块离线硬盘。

## 3. 推荐的日常备份节奏

### 每次验证过 Home Manager 更新后

1. 确认新配置可以完成非激活构建。
2. 运行 `nix-recovery-guide`，选择“创建或刷新恢复材料”。
3. 脚本记录当前 Home Manager 和用户 profile 顶层路径。
4. 脚本使用 KeyVault 内的签名密钥把闭包复制到本地 `file://` cache。
5. 运行脚本的“验证恢复材料”。

只缓存当前代际和少量已知可用旧代际。当前机器已有大量历史代际；不要
默认使用 `nix copy --all`，否则缓存会长期膨胀。

### 每日或每周

- 用 Restic/Borg 备份用户文档、项目和非 Home Manager 应用状态。
- 使用现有 `credential-vault` 备份凭据。
- 使用 `rclone check --checksum --one-way` 验证远端副本。
- 不把明文私钥或 cache 签名私钥上传到普通未加密云目录。

### 每月或重大系统升级前

从可信救援介质启动 Clonezilla/Rescuezilla，对整块 `/dev/nvme0n1` 制作
离线镜像。必须包含分区表、EFI、`/boot`、根分区和数据分区。不要在正在
运行的系统里用普通文件复制冒充一致的整盘镜像。

## 4. KeyVault 的安全角色

KeyVault 是可移动 LUKS 加密盘。建议至少保存：

```text
recovery/nix-system-recovery/
├── MANUAL.md
├── nix-recovery-guide
├── manifest/
│   ├── top-level-paths.txt
│   ├── host-facts.txt
│   ├── repository-status.txt
│   └── cache-location.txt
├── repository/
│   ├── home-config.bundle
│   ├── working-tree.patch
│   └── untracked-files.tar.gz
└── secrets/
    ├── nix-cache-secret-key
    └── nix-cache-public-key
```

安全规则：

- `secrets/`、`manifest/`、`repository/` 使用 `0700`；私钥使用 `0600`。
- 终端只显示密钥路径，不显示密钥内容。
- KeyVault 拔出前执行 `sync`，然后通过桌面或 `udisksctl unmount` 正常卸载。
- 保留第二份离线加密凭据副本，避免 KeyVault 自身成为单点故障。

## 5. 推荐恢复顺序

### A. 直接恢复整机

如果有新鲜且经过验证的整盘镜像：

1. 从 Clonezilla/Rescuezilla 启动。
2. 仔细核对目标磁盘型号和容量。
3. 将整盘镜像恢复到目标 NVMe。
4. 第一次启动后检查 EFI、文件系统和网络。
5. 再恢复镜像之后产生的用户数据与配置。

整盘恢复会覆盖目标磁盘，必须在救援环境中再次人工确认。随附脚本不会
调用 `dd`、格式化、分区或自动恢复磁盘镜像。

### B. 在新装 UOS 上重建

1. 安装与当前架构匹配的 UOS，并先恢复基础网络与系统时间。
2. 安装 multi-user Nix，确认版本和 daemon 状态。
3. 解锁 KeyVault。
4. 优先恢复 SSH/Agenix 身份。现有 `credential-usb-recovery` 会在覆盖前
   建立快照并要求确认。
5. 从 `home-config.bundle` 或远端 Git 恢复仓库，再应用工作区补丁和经人工
   审阅的未跟踪文件。
6. 按 `top-level-paths.txt` 从签名 cache 导入当前闭包。
7. 在仓库中执行非激活构建：

   ```bash
   nix build \
     'path:.#homeConfigurations.Designers.activationPackage' \
     --no-link \
     --no-update-lock-file
   ```

8. 审阅结果后，才执行 Home Manager 激活。
9. 恢复普通用户数据及 UOS 系统层设置。
10. 验证 Agenix、rclone、用户服务、输入法、桌面与关键程序。

## 6. 签名 binary cache 的恢复原理

备份端使用 Nix cache 私钥为生成的 `.narinfo` 签名；恢复端只需公钥。公钥
可公开，私钥只能存于加密介质。恢复时不要为了省事永久关闭签名校验。

随附脚本记录的 cache URL 类似：

```text
file:///share/recovery/nix-cache
```

导入时，脚本把 KeyVault 中的公钥作为本次命令的
`trusted-public-keys` 传给 Nix，并按记录的顶层路径复制完整闭包。导入只把
对象放回 `/nix/store`，不会自动激活 Home Manager。

## 7. 远端存储选择

- **Cachix**：适合 Nix 闭包原生恢复。本机已验证公开恢复缓存
  `https://linuxing3-system-recovery.cachix.org`（见第 7.2 节）。
- **Attic**：适合自建、多缓存和保留策略。
- **S3 binary cache**：适合已有对象存储与 IAM 管理的场景。
- **Google Drive/OneDrive/WebDAV**：适合备份整个本地 cache 目录；先下载
  到本地，再以 `file://` 使用，不把普通云盘当原生 substituter。本机已验证
  `onedrive-linuxing3:Backups/Nix/Designers-PC` 上的 GPG 加密归档（见第 7.1 节）。

远端写入不是本脚本的默认动作。配置目标与保留策略后，再通过明确确认
执行，并以校验结果而不是“上传命令退出 0”作为成功标准。

### 7.1 OneDrive 加密归档操作要点

1. 先完成 `/share/recovery/nix-cache` 的本地签名缓存。
2. 只用 KeyVault 中的 GPG **加密子密钥**流式加密；私钥不得导出或上传。
3. NAR 已是 zstd 时关闭 GPG 二次压缩，避免体积膨胀。
4. 归档完整后再原子写入 `.sha256`；不要上传空校验文件。
5. 先以临时名上传，核对精确字节数与 OneDrive QuickXorHash 后再改正式名。
6. 小元数据（公钥、顶层路径、README）打成单个小 tar 上传；OneDrive 对大量
   小文件 `rclone copyto` 常在成功后卡住，并可能留下 0 字节占位。
7. 不要对数 GiB 密文跑全量 `gpg --list-packets`；只检查包头收件人即可。

### 7.2 Cachix 操作要点（2026-08-13 实测）

1. 缓存名以公开 HTTP/API 为准；本机历史缓存是 `linuxing3`，恢复专用缓存是
   `linuxing3-system-recovery`。勿把笔误名（如 `nuxing3`）当成目标。
2. 客户端签名缓存同时需要写入令牌与配对签名私钥。令牌从 Bitwarden 注入子
   进程，终端不回显；用完删除 `$XDG_RUNTIME_DIR` 临时文件并清空剪贴板。
3. `CACHIX_SIGNING_KEY` 只接受冒号后的 **Base64 私钥材料**。传入完整 Nix
   `名称:Base64` 会使 Cachix 1.11.x 解出错误私钥，表现为“能上传但签名不匹配”。
4. 管理 API 的 `publicSigningKey` 同样只传 Base64。传入 `名称:Base64` 会产
   生重复前缀公钥，必须删除空的错误缓存后重建。
5. 已有客户端签名公钥的缓存目前不能追加第二把公钥。丢失 `-1` 私钥时，应
   新建独立恢复缓存，而不是删除/重建仍有消费者的旧缓存。
6. 删除后再用**同名**重建可能留下后端签名状态不一致；优先使用从未占用过
   的缓存名。
7. `cachix push` 与 bulk missing API 可能把“全球可复用 NAR”误报为“本缓存已
   存在”。必须以每个 path 的公开 `.narinfo` URL 实际返回 HTTP 200 为准。
8. 若本地已有签名 `file://` cache，而远端大量 narinfo 仍 404，应从本地已
   校验的 zstd NAR 回填并重新用**已注册**缓存私钥签署 narinfo。
9. Nix 2.35.1 的 `nix store verify --store https://...` 可能在内容与哈希均
   正确时仍报 `path ... is not valid`。验收应拆成：公钥/元数据校验 + 独立
   的远端字节流哈希校验。
10. Cachix 成功后仍保留 OneDrive GPG 归档，作为互不替代的第二远端层。

Agent 操作细则见 `.codex/skills/uos-nix-store-backup/SKILL.md`。

## 8. 恢复验收清单

恢复完成必须逐项确认：

- KeyVault 中的 `SHA256SUMS` 校验通过；私钥文件权限保持 `0600`。
- Nix cache 能查询所有记录的顶层路径。
- 本地：`nix store verify --recursive` 对恢复闭包没有内容损坏。
- 远端 Cachix：闭包内每一个公开 narinfo URL 均为 HTTP 200，且签名键名与
  注册公钥一致；不以 bulk missing API 或仅顶层根 200 作为完成证据。
- 远端 OneDrive：精确字节数与 QuickXorHash 一致；下载后再核 SHA-256。
- `flake.lock` 未被意外更新。
- activation package 可以在不激活的情况下构建。
- Agenix 可以解密，但秘密值没有出现在日志或终端输出中。
- Home Manager 激活后，关键二进制来自预期 profile。
- rclone 只读 quota/listing 检查成功。
- 用户服务实际运行，不能只检查 unit 文件是否存在。
- 整盘镜像至少做过一次备用盘或虚拟机中的恢复演练。

## 9. 紧急情况下的原则

1. 先保护原盘，不要在疑似损坏的介质上反复修复。
2. 不确定目标设备时停止，不运行格式化、分区、`dd` 或镜像恢复。
3. 先恢复身份与配置，再恢复缓存，最后恢复和激活用户环境。
4. 始终保留回退材料；不要在首次恢复成功前删除旧镜像和旧凭据副本。

