# UOS OKR EFI 修改与虚拟化方案

## 结论

采用用户态恢复路线，不在当前机器运行或修改 OKR EFI：

```text
只读 okr-inspect
→ 只输出新普通文件的 RAW 恢复器
→ 修正虚拟盘 fstab/GRUB
→ QCOW2
→ qemu-system-aarch64 + AAVMF
```

真实备份是 OKR `0x09000812`，公开源码是 `0x09000811` 且只提供 X64
构建。现阶段不具备安全构建、签名和部署匹配 AArch64 EFI 的条件。

## 已确认的生产格式

- 头部固定字段偏移到 `FileNumber` 与公开源码一致。
- `StructSize = 0x6c00`，GPT 区为 `0x10000`，`DataOffset = 0x17000`。
- 9 条生产分区记录从 `0x6024` 开始，每条 `0x130`（304）字节。
- 生产记录在公开结构 `Label[33]` 后加入 `LastMounted[64]`，因此记录从
  176 字节扩展为 304 字节；样本中的 `/share`、`/boot`、`/`、`/var`
  验证了该布局。
- `DataOffset` 指向首个已备份分区的 4 KiB 对齐位图；首个 `czae` 数据块
  位于 `0x18000`，两者相差的 4 KiB 正是 EFI 分区位图。
- 备份选择 EFI、Boot、Roota；`_dde_data`、KT_PART、LENOVO_PART 均未备份。

## 阶段一：只读检查器

`tools/okr-inspect` 只接受普通文件，拒绝设备路径、符号链接、未知版本、越界
字段和不完整分卷。它验证：

- `okr9`、版本、头大小、分区数、GPT 签名和四个分卷总长度；
- 每个分区的 LBA 范围、备份选择、GUID、标签和最后挂载点；
- 每个分区位图边界；
- 所有 `czae`/`nxps` 块头、4 KiB 对齐、长度和分区数据边界。

它不解压、不创建镜像、不访问 `/dev/*`，也不证明备份来源真实性。

## 阶段二：用户态 RAW 恢复器

`tools/okr-restore-raw` 已实现以下边界：

1. 输入继续只读打开，输出使用 `O_CREAT|O_EXCL|O_NOFOLLOW`。
2. 输出必须是不存在的普通文件；拒绝块设备、字符设备、FIFO、目录和符号链接。
3. 先完整验证分卷、GPT、所有位图和全部块头，再进行第一次输出写入。
4. RAW 逻辑大小固定为 `500118192 × 512 = 256060514304` 字节，可创建稀疏文件。
5. 只恢复 `bIfBackup=1` 的 EFI、Boot、Roota；每个写入范围必须满足：

   ```text
   target_lba = BootBegin + bitmap_block × 64
   target_lba + sector_count <= DiskSize
   target_lba + sector_count <= BootBegin + TotalSectors
   ```

6. LZ4 解压结果必须等于位图所需的有效块字节数，不能只检查“解压成功”。
7. GPT 先写入输出文件的逻辑盘头；绝不把宿主块设备作为输出。
8. 验证主 GPT 头及分区数组 CRC，并在 RAW 末尾生成备用 GPT 数组和头。
9. 任何失败都会删除本次新建的不完整输出；已有文件永远不会被覆盖。

先只做完整解压预检：

```sh
tools/okr-restore-raw --preflight-only \
  /share/data/UOS-OKR-backup-20260813/6A7D2ACB-System/okrfile
```

确认目标目录至少有约 11 GiB 可用空间后，显式提供一个不存在的输出文件：

```sh
tools/okr-restore-raw \
  /share/data/UOS-OKR-backup-20260813/6A7D2ACB-System/okrfile \
  /path/to/new-uos-restored.raw
```

## 阶段三：让虚拟系统可启动

备份缺少承载 `/var`、`/home`、`/opt`、`/nix` 和 `/root` 的 `_dde_data`。
首次启动前应在 RAW 副本中离线处理：

1. 保留 EFI、Boot、Roota 的原 UUID，避免不必要地改写 GRUB。
2. 备份并修改虚拟 Roota 的 `/etc/fstab`，注释缺失 `_dde_data` 的挂载和
   bind mount；为 `/var`、`/home`、`/opt`、`/root` 创建本地目录。
3. 若系统的软件或 Home Manager 环境依赖 `/nix`，需另行恢复 `/nix`，否则
   只把它建为空目录不能恢复 Nix 程序。
