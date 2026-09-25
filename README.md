# MIB2 Toolbox — MMI Mirror V2.4.1

简体中文

本项目面向 Audi **MHI2Q** 平台，用于将 MMI 中控画面实时镜像至 **Virtual Cockpit** 的地图显示区域，并通过 Green Engineering Menu / Toolbox 完成安装、启动、停止、更新、日志收集和卸载恢复。

> [!WARNING]
> **⚠️ 写在前面**
>本项目此前在测试阶段曾被个别人未经允许拿去包装、倒卖。免费分享的测试成果被拿去牟利，是本项目停止继续公开开发的主要原因之一。
>现发布的版本是当时测试阶段最终保留下来的较完整版本，已完成实车验证。此次更新只是因为之前公开版本已经明显落后，并不代表项目恢复长期维护。
>目前我们的主要开发重心已经转向 AltScreen，其主体开发也已基本完成。除非后续出现影响正常使用的重大 Bug，本项目将停止继续开发和常规更新。未来可能加入 CarLife 支持，但不作承诺。
>本项目免费开源，禁止倒卖。
>可以学习、研究和交流，但请不要把别人的免费成果换个包装拿去赚钱。

> 
> [!IMPORTANT]
> 本项目会修改车机系统文件。安装、更新或卸载过程中请保持 SD 卡连接和车机供电稳定。  
> **安装或更新完成后必须重启车机 / HMI，再判断显示效果。**
>
> 请勿在驾驶过程中进行安装、更新、卸载或故障处理。

---

<img width="1707" height="1280" alt="1fcb77abdb31026899b34a0c393d8056" src="https://github.com/user-attachments/assets/6098f5b9-f08b-40c0-a651-03676b7703d6" />

<img width="1707" height="1280" alt="131ec8d28840b205975e61d9b2784842" src="https://github.com/user-attachments/assets/033f645f-8a3b-4886-95b6-6a272c62e9ac" />

https://github.com/user-attachments/assets/54a7e453-c473-428b-8cbe-08c460c59622


当前版本主要特性：

- 将 MMI 中控画面实时镜像至 Virtual Cockpit 地图区域。
- 支持 **Classic / Sport** 仪表布局。
- 支持 **Full / Small** 地图区域变化。
- 根据不同仪表状态动态调整镜像显示区域。
- 支持源画面 Crop、Scale、Offset 与自然边缘裁切。
- Classic / Sport、Full / Small 切换后，水印活动区域会随新的镜像位置和裁切区域重新计算。
- 支持手动启动 / 停止。
- 支持 AutoStart 自动启动：当 CarPlay 启动并进入可用状态后，MMI Mirror 会自动启动镜像
- 支持旧版本直接覆盖更新。
- 支持日志收集和完整卸载。

当前 Native：

~~~text
mmi-mirror-display
SHA256:
ee48454507b24ed1cb1f72c1f8ee5202e16e2b58dd045c64a594a3dec0c5d1d5
~~~

包内可通过：

~~~text
Toolbox/apps/mmi-mirror/V2.4.1-SHA256SUMS
~~~

进一步核对安装文件。

---

## 下载与 SD 卡准备

下载本仓库 **main** 分支 ZIP 并解压。

将以下内容放到 SD 卡根目录：

~~~text
metainfo2.txt
Toolbox/
~~~

正确结构示例：

~~~text
SD CARD
├── metainfo2.txt
└── Toolbox
    ├── GEM
    ├── apps
    ├── final
    └── scripts
~~~

不要额外套一层仓库目录。

例如下面这种结构是错误的：

~~~text
SD CARD
└── MHI2Q-CarPlay-RGI-MMI-Mirror-main
    ├── metainfo2.txt
    └── Toolbox
~~~

---

# 安装与使用

## 1. 更新 Toolbox

将本仓库中的：

~~~text
metainfo2.txt
Toolbox/
~~~

复制到 Toolbox SD 卡根目录。

按照 MIB2 High Toolbox 的正常更新方式，让车机加载新的 GEM 菜单、脚本和运行文件。

Toolbox 更新完成后，建议：

~~~text
退出 Green Engineering Menu
        ↓
重新进入 Green Engineering Menu
~~~

确保新的 MMI Mirror 菜单已经重新加载。

---

## 2. 安装 MMI Mirror

进入：

~~~text
Main
  ↓
MQBCoding
  ↓
Customization
  ↓
MMI Mirror
~~~

主要菜单包括：

