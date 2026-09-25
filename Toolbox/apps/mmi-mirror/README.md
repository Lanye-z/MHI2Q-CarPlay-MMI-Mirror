# MMI Mirror V2.4 / Four-edge Crop Layout

## V2.4.1 package status

V2.4.1 继承 V2.4 主体镜像逻辑；启动 Logo 跟随 MMI mirror destination，运行水印为“免费开源，禁止倒卖”并在可见镜像区域内动态漂移。QNX 6.5 ARMv7 binary 已重新编译并同步，且已完成实车验证（`VehicleStatus=VEHICLE_VERIFIED`）。当前作为推荐稳定版本。详见 `V2.4.1-STATUS` 与 `V2.4.1-SHA256SUMS`。

下文描述 V2.4 crop-layout 基线；当前 `v2.4.1` 在此基础上同步品牌资源与重新构建的 QNX Native binary。

## 1. V2.4 与 V2.3 的关系

V2.4 **直接从 `v2.3-carplay-auto-lifecycle` 派生**。V2.3 已经完成并验证的主体架构继续保留：

```text
Java ClusterStateController = terminal1 / ctx80 sole writer
ctx80                       = {98,101,102,3}
Native RGI                  = displayable98 pixels only
Native MMI                  = displayable3 pixels only
CarPlayScreenMonitor        = MAIN_SCREEN state observer
mmi_mirror_supervisor.sh    = BaseVideo lifecycle supervisor
```

两代版本可以简单理解为：

```text
V2.3
= V2.2 的 JAVA80 / RGI / MMI composite
+ CarPlay MAIN_SCREEN / ActiveDevice 感知
+ CarPlay active 时自动启动 MMI Mirror
+ CarPlay inactive 时自动停止 MMI Mirror
+ supervisor / optional boot autorun

V2.4
= V2.3 全部上述功能
+ MMI 源画面四边独立裁切
+ crop 后再执行 SCALE / OFFSET
+ 允许 destination 超出 1440x455，不再强制 clamp 回屏幕
+ OpenGL 自然裁掉越界部分
+ capture / upload / draw / swap 等阶段耗时诊断
```

因此，**V2.4 没有重新设计 V2.3 的 CarPlay 自动生命周期、JAVA80 ownership、RGI98 renderer 或 planes 98/101/102 geometry**；主要新增内容集中在 Native MMI BaseVideo 的显示几何能力和性能诊断能力。

### 本分支的 RGI 版本

`v2.4-crop-layout` **仍然沿用 V2.3 原来的 Unified JAR / RGI 业务逻辑**，也就是用户原先的高德（Amap）专项补丁版本，没有切换到通用第三方地图变体。

当前继承的 Unified JAR：

```text
SHA256:  F96A7FFF4C767B51E9292926EB474E762B0E7119DE4C1D65D3D4961EBA6647FE
Git blob: cc151f7c15e879102d674b782beedd40bfd9232f
```

其构建源固定到：

```text
Lanye-z/mib2q-carplay-rgi-cn
RGI source rev: 0c77063b824bcb2368740c483e5bbc5204cb0816
```

该构建链明确使用用户原有的 `RGI/Amap Java implementation`。因此本分支仍保留原先针对高德数据/状态的专项处理。

如果需要 **去掉 Amap 专项状态机，并改为 Luka 的两项通用第三方导航兼容处理**，请使用：

```text
v2.4-third-party-nav
```

---

## 2. V2.4 four-edge source crop

V2.4 扩展 Native MMI BaseVideo 的显示几何能力：

```text
原始 MMI 1024x480
        ↓
CROP_LEFT / RIGHT / TOP / BOTTOM
        ↓
选中的源画面矩形 / dynamic UV
        ↓
SCALE
        ↓
OFFSET_X / OFFSET_Y
        ↓
1440x455 仪表区域
        ↓
超出边界的部分由 OpenGL 自然裁掉
```

每种仪表状态新增四个独立裁切参数：

```ini
MMI_<PROFILE>_CROP_LEFT=0
MMI_<PROFILE>_CROP_RIGHT=0
MMI_<PROFILE>_CROP_TOP=0
MMI_<PROFILE>_CROP_BOTTOM=0
```

四个 profile：

```text
CLASSIC_FULL
CLASSIC_SMALL
SPORT_FULL
SPORT_SMALL
```

裁切基于固定的 1024x480 MMI capture：

```text
source_x      = CROP_LEFT
source_y      = CROP_TOP
source_width  = 1024 - CROP_LEFT - CROP_RIGHT
source_height = 480  - CROP_TOP  - CROP_BOTTOM
```