4. 先用只读挂载或 `guestfish --ro` 检查文件系统，再在 RAW 的工作副本修改。
5. 将 RAW 转为 QCOW2 后执行 `qemu-img check`。

仓库中的 `tools/fixtures/fstab.uos-okr-vm` 是本备份专用模板，只保留已经恢复
且 UUID 经 `blkid` 验证的 Roota、Boot、EFI。应用到虚拟盘时必须把原始文件
保留为 `/etc/fstab.okr-original`。该模板不能补回缺失的 `_dde_data` 数据；它
只避免缺失分区把虚拟机直接送入 emergency mode。

`tools/fixtures/debugfs-create-vm-runtime.commands` 只为一次性 Roota 工作镜像
建立 LightDM 所需的 `/var` 状态目录和空的 `/home/Designers`。UID/GID 来自
备份内的账户数据库，目录权限与当前 UOS 安装一致。空家目录只用于验证登录
链路，并不代表用户资料已经恢复；原始 RAW 不应应用这组命令。

### 实机验证结果

恢复后的 VM RAW 与 QCOW2 已通过 GPT、ext4 和 `qemu-img check`。在本机
Phytium D2000、UOS 4.19 宿主上，QEMU 必须显式使用
`gic-version=3,its=on`；使用 QEMU 11 默认自动 GIC 会让旧 UOS 内核停在
早期 SMP 初始化。隔离启动条件为 4 vCPU、4 GiB、KVM、无网络、无宿主块
设备且系统盘 `snapshot=on`。

验证达到以下状态：

- EFI fallback、GRUB、UOS 内核、initrd、Roota、Boot 和 EFI 均可加载；
- 控制台启动完成，最近一次为内核 35.241 秒、用户态 22.582 秒，总计
  57.823 秒；
- 补齐包级空目录后，`upower`、`fprintd`、`deepin-user-lock` 和 LightDM
  均能启动，不再出现 `Failed at step NAMESPACE`；
- DDE greeter framebuffer 仍是黑屏，LightDM 在部分启动中稍后退出。

因此当前镜像是可启动、可维护的“系统盘恢复”，但不能宣称已经恢复可用的
DDE 用户桌面。缺少的 `_dde_data` 原本承载真实 `/home`、`/var`、`/opt`、
`/root` 和 `/nix`；创建空目录只能恢复服务启动前提，不能重建用户配置、
账户状态、应用数据或 Nix profile。要可靠恢复 DDE，必须取得 `_dde_data`
备份或从另一份备份恢复至少 `/home/Designers` 与 `/var`。

`tools/okr-run-vm-diagnostic` 固化了已经验证的直接内核诊断参数，并强制
QCOW2、`snapshot=on`、无网络和拒绝 `/dev/*`。示例：

```sh
tools/okr-run-vm-diagnostic \
  --qemu /path/to/qemu-system-aarch64 \
  /path/to/uos-restored-vm.qcow2 \
  /path/to/extracted-vmlinuz \
  /path/to/extracted-initrd.img
```

它用于验证已恢复系统，不替代 EFI/GRUB 完整启动测试，也不会修改 QCOW2。

虚拟机只连接 QCOW2 工作盘和 AAVMF 变量盘副本；不直通宿主 NVMe，不共享
宿主 EFI 变量，不启用 OKR 自动恢复。

## EFI 隔离修改方案

仅在取得匹配 `0x09000812` 的 AArch64 源码、EDK II 依赖、厂商构建参数和签名
流程后考虑。最低补丁集：

- 新增统一 `ValidateImageHeader()`，限制版本、`PartitionCount <= 64`、头大小、
  GPT/数据偏移及所有乘加溢出；
- 将变量大小等长度字段使用 `UINTN`，避免 `UINT8` 截断；
- 每个块严格验证魔数、实际长度、对齐长度、解压上限和分卷边界；
- 在第一次 Block I/O 写入前完成全镜像预检；
- 所有写入统一经过目标磁盘身份与 LBA 边界包装器；
- 禁用 `OKRFunKey=1/2/3` 自动、静默和强制恢复，关闭调试 UI；
- 默认 dry-run，只允许 QEMU 中新建的空 virtio 磁盘；
- 使用 QEMU 快照和无宿主块设备的测试环境，不写本机 NVRAM 或启动项。

公开 X64 EFI 不应在 AArch64 虚拟机中作为恢复方案：它既不是匹配架构，也不
了解生产扩展字段。用户态恢复器更容易审计、测试和限制输出目标。