| 菜单项 | 作用 |
| --- | --- |
| Install/Update MMI Mirror | 首次安装或覆盖更新 MMI Mirror |
| Start MMI Mirror | 手动启动 MMI Mirror |
| Stop MMI Mirror | 停止当前 MMI Mirror 会话 |
| AutoStart ON - start after MMI boot | 开启自动启动：CarPlay 启动后自动开启 MMI Mirror。 |
| AutoStart OFF - manual start only | 关闭后续自动启动 |
| Copy MMI Mirror diagnostics to SD-card | 将诊断日志复制到 SD 卡 |
| Clear temporary MMI Mirror logs | 清理临时运行日志 |
| Restore/Uninstall MMI Mirror | 卸载 MMI Mirror 并恢复安装前状态 |

保持 SD 卡插入，选择：

~~~text
Install/Update MMI Mirror
~~~

安装程序会：

~~~text
检查 SD 卡安装文件
        ↓
停止当前正在运行的旧 MMI Mirror
        ↓
创建新的 staged runtime
        ↓
复制并校验新的 binary / scripts / config
        ↓
保留旧 runtime 作为临时 rollback
        ↓
切换到新 runtime
        ↓
执行 binary loader self-test
        ↓
执行 launcher shell self-test
        ↓
成功后完成安装
~~~

如果更新过程中发生错误，脚本会尽可能恢复安装前的 runtime，避免留下简单的“半覆盖”状态。

安装日志保存在：

~~~text
Backup/<VERSION>/MMIMirror/install_mmi_mirror.log
~~~

其中 <VERSION> 为当前车机固件版本。

---

## 3. 安装完成后

安装成功后，**必须重启车机 / HMI**。

正确流程：

~~~text
Install/Update MMI Mirror
        ↓
确认安装成功
        ↓
重启车机 / HMI
        ↓
等待车机完整启动
        ↓
重新进入 MMI Mirror 菜单
        ↓
Start MMI Mirror
        ↓
确认仪表镜像正常
~~~

不建议在安装完成但尚未重启的情况下直接启动 MMI Mirror 判断效果，因为磁盘上的新版本已经替换，但当前系统中仍可能存在旧进程或旧运行环境。

---

# 重复安装 / 版本升级

## 已经安装旧版 MMI Mirror，可以直接升级吗？

**可以。**

正常情况下，**不需要先卸载旧版本**。

直接使用新版 SD 卡执行：

~~~text
Install/Update MMI Mirror
~~~

即可完成覆盖更新。

安装脚本会主动检测已有：

~~~text
/mnt/app/root/mmi-mirror
~~~

如果发现已有安装或正在运行的 MMI Mirror，会先停止旧会话，再通过 staged runtime + rollback 的方式切换到新版本，而不是直接在正在运行的目录里逐个覆盖文件。

### 推荐升级流程

如果当前已经开启 AutoStart，建议先执行：

~~~text
AutoStart OFF - manual start only
~~~

然后：

~~~text
准备新版 SD 卡
        ↓
Install/Update MMI Mirror
        ↓
确认安装日志显示成功
        ↓
重启车机 / HMI
        ↓
手动 Start MMI Mirror
        ↓
确认镜像和布局正常
        ↓
如有需要，再重新开启 AutoStart
~~~

### 升级需要准备什么？

只需要新版安装包中的：

~~~text
metainfo2.txt
Toolbox/
~~~

并确保 SD 卡中的：

~~~text
Toolbox/apps/mmi-mirror/mmi-mirror-display
Toolbox/apps/mmi-mirror/scripts/
Toolbox/apps/mmi-mirror/config.local
Toolbox/scripts/
Toolbox/GEM/
~~~

均来自同一版本安装包。

**不要只单独复制一个新的 mmi-mirror-display binary 到旧安装包中进行升级。**

V2.4.1 的 Native、启动脚本、布局配置、GEM 菜单和安装 / 卸载逻辑是配套的，应整包更新。

### config.local 会怎样处理？

当前安装包自带：

~~~text
Toolbox/apps/mmi-mirror/config.local
~~~

因此执行 Install/Update 时，会优先使用 SD 卡中的当前版本配置。

如果你曾经手动调整过旧版本的 Crop / Scale / Offset，升级前建议自行备份旧的 config.local，然后再根据新版本重新核对参数。

---

# 手动启动与停止

## 启动

进入：

~~~text
Main > MQBCoding > Customization > MMI Mirror
~~~

选择：

~~~text
Start MMI Mirror
~~~

正常情况下，MMI Mirror 会开始捕获中控 MMI 画面，并输出至 Virtual Cockpit 地图显示区域。

## 停止

选择：

~~~text
Stop MMI Mirror
~~~

该操作会结束当前 MMI Mirror 会话，但不会卸载程序。

下次仍然可以重新执行 Start MMI Mirror 再次启动。