四边完全独立，因此可直接表达：

```text
左裁 120 px
右裁 40 px
上裁 30 px
下裁 80 px
```

OpenGL 侧不会重新 memcpy 一张裁切后的 framebuffer，而是把该矩形转换为 `u0/v0/u1/v1` texture coordinates，仅采样选中的源区域。

## 3. Scale and offset are applied after crop

V2.4 的 `SCALE` 作用于**裁切后的源区域**。

例如：

```ini
MMI_SPORT_SMALL_CROP_LEFT=120
MMI_SPORT_SMALL_CROP_RIGHT=40
MMI_SPORT_SMALL_CROP_TOP=30
MMI_SPORT_SMALL_CROP_BOTTOM=80
MMI_SPORT_SMALL_SCALE=1.00
```

裁切后的源画面为：

```text
864 x 370
```

因此：

```text
SCALE=1.00  -> 约 864x370
SCALE=0.80  -> 约 691x296
SCALE=2.00  -> 约 1728x740
```

V2.4 不再使用 V2.3 的 `max_scale = min(output/source)` 强制 fit 限制，`SCALE` 在允许范围内按字面值执行。

## 4. Literal offsets and natural edge clipping

V2.3 会把 destination rectangle 强行夹回 `1440x455` 内。V2.4 删除该行为。

例如：

```ini
MMI_SPORT_SMALL_OFFSET_X=-300
```

现在就真正表示向左移动 300 px。若画面越过左边界，超出的部分只是不显示；Native 不会把画面自动推回屏幕内。

因此 V2.4 明确区分：

```text
CROP_*   = 决定“源 MMI 的哪些内容被取出来”
SCALE    = 决定“取出的内容显示多大”
OFFSET_* = 决定“最终内容放在哪里”
```

## 5. Diagnostic timing

当前 V2.4 Native 还保留纯观测性质的阶段计时，用于分析长时间运行后 FPS 下降原因：

```text
capture
upload
draw
swap
work
interval
sleep
overshoot
no_sleep
```

这些统计只记录耗时，不改变线程优先级、swap interval、capture frequency 或原有 pacing 策略。

## 6. Default behavior and config

所有 V2.4 crop 默认值均为 0：

```text
LEFT=0 RIGHT=0 TOP=0 BOTTOM=0
```

旧 V2.3 `config.local` 不包含 crop 参数时，V2.4 launcher 会自动补 0，不会主动裁掉任何源内容。

统一配置位置：

```text
Toolbox/apps/mmi-mirror/config.local
```

Toolbox 页面：

```text
Install/Update custom display config
Reset custom display config to defaults
```

安装后的配置位置：

```text
/mnt/app/root/mmi-mirror/config.local
```

配置更新在下一次 BaseVideo 启动时生效。

## 7. Current artifact / install status

当前 V2.4.1 Native 已重新编译、同步并完成实车验证：

```text
Size:     105187
SHA256:   EE48454507B24ED1CB1F72C1F8EE5202E16E2B58DD045C64A594A3DEC0C5D1D5
Git blob: 46f9f45a0585777142a9ba50627f12485d4689d7
```

状态文件：

```text
Toolbox/apps/mmi-mirror/V2.4-STATUS
```

当前状态：

```text
CandidatePhase=VEHICLE_VERIFIED
NativeStatus=READY
SourceBinarySync=YES
QNXBuild=PASS
UnifiedJarStatus=INHERITED_V2.3_UNCHANGED
RGI98Status=INHERITED_V2.3_UNCHANGED
LifecycleStatus=INHERITED_V2.3_UNCHANGED
VehicleStatus=VEHICLE_VERIFIED
InstallStatus=VEHICLE_VERIFIED_READY
```

也就是说：**V2.4.1 当前源码、QNX artifact、安装包与实车验证状态已经闭环，可作为推荐稳定安装版本。**

## 8. Verification summary

```text
V2.3 JAVA80 ownership              INHERITED / UNCHANGED
V2.3 Auto Lifecycle                INHERITED / UNCHANGED
V2.3 Unified JAR + Amap RGI logic  INHERITED / UNCHANGED
V2.3 RGI98                         INHERITED / UNCHANGED
V2.4 four-edge source crop         BUILT / CI VERIFIED
V2.4 literal destination offsets   BUILT / CI VERIFIED
V2.4 natural GL overflow clipping  BUILT / CI VERIFIED
V2.4 stage timing diagnostics      BUILT / CI VERIFIED
V2.4.1 vehicle validation          VERIFIED
```
