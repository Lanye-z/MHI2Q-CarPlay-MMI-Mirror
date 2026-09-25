# MHI2Q CarPlay RGI + MMI Mirror — V2.4.1

当前 **main** 为 **V2.4.1 无源码安装版**，面向 Audi MHI2Q 实车使用。

## 当前状态

**V2.4.1 已完成实车验证，当前作为推荐稳定版本。**

- QNX 6.5 ARMv7 Native 已重新编译并与安装包同步
- MMI Mirror 主体显示与动态布局已完成实车验证
- 启动 Logo 跟随当前 MMI Mirror destination 显示，不再铺满整个仪表区域
- 运行水印为：**“免费开源，禁止倒卖”**
- 水印在当前实际可见的镜像区域内动态漂移
- Classic / Sport、Full / Small 切换时，水印边界会随新的镜像裁切/平移区域重新计算
- 已有 MMI Mirror 可以直接使用 Install/Update 覆盖更新；安装完成后必须重启 HMI/车机再测试

## 安装

下载 main 分支 ZIP 并解压，将下面两项放在 SD 卡根目录：

```text
metainfo2.txt
Toolbox/
```

然后进入 Green Menu / Toolbox 执行对应的 MMI Mirror 安装或更新项。

## 本 main 的内容

本分支是纯安装版，只保留上车运行与安装所需文件：

```text
metainfo2.txt
Toolbox/
README.md
LICENSE
```

不包含：

- MMI-Mirror C/C++ 源码
- QNX 编译工程与 build 脚本
- 开发测试目录
- Research / Tools
- GitHub CI 编译文件

## V2.4.1 Native

```text
mmi-mirror-display
SHA256:
ee48454507b24ed1cb1f72c1f8ee5202e16e2b58dd045c64a594a3dec0c5d1d5
```

包内 `Toolbox/apps/mmi-mirror/V2.4.1-SHA256SUMS` 可用于进一步核对安装产物。

## 版本备份

本项目替换前的原 main 已完整备份为：

```text
V2.2
```

需要旧版时可直接切换到 `V2.2` 分支。

## 开源说明

**免费开源，禁止倒卖。**