---

# AutoStart

确认手动启动工作正常后，可以选择：

~~~text
AutoStart ON - start after MMI boot
~~~

开启开机自动启动。

AutoStart 会在 MMI 启动后等待必要运行环境就绪，再调用 MMI Mirror 启动流程。

开启 AutoStart 后，日常正常使用不需要持续插入 SD 卡。

如需关闭：

~~~text
AutoStart OFF - manual start only
~~~

需要注意：

AutoStart OFF 只是**从下一次开机开始禁止自动启动**。

如果当前 MMI Mirror 已经运行，它不会自动停止当前会话。如需立即停止，请另外执行：

~~~text
Stop MMI Mirror
~~~

### 更新或卸载之前

如果 AutoStart 已开启，建议先关闭 AutoStart，再进行安装更新或卸载。

完成操作并重启后，先手动测试正常，再决定是否重新开启 AutoStart。

---

# 日志与故障排查

如果出现：

- MMI Mirror 无法启动
- 启动后自动退出
- 仪表黑屏
- 镜像位置异常
- Sport / Classic 布局切换异常
- Full / Small 显示区域异常
- 更新或卸载失败

进入：

~~~text
Main > MQBCoding > Customization > MMI Mirror
~~~

选择：

~~~text
Copy MMI Mirror diagnostics to SD-card
~~~

诊断信息会保存到：

~~~text
Backup/<VERSION>/MMIMirror/RuntimeLogs/<TIMESTAMP>/
~~~

安装过程日志：

~~~text
Backup/<VERSION>/MMIMirror/install_mmi_mirror.log
~~~

需要重新从较干净的日志状态复现问题时，可以执行：

~~~text
Clear temporary MMI Mirror logs
~~~

该操作只清理可丢弃的临时日志，不等于停止或卸载 MMI Mirror。

---

# 卸载 / 恢复

如果开启过 AutoStart，建议首先关闭：

~~~text
AutoStart OFF - manual start only
~~~

如果 MMI Mirror 当前正在运行，可以先执行：

~~~text
Stop MMI Mirror
~~~

随后选择：

~~~text
Restore/Uninstall MMI Mirror
~~~

卸载脚本会处理当前 MMI Mirror runtime，并根据安装时记录的状态恢复相应文件。

卸载过程中：

- 不要拔出 SD 卡。
- 不要断开车机供电。
- 不要中途强制重启。

卸载完成后，**必须重启车机 / HMI**。

推荐完整流程：

~~~text
AutoStart OFF
        ↓
Stop MMI Mirror
        ↓
Restore/Uninstall MMI Mirror
        ↓
确认卸载成功
        ↓
重启车机 / HMI
        ↓
确认原车显示恢复正常
~~~

如果卸载出现错误，请先保存：

~~~text
Backup/<VERSION>/MMIMirror/
~~~

中的日志与备份文件，不要反复执行清理或手动删除车机文件。

---

# SD 卡与备份

安装、更新和卸载脚本会在 SD 卡中建立：

~~~text
Backup/<VERSION>/MMIMirror/
~~~

其中可能包含：

- 安装日志
- 卸载 / 恢复过程需要的状态信息
- 诊断日志
- 运行状态快照
- 必要的恢复文件

**不要随意删除 Backup 目录。**

至少在确认安装、更新或卸载完成，并且车机经过重启后工作正常之前，应保留该目录。

---

# 版本分支

当前推荐版本：

~~~text
main
└── V2.4.1
    └── 实车验证完成
~~~

旧版备份：

~~~text
V2.2
└── 原 main 的完整历史版本
~~~

---

# 开源说明

本项目为免费开源项目。

> **免费开源，禁止倒卖。**


---

# Acknowledgements

感谢以下项目和作者提供的基础工作与参考：

- [yuedizhibo / mib2q-MMI-Cockpit-Mirror](https://github.com/yuedizhibo/mib2q-MMI-Cockpit-Mirror) — MMI 中控画面镜像至 Virtual Cockpit 的重要实现基础。
- [OneB1t / VcMOSTRenderMqb](https://github.com/OneB1t/VcMOSTRenderMqb) — MQB Virtual Cockpit / MOST 自定义渲染研究的重要基础。
- [fifthBro / mh2p-cluster](https://github.com/fifthBro/mh2p-cluster) — QNX HMI 捕获及 GPU crop / zoom / pan 等实现思路的重要参考。
- [jilleb / mib2-toolbox](https://github.com/jilleb/mib2-toolbox) — MIB2 High Toolbox、Green Engineering Menu 与部署框架。

各上游文件与组件继续受其原始许可证和版权声明约束。
